// Balance simulator: a bot plays the whole game headlessly.
// Usage: node tools/sim.js [dirty|middle|green] [clicksPerSecond]
// The bot makes at most ~3 purchases per second, like a real player.
const fs = require("fs");
const path = require("path");
const vm = require("vm");
for (const f of ["js/data.js", "js/content.js", "js/engine.js"]) {
  vm.runInThisContext(fs.readFileSync(path.join(__dirname, "..", f), "utf8"), { filename: f });
}
const E = globalThis.Engine, G = globalThis.GAME;
if (process.env.GOALS) JSON.parse(process.env.GOALS).forEach((g, i) => (G.stages[i].goal = g));

function run(strategy, cps = 3, seed = 1) {
  let rnd = seed;
  const random = () => ((rnd = (rnd * 16807) % 2147483647) / 2147483647);
  const st = E.newState("Bot");
  const dt = 0.1;
  let t = 0, clickAcc = 0, cooldown = 0;
  const stageTimes = [];
  const readShare = { green: 1, middle: 0.6, dirty: 0.3 }[strategy];
  while (!st.ended && t < 7200) {
    while (st.queue.length) {
      const q = st.queue.shift();
      if (q.type === "final") E.finish(st);
      if (q.type === "decision") {
        const ss = E.decById[q.id].options.map((o) => o.s);
        const idx = strategy === "green" ? ss.indexOf(Math.max(...ss)) : strategy === "dirty" ? ss.indexOf(Math.min(...ss))
          : ss.map(Math.abs).indexOf(Math.min(...ss.map(Math.abs)));
        E.decide(st, q.id, idx);
      }
      if (q.type === "press") {
        const known = st.read.includes(q.fact);
        const ok = random() < (known ? 0.85 : 0.4);
        const ans = G.press[q.fact].answer;
        E.answerPress(st, q.fact, ok ? ans : (ans + 1) % 3);
      }
    }
    if (st.ended) break;
    st.toasts.length = 0;
    // read facts as they unlock (some strategies skip some)
    for (const id of st.facts) if (!st.read.includes(id) && !st.asked.includes("skip:" + id)) {
      if (random() < readShare) E.readFact(st, id); else st.asked.push("skip:" + id);
    }
    if (E.currentGoal(st)?.done) E.claimGoal(st);
    if (E.stageInfo(st).ready) E.moveStage(st);
    clickAcc += cps * dt;
    while (clickAcc >= 1) { E.click(st); clickAcc--; }
    if ((cooldown -= dt) <= 0) {
      const inc = Math.max(E.incomePerSec(st), 0.01);
      // green purchases first (for green players, and half of them for middle players)
      const greens = E.greenUpgrades(st).filter((g, i) => E.greenStatus(st, g) === "available" && (strategy === "green" || (strategy === "middle" && i % 2 === 0)));
      const g = greens.find((x) => st.cash >= E.greenCost(x));
      if (g) { E.buyGreen(st, g.id); cooldown = 0.33; }
      else {
        const cands = [];
        for (const gen of E.visibleGenerators(st)) {
          const gain = E.genIncome(st, gen.id) * (G.MILESTONES.includes(st.owned[gen.id] + 1) ? 2 : 1);
          cands.push({ kind: "g", id: gen.id, cost: E.genCost(st, gen.id), gain });
        }
        for (const u of E.aiUpgrades(st)) {
          if (E.upgradeStatus(st, u) !== "available") continue;
          const e = u.effect;
          let gain = 0;
          if (e.all) gain += inc * (e.all - 1);
          if (e.gen) gain += st.owned[e.gen] * E.genIncome(st, e.gen) * (e.mult - 1);
          if (e.click) gain += E.clickValue(st) * cps * (e.click - 1);
          cands.push({ kind: "u", id: u.id, cost: u.cost, gain: Math.max(gain, 1e-9) });
        }
        cands.forEach((c) => (c.score = c.cost / inc + c.cost / c.gain));
        cands.sort((a, b) => a.score - b.score);
        const best = cands[0];
        if (best && st.cash >= best.cost) {
          if (best.kind === "g") E.buyGen(st, best.id); else E.buyUpgrade(st, best.id);
          cooldown = 0.33;
        }
      }
      if (strategy === "green" && st.revealed && st.offsets < 3 && st.cash > E.offsetCost(st) * 3) E.buyOffset(st);
    }
    const before = st.stage;
    E.tick(st, dt);
    t += dt;
    if (st.stage !== before) stageTimes.push(t);
    if (stageTimes.length < st.stage - 1) stageTimes.push(t);
  }
  const ts = [0, ...stageTimes, t];
  const fp = st.footprint;
  return {
    strategy, total: (t / 60).toFixed(1) + " min",
    stages: ts.slice(1).map((v, i) => ((v - ts[i]) / 60).toFixed(1)).join(" | "),
    S: E.sustainability(st), ending: st.ending, rank: st.rank, green: st.green.length, press: `${st.pressRight}/${st.pressRight + st.pressWrong}`,
    badges: st.badges.length, energy: E.fmtEnergy(fp.kwh), co2: E.fmtMass(fp.co2),
  };
}

module.exports = { run };
if (require.main === module) {
  const strategies = process.argv[2] ? [process.argv[2]] : ["dirty", "middle", "green"];
  const cps = process.argv[3] ? Number(process.argv[3]) : 3;
  for (const s of strategies) console.log(run(s, cps));
}
