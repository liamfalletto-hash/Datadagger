/* AETHER — game engine. Pure logic, no DOM: it can run in the browser or in
 * Node (see tools/sim.js). The UI reads `state` and calls the actions below.
 */
(function (root) {
  const G = root.GAME;
  const SAVE_VERSION = 1;

  const genById = Object.fromEntries(G.generators.map((g) => [g.id, g]));
  const upById = Object.fromEntries(G.upgrades.map((u) => [u.id, u]));
  const decById = Object.fromEntries(G.decisions.map((d) => [d.id, d]));

  function newState() {
    const owned = {};
    G.generators.forEach((g) => (owned[g.id] = 0));
    return {
      version: SAVE_VERSION,
      cash: 0,
      lifetime: 0,
      day: 0,
      stage: 1,
      owned,
      upgrades: {},
      clicks: 0,
      promptIndex: 0,
      revealed: false,
      decisions: {}, // decisionId -> option index
      sBonus: 0, // offsets + random events
      offsets: 0,
      factors: { ci: 0.45, pue: 1.5, wue: 0.5, lifespan: 1095, powerMult: 1, desert: false },
      footprint: { kwh: 0, co2: 0, water: 0, ewaste: 0 },
      footprintAtReveal: null,
      facts: [],
      news: [],
      queue: [{ type: "intro" }],
      toasts: [],
      triggered: {},
      timers: { news: 8, fine: 90, heat: 70, good: 80 },
      heatUntil: 0,
      ended: false,
      ending: null,
      sHistory: [],
    };
  }

  /* ---------------- derived values ---------------- */

  function sustainability(st) {
    let s = 50 + st.sBonus;
    for (const [id, idx] of Object.entries(st.decisions)) {
      const opt = decById[id] && decById[id].options[idx];
      if (opt) s += opt.s || 0;
    }
    return Math.max(0, Math.min(100, Math.round(s)));
  }

  // Low sustainability = cutting corners = more money (×1.3 at 0, ×0.7 at 100).
  function sMult(st) {
    if (!st.revealed) return 1;
    return 1 + ((50 - sustainability(st)) / 50) * 0.3;
  }

  function allMult(st) {
    let m = 1;
    for (const id in st.upgrades) {
      const e = upById[id] && upById[id].effect;
      if (e && e.all) m *= e.all;
    }
    return m;
  }

  function genMult(st, gid) {
    let m = 1;
    for (const id in st.upgrades) {
      const e = upById[id] && upById[id].effect;
      if (e && e.gen === gid) m *= e.mult;
    }
    return m;
  }

  function powerMult(st) {
    let m = st.factors.powerMult;
    for (const id in st.upgrades) {
      const e = upById[id] && upById[id].effect;
      if (e && e.power) m *= e.power;
    }
    return m;
  }

  function heatMult(st) {
    return st.day < st.heatUntil ? 0.7 : 1;
  }

  function genIncome(st, gid) {
    const g = genById[gid];
    return g.income * genMult(st, gid) * allMult(st) * sMult(st) * heatMult(st);
  }

  function incomePerSec(st) {
    let total = 0;
    for (const g of G.generators) if (st.owned[g.id]) total += st.owned[g.id] * genIncome(st, g.id);
    return total;
  }

  function clickValue(st) {
    let m = 1;
    for (const id in st.upgrades) {
      const e = upById[id] && upById[id].effect;
      if (e && e.click) m *= e.click;
    }
    // Clicking stays useful all game: each click is worth a slice of income.
    return m * Math.max(1, incomePerSec(st) * 0.15);
  }

  // IT power in kW (the laptop counts too).
  function itPowerKW(st) {
    let kw = 0.06;
    for (const g of G.generators) kw += st.owned[g.id] * g.kw;
    return kw * powerMult(st);
  }

  function facilityPowerKW(st) {
    return itPowerKW(st) * st.factors.pue;
  }

  // Human users: capped by how many people are online, and falling late in a
  // polluting game as the world gets harder to live in.
  function users(st) {
    const raw = 3 + incomePerSec(st) * 12 + st.clicks * 0.2;
    const decline = st.revealed && st.stage >= 4 ? 0.3 + 0.7 * (sustainability(st) / 100) : 1;
    return Math.round(Math.min(raw, 5e9 * decline));
  }

  function genCost(st, gid) {
    const g = genById[gid];
    return Math.ceil(g.cost * Math.pow(1.15, st.owned[gid]));
  }

  // Price of the next n units (geometric series), and how many the player can afford.
  function genCostN(st, gid, n) {
    const g = genById[gid];
    const first = g.cost * Math.pow(1.15, st.owned[gid]);
    return Math.ceil((first * (Math.pow(1.15, n) - 1)) / 0.15);
  }

  function maxAffordable(st, gid) {
    const g = genById[gid];
    const first = g.cost * Math.pow(1.15, st.owned[gid]);
    if (st.cash < first) return 0;
    return Math.max(0, Math.floor(Math.log((st.cash * 0.15) / first + 1) / Math.log(1.15)));
  }

  function visibleGenerators(st) {
    return G.generators.filter((g) => g.stage <= st.stage);
  }

  function upgradeAvailable(st, u) {
    if (st.upgrades[u.id] || u.stage > st.stage) return false;
    if (u.req) for (const gid in u.req) if (st.owned[gid] < u.req[gid]) return false;
    return true;
  }

  function visibleUpgrades(st) {
    return G.upgrades.filter((u) => upgradeAvailable(st, u));
  }

  function stageInfo(st) {
    const stage = G.stages[st.stage - 1];
    const prevGoal = st.stage > 1 ? G.stages[st.stage - 2].goal : 0;
    const progress = Math.max(0, Math.min(1, (st.lifetime - prevGoal) / (stage.goal - prevGoal)));
    return { stage, prevGoal, progress, next: G.stages[st.stage] || null };
  }

  function offsetCost(st) {
    return Math.max(50, Math.round(stageInfo(st).stage.goal * 0.04 * Math.pow(2.5, st.offsets)));
  }

  function endingFor(st) {
    const s = sustainability(st);
    if (s >= G.endings.good.min) return "good";
    if (s >= G.endings.mid.min) return "mid";
    return "bad";
  }

  /* ---------------- helpers that emit messages ---------------- */

  function addNews(st, text, kind) {
    st.news.unshift({ day: Math.floor(st.day), text: fill(st, text), kind: kind || "info" });
    if (st.news.length > 80) st.news.length = 80;
  }

  function unlockFact(st, id, silent) {
    if (!id || !G.facts[id] || st.facts.includes(id)) return false;
    st.facts.push(id);
    if (!silent) st.toasts.push({ type: "fact", id });
    return true;
  }

  function toast(st, text, kind) {
    st.toasts.push({ type: "msg", text, kind: kind || "info" });
  }

  function fill(st, text) {
    return text
      .replace("{users}", fmtNum(users(st)))
      .replace("{homes}", fmtNum((facilityPowerKW(st) * 8760) / G.REF.homeKwhYear))
      .replace("{co2}", fmtMass(st.footprint.co2))
      .replace("{cash}", "$" + fmtNum(st.cash));
  }

  /* ---------------- actions ---------------- */

  function click(st) {
    const v = clickValue(st);
    st.cash += v;
    st.lifetime += v;
    st.clicks++;
    st.promptIndex++;
    if (st.clicks === 25) unlockFact(st, "prompt");
    return v;
  }

  function currentPrompt(st) {
    const list = G.prompts[st.stage];
    return list[st.promptIndex % list.length];
  }

  function buyGen(st, gid) {
    const c = genCost(st, gid);
    if (st.cash < c) return false;
    st.cash -= c;
    st.owned[gid]++;
    if (st.owned[gid] === 1) {
      const g = genById[gid];
      if (gid === "gpu") unlockFact(st, "gpu");
      if (gid === "datacenter") { addNews(st, "Aether opens its first data centre."); unlockFact(st, "ireland"); }
      if (gid === "campus") addNews(st, "Aether breaks ground on its first 100 MW hyperscale campus.");
      if (gid === "gigafactory") addNews(st, "Aether switches on a 1-gigawatt AI gigafactory, as big as a nuclear reactor.");
      if (gid === "server") addNews(st, "Aether buys its first real AI server.");
      void g;
    }
    return true;
  }

  function buyGenN(st, gid, n) {
    let bought = 0;
    while (bought < n && buyGen(st, gid)) bought++;
    return bought;
  }

  function buyUpgrade(st, uid) {
    const u = upById[uid];
    if (!u || !upgradeAvailable(st, u) || st.cash < u.cost) return false;
    st.cash -= u.cost;
    st.upgrades[uid] = true;
    if (u.effect.oneOffKwh) addFootprint(st, u.effect.oneOffKwh, 0);
    if (u.news) addNews(st, u.news);
    if (u.fact) unlockFact(st, u.fact);
    return true;
  }

  function decide(st, did, idx) {
    const d = decById[did];
    const opt = d && d.options[idx];
    if (!opt || st.decisions[did] !== undefined) return false;
    const inc = incomePerSec(st);
    if (opt.costFrac) st.cash -= Math.max(0, st.cash) * opt.costFrac;
    if (opt.bonusSec) { const b = inc * opt.bonusSec; st.cash += b; st.lifetime += b; }
    const f = st.factors, set = opt.set || {};
    if (set.ci !== undefined) f.ci = set.ci;
    if (set.ciBlend !== undefined) f.ci = (f.ci + set.ciBlend) / 2;
    if (set.pue !== undefined) f.pue = set.pue;
    if (set.pueAdd) f.pue += set.pueAdd;
    if (set.wue !== undefined) f.wue = set.wue;
    if (set.wueMult) f.wue *= set.wueMult;
    if (set.lifespan) f.lifespan = set.lifespan;
    if (set.powerMult) f.powerMult = set.powerMult;
    if (set.desert) f.desert = true;
    st.decisions[did] = idx;
    if (opt.news) addNews(st, opt.news);
    if (d.fact) unlockFact(st, d.fact, true);
    return true;
  }

  function buyOffset(st) {
    if (!st.revealed || st.offsets >= 3) return false;
    const c = offsetCost(st);
    if (st.cash < c) return false;
    st.cash -= c;
    st.offsets++;
    st.sBonus += 3;
    unlockFact(st, "offsets");
    addNews(st, "Aether buys carbon offsets and calls itself 'climate-friendly'. Its emissions haven't changed.");
    return true;
  }

  /* ---------------- simulation ---------------- */

  function addFootprint(st, kwh, itKwh) {
    const fp = st.footprint, f = st.factors;
    fp.kwh += kwh;
    fp.co2 += kwh * f.ci;
    fp.water += (itKwh || kwh / f.pue) * f.wue;
  }

  function tick(st, dt) {
    if (st.ended) return;
    const days = dt * G.DAYS_PER_SEC;
    st.day += days;

    const inc = incomePerSec(st);
    st.cash += inc * dt;
    st.lifetime += inc * dt;

    // Footprint: energy (with cooling overhead), CO2, water, e-waste.
    const itKw = itPowerKW(st);
    const itKwh = itKw * 24 * days;
    addFootprint(st, itKwh * st.factors.pue, itKwh);
    st.footprint.ewaste += (itKw * G.REF.hardwareKgPerKw * days) / st.factors.lifespan;

    checkProgress(st);
    randomEvents(st, dt);
  }

  function checkProgress(st) {
    const info = stageInfo(st);

    // Stage transitions.
    if (st.lifetime >= info.stage.goal) {
      if (st.stage < G.stages.length) {
        st.stage++;
        st.queue.push({ type: "stage", stage: st.stage });
        addNews(st, `MILESTONE: Aether enters a new era: ${G.stages[st.stage - 1].name}.`, "milestone");
        if (st.stage === 3) unlockFact(st, "digital");
        if (st.stage === 4) unlockFact(st, "usGrid");
      } else if (!st.triggered.final) {
        st.triggered.final = true;
        st.queue.push({ type: "final" });
      }
    }

    // The fine that reveals the sustainability metric (early in stage 2).
    if (st.stage >= 2 && !st.triggered.fine && (st.stage > 2 || info.progress >= 0.1)) {
      st.triggered.fine = true;
      // Half your cash, or 10% of everything you've earned, whichever hurts more
      // (this can push you into debt).
      const amount = Math.round(Math.max(st.cash * 0.5, st.lifetime * 0.1));
      st.cash -= amount;
      st.revealed = true;
      st.footprintAtReveal = { ...st.footprint };
      st.queue.push({ type: "fine", amount });
      addNews(st, `BREAKING: Aether fined $${fmtNum(amount)} for hiding its energy use.`, "bad");
      unlockFact(st, "reporting", true);
      unlockFact(st, "dataCentres");
      unlockFact(st, "co2Volume", true);
    }

    // Decisions.
    const cur = stageInfo(st);
    for (const d of G.decisions) {
      if (st.triggered["d_" + d.id]) continue;
      if (st.stage > d.trigger.stage || (st.stage === d.trigger.stage && cur.progress >= d.trigger.progress)) {
        st.triggered["d_" + d.id] = true;
        st.queue.push({ type: "decision", id: d.id });
      }
    }
  }

  function randomEvents(st, dt) {
    const t = st.timers;
    const s = sustainability(st);

    // News every ~12–20 s.
    t.news -= dt;
    if (t.news <= 0) {
      t.news = 12 + Math.random() * 8;
      addNews(st, pickNews(st, s));
    }

    if (!st.revealed || st.stage < 3) return;

    // Regulators fine polluters.
    t.fine -= dt;
    if (t.fine <= 0) {
      t.fine = 60 + Math.random() * 40;
      if (s < 40) {
        const amount = Math.round(Math.max(st.cash * 0.12, incomePerSec(st) * 10));
        st.cash -= amount;
        addNews(st, `Regulator fines Aether $${fmtNum(amount)} for breaking pollution limits.`, "bad");
        toast(st, `⚖️ Fined $${fmtNum(amount)} for breaking pollution limits (Sustainability below 40).`, "bad");
      }
    }

    // Heatwaves overload cooling, and they get worse the lower the score.
    t.heat -= dt;
    if (t.heat <= 0) {
      t.heat = 55 + Math.random() * 40;
      if (Math.random() < (100 - s) / 100) {
        st.heatUntil = st.day + 15;
        addNews(st, "Heatwave: Aether's cooling can't keep up. Servers are slowed down to avoid overheating.", "bad");
        toast(st, "🌡️ Heatwave! Cooling overloaded: income −30% for 15 days.", "bad");
      }
    }

    // A sustainable company attracts talent and public money.
    t.good -= dt;
    if (t.good <= 0) {
      t.good = 70 + Math.random() * 40;
      if (s >= 70) {
        const b = incomePerSec(st) * 25;
        st.cash += b;
        st.lifetime += b;
        addNews(st, "Aether wins a public grant for its clean data centres.", "good");
        toast(st, `🌱 Green grant: +$${fmtNum(b)} for your clean data centres.`, "good");
      }
    }
  }

  function pickNews(st, s) {
    const N = G.news;
    let pool = N.stage[st.stage];
    if (st.revealed) {
      const r = Math.random();
      if (s < 40 && r < 0.55) pool = st.stage >= 4 ? N.low.concat(N.lowLate) : N.low;
      else if (s >= 70 && r < 0.45) pool = N.high;
      else if (s >= 40 && s < 70 && r < 0.35) pool = N.mid;
    }
    // Avoid repeating recent headlines.
    st.recentNews = st.recentNews || [];
    const fresh = pool.filter((p) => !st.recentNews.includes(p));
    const list = fresh.length ? fresh : pool;
    const pick = list[Math.floor(Math.random() * list.length)];
    st.recentNews.unshift(pick);
    st.recentNews.length = Math.min(st.recentNews.length, 8);
    return pick;
  }

  function finish(st) {
    st.ended = true;
    st.ending = endingFor(st);
  }

  /* ---------------- formatting ---------------- */

  function fmtNum(n) {
    if (!isFinite(n)) return "∞";
    const a = Math.abs(n);
    if (a < 1000) return a < 10 && a % 1 ? n.toFixed(1) : Math.round(n).toLocaleString("en-US");
    const units = ["", "K", "M", "B", "T", "Qa", "Qi"];
    let i = 0, v = n;
    while (Math.abs(v) >= 1000 && i < units.length - 1) { v /= 1000; i++; }
    return (Math.abs(v) < 100 ? v.toFixed(2) : v.toFixed(1)) + units[i];
  }

  function fmtEnergy(kwh) {
    if (kwh < 1) return (kwh * 1000).toFixed(0) + " Wh";
    if (kwh < 1e3) return kwh.toFixed(1) + " kWh";
    if (kwh < 1e6) return (kwh / 1e3).toFixed(1) + " MWh";
    if (kwh < 1e9) return (kwh / 1e6).toFixed(1) + " GWh";
    return (kwh / 1e9).toFixed(2) + " TWh";
  }

  function fmtPower(kw) {
    if (kw < 1) return (kw * 1000).toFixed(0) + " W";
    if (kw < 1e3) return kw.toFixed(1) + " kW";
    if (kw < 1e6) return (kw / 1e3).toFixed(1) + " MW";
    return (kw / 1e6).toFixed(2) + " GW";
  }

  function fmtMass(kg) {
    if (kg < 1000) return kg.toFixed(kg < 10 ? 1 : 0) + " kg";
    if (kg < 1e6) return (kg / 1e3).toFixed(1) + " t";
    if (kg < 1e9) return (kg / 1e6).toFixed(2) + " thousand t";
    return (kg / 1e9).toFixed(2) + " million t";
  }

  function fmtWater(l) {
    if (l < 1000) return l.toFixed(0) + " L";
    if (l < 1e6) return (l / 1e3).toFixed(1) + " m³";
    if (l < 1e9) return (l / 1e6).toFixed(2) + " million L";
    return (l / 1e9).toFixed(2) + " billion L";
  }

  /* ---------------- save / load ---------------- */

  function serialize(st) {
    return JSON.stringify(st);
  }

  function deserialize(json) {
    try {
      const data = JSON.parse(json);
      if (!data || data.version !== SAVE_VERSION) return null;
      const fresh = newState();
      const st = Object.assign(fresh, data);
      st.toasts = [];
      return st;
    } catch (e) {
      return null;
    }
  }

  root.Engine = {
    newState, tick, click, buyGen, buyGenN, genCostN, maxAffordable, buyUpgrade, decide, buyOffset, finish,
    sustainability, sMult, incomePerSec, genIncome, clickValue, itPowerKW, facilityPowerKW,
    users, genCost, visibleGenerators, visibleUpgrades, stageInfo, offsetCost, endingFor,
    currentPrompt, addNews, unlockFact,
    fmtNum, fmtEnergy, fmtPower, fmtMass, fmtWater,
    serialize, deserialize, genById, upById, decById,
  };
})(typeof window !== "undefined" ? window : globalThis);
