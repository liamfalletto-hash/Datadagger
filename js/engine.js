/* Game engine: rules and simulation only (no DOM). Runs in the browser and in
 * Node (tools/sim.js). The UI reads `state` and calls the actions below. */
(function (root) {
  const G = root.GAME;
  const SAVE_VERSION = 2;
  const byId = (list) => Object.fromEntries(list.map((x) => [x.id, x]));
  const genById = byId(G.generators), upById = byId(G.upgrades), greenById = byId(G.greenUpgrades), decById = byId(G.decisions);
  const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
  const FACT_IDS = Object.keys(G.facts);

  function cleanName(s) {
    const n = String(s || "").replace(/[^\p{L}\p{N} .'!?-]/gu, "").replace(/\s+/g, " ").trim().slice(0, 16);
    return n || "Nimbus";
  }

  function newState(name) {
    const owned = {};
    G.generators.forEach((g) => (owned[g.id] = 0));
    return {
      version: SAVE_VERSION, name: cleanName(name),
      cash: 0, lifetime: 0, day: 0, stage: 1, owned, upgrades: {}, green: [], clicks: 0, promptIndex: 0,
      revealed: false, decisions: {}, sBonus: 0, offsets: 0,
      factors: { ci: 0.45, pue: 1.5, wue: 0.5, lifespan: 1095, powerMult: 1, biome: "grass" },
      footprint: { kwh: 0, co2: 0, water: 0, ewaste: 0 }, footprintAtReveal: null,
      facts: [], read: [], asked: [], pressRight: 0, pressWrong: 0,
      goalsDone: [], badges: [], rank: 1200, passed: [], finesPaid: 0, finesCount: 0,
      news: [], recentNews: [], queue: [], toasts: [], triggered: {},
      timers: { news: 6, fine: 90, heat: 70, good: 80, press: 70 },
      heatUntil: 0, ended: false, ending: null,
    };
  }

  /* ---------------- derived values ---------------- */

  // Small companies start clean (85). Growing (more power) and dirty choices pull the score down.
  const BASE_S = 85;
  function sizePressure(st) { return Math.max(0, Math.round(4 * (Math.log10(Math.max(1, facilityPowerKW(st))) - 1.5))); }
  function sustainability(st) {
    let s = BASE_S + st.sBonus - sizePressure(st);
    for (const [id, idx] of Object.entries(st.decisions)) s += (decById[id].options[idx].s || 0);
    for (const id in st.upgrades) s += upById[id].s || 0;
    for (const id of st.green) s += greenById[id].s;
    return clamp(Math.round(s), 0, 100);
  }

  // Green upgrades cost a share of income.
  function greenMult(st) { let m = 1; for (const id of st.green) m *= greenById[id].income || 1; return m; }

  // Footprint factors after decisions and green upgrades.
  function eff(st) {
    const f = st.factors;
    let ci = f.ci, pue = f.pue, wue = f.wue, life = f.lifespan, pm = f.powerMult;
    for (const id of st.green) {
      const s = greenById[id].set || {};
      if (s.ciMult) ci *= s.ciMult;
      if (s.pueAdd) pue += s.pueAdd;
      if (s.wueMult) wue *= s.wueMult;
      if (s.lifespanMult) life *= s.lifespanMult;
      if (s.powerMult) pm *= s.powerMult;
    }
    for (const id in st.upgrades) { const e = upById[id].effect; if (e.power) pm *= e.power; }
    return { ci, pue: Math.max(1.05, pue), wue, lifespan: life, powerMult: pm };
  }

  function allMult(st) { let m = 1; for (const id in st.upgrades) { const e = upById[id].effect; if (e.all) m *= e.all; } return m; }
  function stars(st, gid) { return G.MILESTONES.filter((n) => st.owned[gid] >= n).length; }
  function genMult(st, gid) {
    let m = Math.pow(2, stars(st, gid));
    for (const id in st.upgrades) { const e = upById[id].effect; if (e.gen === gid) m *= e.mult; }
    return m;
  }
  const heatMult = (st) => (st.day < st.heatUntil ? 0.7 : 1);
  function genIncome(st, gid) { return genById[gid].income * genMult(st, gid) * allMult(st) * greenMult(st) * heatMult(st); }
  function incomePerSec(st) { let t = 0; for (const g of G.generators) if (st.owned[g.id]) t += st.owned[g.id] * genIncome(st, g.id); return t; }
  function clickValue(st) {
    let m = 1;
    for (const id in st.upgrades) { const e = upById[id].effect; if (e.click) m *= e.click; }
    return m * Math.max(1, incomePerSec(st) * 0.15);
  }
  function itPowerKW(st) { let kw = 0.06; for (const g of G.generators) kw += st.owned[g.id] * g.kw; return kw * eff(st).powerMult; }
  const facilityPowerKW = (st) => itPowerKW(st) * eff(st).pue;
  function users(st) {
    const raw = 3 + incomePerSec(st) * 12 + st.clicks * 0.2;
    const decline = st.revealed && st.stage >= 4 ? 0.3 + 0.7 * (sustainability(st) / 100) : 1;
    return Math.round(Math.min(raw, 5e9 * decline));
  }

  const genCost = (st, gid) => Math.ceil(genById[gid].cost * Math.pow(1.15, st.owned[gid]));
  function genCostN(st, gid, n) { const first = genById[gid].cost * Math.pow(1.15, st.owned[gid]); return Math.ceil((first * (Math.pow(1.15, n) - 1)) / 0.15); }
  function maxAffordable(st, gid) {
    const first = genById[gid].cost * Math.pow(1.15, st.owned[gid]);
    if (st.cash < first) return 0;
    return Math.max(0, Math.floor(Math.log((st.cash * 0.15) / first + 1) / Math.log(1.15)));
  }

  function stageInfo(st) {
    const stage = G.stages[st.stage - 1];
    const prevGoal = st.stage > 1 ? G.stages[st.stage - 2].goal : 0;
    const progress = clamp((st.lifetime - prevGoal) / (stage.goal - prevGoal), 0, 1);
    return { stage, prevGoal, progress, ready: st.lifetime >= stage.goal, next: G.stages[st.stage] || null };
  }

  const visibleGenerators = (st) => G.generators.filter((g) => g.stage <= st.stage);
  function upgradeStatus(st, u) {
    if (st.upgrades[u.id]) return "owned";
    if (u.req) for (const gid in u.req) if (st.owned[gid] < u.req[gid]) return "locked";
    return "available";
  }
  const aiUpgrades = (st) => G.upgrades.filter((u) => u.stage <= st.stage);
  function greenCost(g) {
    const i = g.stage - 1, span = G.stages[i].goal - (i ? G.stages[i - 1].goal : 0);
    return Math.ceil(g.costFrac * span);
  }
  function greenStatus(st, g) {
    if (st.green.includes(g.id)) return "owned";
    if (!st.revealed) return "hidden";
    if (g.fact && !st.read.includes(g.fact)) return "needsFact";
    return "available";
  }
  const greenUpgrades = (st) => G.greenUpgrades.filter((g) => g.stage <= st.stage);
  const offsetCost = (st) => Math.max(50, Math.round(stageInfo(st).stage.goal * 0.04 * Math.pow(2.5, st.offsets)));
  function endingFor(st) { const s = sustainability(st); return s >= G.endings.good.min ? "good" : s >= G.endings.mid.min ? "mid" : "bad"; }

  // How dirty the world around you looks (0 = pristine, 1 = ruined).
  // 85+ pristine, 50 a little grey, below 40 clearly damaged, below 15 on fire.
  const POLLUTION_CURVE = [[100, 0], [85, 0], [50, 0.3], [40, 0.45], [15, 0.8], [0, 1]];
  function pollution(st) {
    if (!st.revealed) return Math.min(0.12, (st.footprint.co2 / 1000) * 0.03);
    const s = sustainability(st);
    for (let i = 0; i < POLLUTION_CURVE.length - 1; i++) {
      const [s1, p1] = POLLUTION_CURVE[i], [s2, p2] = POLLUTION_CURVE[i + 1];
      if (s <= s1 && s >= s2) return p1 + ((p2 - p1) * (s1 - s)) / (s1 - s2);
    }
    return 1;
  }
  // Fines after the first one: the lower the score, the more often and the bigger.
  function fineRate(st) {
    const s = sustainability(st);
    if (!st.revealed || s >= 65) return null;
    return { every: 10 + s * 0.6, share: (0.5 * (65 - s)) / 65 };
  }

  // World ranking: climbs on a log scale through each stage.
  const RANK_PATH = [[1200, 300], [300, 60], [60, 10], [10, 2], [2, 1]];
  function rankFor(st) {
    const [a, b] = RANK_PATH[st.stage - 1], p = stageInfo(st).progress;
    const t = st.stage === 5 ? Math.min(1, p / 0.3) : p;
    return Math.max(1, Math.round(Math.exp(Math.log(a) + (Math.log(b) - Math.log(a)) * t)));
  }
  // Who sits at a given rank, once the player is placed on the board.
  function boardAt(st, r) {
    if (r === st.rank) return { name: st.name, you: true };
    const orig = r < st.rank ? r : r - 1; // entries below you moved down by one
    if (orig <= G.brands.length) return { ...G.brands[orig - 1] };
    return { name: G.rivalName(orig), by: "Start-up" };
  }

  /* ---------------- messages ---------------- */
  function fill(st, text) {
    return String(text).split("{name}").join(st.name)
      .split("{users}").join(fmtNum(users(st)))
      .split("{homes}").join(fmtNum((facilityPowerKW(st) * 8760) / G.REF.homeKwhYear))
      .split("{co2}").join(fmtMass(st.footprint.co2))
      .split("{cash}").join("$" + fmtNum(st.cash));
  }
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
  const toast = (st, text, kind) => st.toasts.push({ type: "msg", text: fill(st, text), kind: kind || "" });

  /* ---------------- actions ---------------- */
  function click(st) {
    const v = clickValue(st);
    st.cash += v; st.lifetime += v; st.clicks++; st.promptIndex++;
    if (st.clicks === 25) unlockFact(st, "prompt");
    return v;
  }
  const currentPrompt = (st) => { const l = G.prompts[st.stage]; return l[st.promptIndex % l.length]; };

  function buyGen(st, gid) {
    const c = genCost(st, gid);
    if (st.cash < c || genById[gid].stage > st.stage) return false;
    st.cash -= c;
    st.owned[gid]++;
    if (st.owned[gid] === 1) {
      if (gid === "gpu") unlockFact(st, "gpu");
      if (gid === "server") addNews(st, "{name} buys its first real AI server.");
      if (gid === "datacenter") { addNews(st, "{name} opens its first data centre hall."); unlockFact(st, "ireland"); }
      if (gid === "campus") addNews(st, "{name} breaks ground on its first 100 MW campus.");
      if (gid === "gigafactory") addNews(st, "{name} switches on a 1-gigawatt AI gigafactory, as big as a nuclear reactor.");
    }
    if (G.MILESTONES.includes(st.owned[gid])) toast(st, `★ ${st.owned[gid]} × ${genById[gid].name}: they now earn double!`, "good");
    return true;
  }
  function buyGenN(st, gid, n) { let b = 0; while (b < n && buyGen(st, gid)) b++; return b; }

  function buyUpgrade(st, uid) {
    const u = upById[uid];
    if (!u || u.stage > st.stage || upgradeStatus(st, u) !== "available" || st.cash < u.cost) return false;
    st.cash -= u.cost;
    st.upgrades[uid] = true;
    if (u.effect.oneOffKwh) addFootprint(st, u.effect.oneOffKwh, 0);
    if (u.news) addNews(st, u.news);
    if (u.fact) unlockFact(st, u.fact);
    return true;
  }

  function buyGreen(st, id) {
    const g = greenById[id];
    if (!g || g.stage > st.stage || greenStatus(st, g) !== "available") return false;
    const c = greenCost(g);
    if (st.cash < c) return false;
    st.cash -= c;
    st.green.push(id);
    addNews(st, `{name} goes greener: ${g.name.toLowerCase()}.`, "good");
    return true;
  }

  function readFact(st, id) {
    if (!st.facts.includes(id) || st.read.includes(id)) return null;
    st.read.push(id);
    return G.greenUpgrades.find((g) => g.fact === id) || null;
  }

  function decide(st, did, idx) {
    const d = decById[did], opt = d && d.options[idx];
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
    if (set.biome) f.biome = set.biome;
    st.decisions[did] = idx;
    if (opt.news) addNews(st, opt.news);
    if (d.fact) unlockFact(st, d.fact, true);
    return true;
  }

  function buyOffset(st) {
    if (!st.revealed || st.offsets >= 3) return false;
    const c = offsetCost(st);
    if (st.cash < c) return false;
    st.cash -= c; st.offsets++; st.sBonus += 3;
    unlockFact(st, "offsets");
    addNews(st, "{name} buys carbon offsets and calls itself 'climate-friendly'. Its emissions haven't changed.");
    return true;
  }

  // Goals: one at a time, from the current stage.
  function goalProgress(st, g) {
    switch (g.kind) {
      case "clicks": return [Math.min(st.clicks, g.n), g.n];
      case "own": return [Math.min(st.owned[g.gen], g.n), g.n];
      case "read": return [Math.min(st.read.length, g.n), g.n];
      case "green": return [Math.min(st.green.length, g.n), g.n];
      case "press": return [Math.min(st.pressRight, g.n), g.n];
      case "rank": return [st.rank <= g.n ? 1 : 0, 1];
      default: return [0, 1];
    }
  }
  function currentGoal(st) {
    const i = G.goals.findIndex((g, k) => g.stage === st.stage && !st.goalsDone.includes(k));
    if (i < 0) return null;
    const g = G.goals[i], [a, b] = goalProgress(st, g);
    return { index: i, goal: g, have: a, need: b, done: a >= b, reward: goalReward(st, g) };
  }
  const goalReward = (st, g) => Math.round(g.reward || Math.max(50, incomePerSec(st) * g.rewardSec));
  function claimGoal(st) {
    const c = currentGoal(st);
    if (!c || !c.done) return 0;
    st.cash += c.reward; st.lifetime += c.reward;
    st.goalsDone.push(c.index);
    return c.reward;
  }

  // Press conferences.
  function nextPressFact(st) {
    const fresh = (list) => list.filter((id) => G.press[id] && !st.asked.includes(id));
    const read = fresh(st.read);
    if (read.length) return read[Math.floor(Math.random() * read.length)];
    const seen = fresh(st.facts);
    return seen.length ? seen[0] : null;
  }
  function answerPress(st, fid, idx) {
    const q = G.press[fid];
    if (!q || st.asked.includes(fid)) return null;
    st.asked.push(fid);
    const ok = idx === q.answer;
    let reward = 0;
    if (ok) {
      reward = Math.round(Math.max(100, incomePerSec(st) * 40));
      st.cash += reward; st.lifetime += reward; st.pressRight++;
      if (st.revealed) st.sBonus += 1;
    } else st.pressWrong++;
    return { ok, reward, answer: q.answer };
  }

  // Move to the next place once the progress bar is full.
  function moveStage(st) {
    const info = stageInfo(st);
    if (!info.ready || st.ended) return false;
    if (st.stage < G.stages.length) {
      st.stage++;
      st.queue.push({ type: "stage", stage: st.stage });
      addNews(st, `MILESTONE: {name} moves on: ${G.stages[st.stage - 1].name}.`, "milestone");
      if (st.stage === 3) unlockFact(st, "digital");
      if (st.stage === 4) unlockFact(st, "usGrid");
    } else if (!st.triggered.final) {
      st.triggered.final = true;
      st.queue.push({ type: "final" });
    }
    return true;
  }

  function finish(st) {
    st.ended = true;
    st.ending = endingFor(st);
    earnBadge(st, { good: "longgame", mid: "usual", bad: "hellobad" }[st.ending]);
  }

  /* ---------------- simulation ---------------- */
  function addFootprint(st, kwh, itKwh) {
    const fp = st.footprint, e = eff(st);
    fp.kwh += kwh;
    fp.co2 += kwh * e.ci;
    fp.water += (itKwh || kwh / e.pue) * e.wue;
  }

  function tick(st, dt) {
    if (st.ended) return;
    const days = dt * G.DAYS_PER_SEC;
    st.day += days;
    const inc = incomePerSec(st);
    st.cash += inc * dt;
    st.lifetime += inc * dt;
    const e = eff(st), itKw = itPowerKW(st), itKwh = itKw * 24 * days;
    addFootprint(st, itKwh * e.pue, itKwh);
    st.footprint.ewaste += (itKw * G.REF.hardwareKgPerKw * days) / e.lifespan;
    checkProgress(st);
    checkRank(st);
    checkBadges(st);
    randomEvents(st, dt);
  }

  function checkProgress(st) {
    const info = stageInfo(st);
    if (info.ready && !st.triggered["ready" + st.stage]) {
      st.triggered["ready" + st.stage] = true;
      const s = G.stages[st.stage - 1];
      toast(st, `Ready! Press “${s.move}” when you want to go on.`, "good");
    }
    // The fine that reveals the sustainability score (early in the office).
    if (st.stage >= 2 && !st.triggered.fine && (st.stage > 2 || info.progress >= 0.1)) {
      st.triggered.fine = true;
      const amount = Math.round(Math.max(st.cash * 0.5, st.lifetime * 0.1));
      st.cash -= amount;
      st.revealed = true;
      st.footprintAtReveal = { ...st.footprint };
      st.queue.push({ type: "fine", amount });
      addNews(st, `BREAKING: {name} fined $${fmtNum(amount)} for hiding its energy use.`, "bad");
      unlockFact(st, "reporting", true);
      unlockFact(st, "dataCentres");
      unlockFact(st, "co2Volume", true);
    }
    for (const d of G.decisions) {
      if (st.triggered["d_" + d.id]) continue;
      if (st.stage > d.trigger.stage || (st.stage === d.trigger.stage && info.progress >= d.trigger.progress)) {
        st.triggered["d_" + d.id] = true;
        st.queue.push({ type: "decision", id: d.id });
      }
    }
  }

  function checkRank(st) {
    const r = rankFor(st);
    if (r >= st.rank) return;
    for (let k = Math.min(st.rank - 1, G.brands.length); k >= r; k--) {
      if (st.passed.includes(k)) continue;
      st.passed.push(k);
      const b = G.brands[k - 1];
      addNews(st, `{name} overtakes ${b.name} to become the world's #${k} AI.`, "milestone");
      st.toasts.push({ type: "rank", text: `You overtook ${b.name} (${b.by})! You're now #${k}.` });
    }
    st.rank = r;
  }

  function earnBadge(st, id) {
    if (!id || st.badges.includes(id)) return;
    st.badges.push(id);
    st.toasts.push({ type: "badge", id });
  }
  function checkBadges(st) {
    const d = st.decisions;
    const rules = {
      hello: st.clicks >= 1, plugged: st.owned.gpu >= 1, garageband: st.owned.gpu >= 5, movingout: st.stage >= 2,
      caught: !!st.triggered.fine, cleanpower: d.energy === 2, coalburner: d.energy === 0, coolhead: d.cooling === 2,
      longlife: d.hardware === 2, rightsized: d.model === 1, greenthumb: st.green.length >= 5,
      factchecker: st.read.length >= 10, bookworm: st.read.length >= FACT_IDS.length, presspro: st.pressRight >= 3,
      top10: st.rank <= 10, numberone: st.rank === 1, greenwasher: st.offsets >= 3, gigawatt: st.owned.gigafactory >= 1,
    };
    for (const id in rules) if (rules[id]) earnBadge(st, id);
  }

  function randomEvents(st, dt) {
    const t = st.timers, s = sustainability(st);
    if ((t.news -= dt) <= 0) { t.news = 12 + Math.random() * 8; addNews(st, pickNews(st, s)); }
    // Press conference every ~2 minutes, from the second half of the garage on.
    if (st.stage > 1 || stageInfo(st).progress > 0.5) {
      if ((t.press -= dt) <= 0) {
        const fid = nextPressFact(st);
        if (fid && !st.queue.some((q) => q.type === "press")) {
          const order = [0, 1, 2].sort(() => Math.random() - 0.5);
          st.queue.push({ type: "press", fact: fid, order });
          t.press = 100 + Math.random() * 40;
        }
        else t.press = 20;
      }
    }
    if (!st.revealed || !st.triggered.fine) return;
    if ((t.fine -= dt) <= 0) {
      const r = fineRate(st);
      if (r) {
        const amount = Math.round(Math.max(50, incomePerSec(st) * r.share * r.every));
        st.cash -= amount; st.finesPaid += amount; st.finesCount++;
        st.toasts.push({ type: "fine", amount });
        const tpl = G.news.fines[Math.floor(Math.random() * G.news.fines.length)];
        addNews(st, tpl.split("{fine}").join("$" + fmtNum(amount)), "bad");
        t.fine = r.every * (0.8 + Math.random() * 0.4);
      } else t.fine = 8;
    }
    if (st.stage < 3) return;
    if ((t.heat -= dt) <= 0) {
      t.heat = 55 + Math.random() * 40;
      if (Math.random() < (100 - s) / 100) {
        st.heatUntil = st.day + 15;
        addNews(st, "Heatwave: {name}'s cooling can't keep up. Servers are slowed down to avoid overheating.", "bad");
        toast(st, "Heatwave! Cooling overloaded: income −30% for 15 days.", "bad");
      }
    }
    if ((t.good -= dt) <= 0) {
      t.good = 70 + Math.random() * 40;
      if (s >= 70) {
        const b = incomePerSec(st) * 25;
        st.cash += b; st.lifetime += b;
        addNews(st, "{name} wins a public grant for its clean data centres.", "good");
        toast(st, `Green grant: +$${fmtNum(b)} for your clean data centres.`, "good");
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
    const fresh = pool.filter((p) => !st.recentNews.includes(p));
    const list = fresh.length ? fresh : pool;
    const pick = list[Math.floor(Math.random() * list.length)];
    st.recentNews.unshift(pick);
    st.recentNews.length = Math.min(st.recentNews.length, 8);
    return pick;
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
  const serialize = (st) => JSON.stringify(st);
  function deserialize(json) {
    try {
      const data = JSON.parse(json);
      if (!data || data.version !== SAVE_VERSION) return null;
      const st = Object.assign(newState(data.name), data);
      st.toasts = [];
      return st;
    } catch (e) { return null; }
  }

  root.Engine = {
    newState, cleanName, tick, click, buyGen, buyGenN, buyUpgrade, buyGreen, readFact, decide, buyOffset,
    claimGoal, answerPress, moveStage, finish, earnBadge,
    sustainability, sizePressure, greenMult, fineRate, eff, incomePerSec, genIncome, genMult, stars, clickValue, itPowerKW, facilityPowerKW, users,
    genCost, genCostN, maxAffordable, stageInfo, visibleGenerators, upgradeStatus, aiUpgrades, greenUpgrades, greenStatus, greenCost,
    offsetCost, endingFor, pollution, rankFor, boardAt, currentGoal, goalProgress, currentPrompt, fill, addNews, unlockFact,
    fmtNum, fmtEnergy, fmtPower, fmtMass, fmtWater, serialize, deserialize, genById, upById, greenById, decById,
  };
})(typeof window !== "undefined" ? window : globalThis);
