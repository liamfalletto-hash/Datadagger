// Balance simulator: a greedy bot plays the whole game headlessly.
// Usage: node tools/sim.js [green|dirty|middle] [clicksPerSecond]
const fs = require("fs");
const path = require("path");
const vm = require("vm");
for (const f of ["js/data.js", "js/engine.js"]) {
  vm.runInThisContext(fs.readFileSync(path.join(__dirname, "..", f), "utf8"), { filename: f });
}
const E = globalThis.Engine, G = globalThis.GAME;
if (process.env.GOALS) JSON.parse(process.env.GOALS).forEach((g, i) => (G.stages[i].goal = g));

// mode "optimal": buys the best payback item. mode "casual": acts twice a
// second and buys the most expensive thing it can afford (closer to real players).
function run(strategy, cps, mode = "optimal") {
  const st = E.newState();
  const dt = 0.1;
  let t = 0, clickAcc = 0, cooldown = 0;
  const stageTimes = {};
  while (!st.ended && t < 3600) {
    while (st.queue.length) {
      const q = st.queue.shift();
      if (q.type === "stage") stageTimes[q.stage] = t;
      if (q.type === "final") E.finish(st);
      if (q.type === "decision") {
        const d = E.decById[q.id];
        const ss = d.options.map((o) => o.s);
        let idx;
        if (strategy === "green") idx = ss.indexOf(Math.max(...ss));
        else if (strategy === "dirty") idx = ss.indexOf(Math.min(...ss));
        else { const abs = ss.map(Math.abs); idx = abs.indexOf(Math.min(...abs)); }
        E.decide(st, q.id, idx);
      }
    }
    if (st.ended) break;
    st.toasts.length = 0;
    clickAcc += cps * dt;
    while (clickAcc >= 1) { E.click(st); clickAcc--; }
    if (mode === "casual") {
      if (Math.round(t * 10) % 5 === 0) {
        const items = [...E.visibleGenerators(st).map((g) => ({ k: "g", id: g.id, c: E.genCost(st, g.id) })),
          ...E.visibleUpgrades(st).map((u) => ({ k: "u", id: u.id, c: u.cost }))].filter((x) => x.c <= st.cash).sort((a, b) => b.c - a.c);
        if (items[0]) items[0].k === "g" ? E.buyGen(st, items[0].id) : E.buyUpgrade(st, items[0].id);
      }
    } else if ((cooldown -= dt) <= 0)
    // greedy buying, at most ~3 purchases per second like a real player
    for (let k = 0; k < 1; k++) {
      const inc = Math.max(E.incomePerSec(st), 0.01);
      const cands = [];
      for (const g of E.visibleGenerators(st)) cands.push({ kind: "g", id: g.id, cost: E.genCost(st, g.id), gain: E.genIncome(st, g.id) });
      for (const u of E.visibleUpgrades(st)) {
        const e = u.effect; let gain = 0;
        if (e.all) gain += inc * (e.all - 1);
        if (e.gen) gain += st.owned[e.gen] * E.genIncome(st, e.gen) * (e.mult - 1);
        if (e.click) gain += E.clickValue(st) * cps * (e.click - 1);
        cands.push({ kind: "u", id: u.id, cost: u.cost, gain: Math.max(gain, 1e-9) });
      }
      cands.forEach((c) => (c.score = c.cost / inc + c.cost / c.gain));
      cands.sort((a, b) => a.score - b.score);
      const best = cands[0];
      if (!best || st.cash < best.cost) break;
      if (best.kind === "g") E.buyGen(st, best.id); else E.buyUpgrade(st, best.id);
      cooldown = 0.33;
    }
    if (strategy === "green" && st.revealed && st.offsets < 3 && st.cash > E.offsetCost(st) * 3) E.buyOffset(st);
    E.tick(st, dt);
    t += dt;
  }
  const fp = st.footprint;
  return {
    strategy, cps, mode, total: (t / 60).toFixed(1) + " min",
    stages: (() => { const ts = [0, ...Object.values(stageTimes), t]; return ts.slice(1).map((v, i) => ((v - ts[i]) / 60).toFixed(1)).join(" | "); })(),
    S: E.sustainability(st), ending: st.ending,
    energy: E.fmtEnergy(fp.kwh), co2: E.fmtMass(fp.co2), water: E.fmtWater(fp.water), ewaste: E.fmtMass(fp.ewaste),
  };
}

module.exports = { run };
if (require.main !== module) return;
const strategies = process.argv[2] ? [process.argv[2]] : ["dirty", "middle", "green"];
const cps = process.argv[3] ? Number(process.argv[3]) : 3;
const mode = process.argv[4] || "optimal";
for (const s of strategies) console.log(run(s, cps, mode));
