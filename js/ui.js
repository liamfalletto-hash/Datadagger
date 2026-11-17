/* Main game screen: full-screen world, floating panels, shop and the game loop. */
(function () {
  const G = window.GAME, E = window.Engine, A = window.AetherArt, SC = window.AetherScenes;
  const $ = (id) => document.getElementById(id);
  const fmt = E.fmtNum, money = (n) => (n < 0 ? "−$" + fmt(-n) : "$" + fmt(n));
  const SAVE = "aether-save-v2", BADGES = "aether-badges-v1", R = G.REF;
  const params = new URLSearchParams(location.search);
  const SPEED = location.hash === "#fast" ? 5 : Math.max(0.1, Math.min(50, Number(params.get("speed")) || 1));
  const App = (window.App = { st: null, running: false, modalOpen: false, tab: "hardware", amount: "1", money, fmt, $ });

  /* ---------- storage (always optional) ---------- */
  const load = (k) => { try { return localStorage.getItem(k); } catch (e) { return null; } };
  const store = (k, v) => { try { localStorage.setItem(k, v); } catch (e) { /* ignore */ } };
  App.loadSave = () => { const raw = load(SAVE), s = raw && E.deserialize(raw); return s && !s.ended ? s : null; };
  App.save = () => { if (App.st && !App.st.ended) store(SAVE, E.serialize(App.st)); };
  App.clearSave = () => { try { localStorage.removeItem(SAVE); } catch (e) { /* ignore */ } };
  App.collection = () => { try { return JSON.parse(load(BADGES) || "[]"); } catch (e) { return []; } };
  App.collect = (id) => { const c = App.collection(); if (!c.includes(id)) { c.push(id); store(BADGES, JSON.stringify(c)); } return c; };

  /* ---------- helpers ---------- */
  const fill = (t) => E.fill(App.st, t);
  const badge = (id) => G.badges.find((b) => b.id === id);
  App.eq = {
    energy: (kwh) => (kwh / R.homeKwhYear < 1 ? `≈ ${fmt(kwh / R.phoneChargeKwh)} phone charges` : `≈ ${fmt(kwh / R.homeKwhYear)} homes for a year`),
    co2: (kg) => {
      const m3 = (kg / 1000) * R.m3PerTonneCo2;
      return m3 < R.olympicPoolM3 ? `fills ${fmt(m3)} m³` : m3 < 1e8 ? `fills ${fmt(m3 / R.olympicPoolM3)} Olympic pools` : `a cube of gas ${(Math.cbrt(m3) / 1000).toFixed(1)} km wide`;
    },
    water: (l) => (l < R.olympicPoolL ? `≈ ${fmt(l / R.showerL)} showers` : `≈ ${fmt(l / R.olympicPoolL)} Olympic pools`),
    ewaste: (kg) => (kg < 5000 ? `≈ ${fmt(kg / R.smartphoneKg)} smartphones` : `≈ ${fmt(kg / R.truckKg)} lorry-loads`),
  };
  App.footprintRows = (fp, all) => [
    ["cloud", "CO₂", E.fmtMass(fp.co2), App.eq.co2(fp.co2)], ["bolt", "Electricity", E.fmtEnergy(fp.kwh), App.eq.energy(fp.kwh)],
    ["drop", "Water", E.fmtWater(fp.water), App.eq.water(fp.water)], ...(all ? [["trash", "E-waste", E.fmtMass(fp.ewaste), App.eq.ewaste(fp.ewaste)]] : []),
  ].map(([i, l, v, e]) => `<div class="fp-row">${A.icon(i)}<div><b>${v} ${l === "CO₂" ? "CO₂" : ""}</b><span>${e}</span></div></div>`).join("");
  App.gauge = (v) => {
    const pt = (x, r) => { const a = Math.PI - (x / 100) * Math.PI; return [100 + r * Math.cos(a), 105 - r * Math.sin(a)]; };
    const arc = (a, b, c) => { const [x1, y1] = pt(a, 75), [x2, y2] = pt(b, 75); return `<path d="M${x1.toFixed(1)} ${y1.toFixed(1)}A75 75 0 0 1 ${x2.toFixed(1)} ${y2.toFixed(1)}" fill="none" stroke="${c}" stroke-width="20"/>`; };
    const a = Math.PI - (v / 100) * Math.PI, [tx, ty] = pt(v, 60), bx = 6 * Math.sin(a), by = 6 * Math.cos(a);
    return `<svg viewBox="0 0 200 118" aria-hidden="true"><path d="M25 105A75 75 0 0 1 175 105" fill="none" stroke="#2b2433" stroke-width="27"/>${arc(0, 40, "#ef7c64")}${arc(40, 70, "#f6c445")}${arc(70, 100, "#7cc36b")}<polygon points="${tx.toFixed(1)},${ty.toFixed(1)} ${(100 + bx).toFixed(1)},${(105 + by).toFixed(1)} ${(100 - bx).toFixed(1)},${(105 - by).toFixed(1)}" fill="#2b2433"/><circle cx="100" cy="105" r="10" fill="#fffaf0" stroke="#2b2433" stroke-width="3"/></svg>`;
  };
  App.rating = (s) => (s < 15 ? ["On fire", "#ef7c64"] : s < 40 ? ["Bad", "#ef7c64"] : s < 55 ? ["Medium", "#f6c445"] : s < 70 ? ["Fair", "#f6c445"] : s < 85 ? ["Good", "#7cc36b"] : ["Excellent", "#7cc36b"]);

  /* ---------- world (full-screen scene) ---------- */
  const compactMQ = window.matchMedia ? matchMedia("(max-width: 900px)") : { matches: false };
  function applyFrame() {
    $("scene").setAttribute("viewBox", compactMQ.matches ? "120 -10 720 680" : "-180 -110 1440 900");
    placeBubble();
  }
  // Scene coordinates → pixels inside the world box ("meet" scaling).
  App.toScreen = (pt) => {
    const svg = $("scene"), r = svg.getBoundingClientRect(), vb = svg.viewBox.baseVal;
    const sc = Math.min(r.width / vb.width, r.height / vb.height), ox = (r.width - vb.width * sc) / 2, oy = (r.height - vb.height * sc) / 2;
    return [ox + (pt[0] - vb.x) * sc, oy + (pt[1] - vb.y) * sc];
  };
  function placeBubble() {
    if (!App.bubbleAt) return;
    const [x, y] = App.toScreen(App.bubbleAt), b = $("bubble");
    b.style.left = x + "px";
    b.style.top = y + "px";
  }
  window.addEventListener("resize", applyFrame);

  let sceneKey = "";
  App.view = () => {
    const st = App.st, e = E.eff(st);
    return { name: st.name, stage: st.stage, owned: st.owned, pollution: E.pollution(st), powerKw: E.itPowerKW(st), biome: st.factors.biome, ci: e.ci,
      badgeColors: st.badges.map((b) => badge(b).color) };
  };
  function renderScene(force) {
    const st = App.st, v = App.view();
    const key = [st.stage, JSON.stringify(st.owned), st.badges.length, Math.round(v.pollution * 16), v.biome, v.ci > 0.6, v.ci < 0.2, st.name].join("|");
    if (!force && key === sceneKey) return;
    sceneKey = key;
    const res = SC.forStage(st.stage, v);
    $("scene").innerHTML = res.svg;
    App.zoom = res.zoom;
    App.bubbleAt = res.bubble;
    placeBubble();
  }

  /* ---------- HUD ---------- */
  function renderHud() {
    const st = App.st, info = E.stageInfo(st);
    $("cash").textContent = money(st.cash);
    $("rate").textContent = `+${money(E.incomePerSec(st))}/s`;
    $("power").textContent = E.fmtPower(E.facilityPowerKW(st));
    $("stageName").textContent = info.stage.name;
    $("stageStep").textContent = `Stage ${st.stage} of ${G.stages.length}`;
    $("stageBar").style.width = info.progress * 100 + "%";
    $("stageLabel").textContent = info.ready ? "Ready to move on!" : `${Math.floor(info.progress * 100)}%`;
    const mv = $("moveBtn");
    mv.classList.toggle("show", info.ready);
    mv.textContent = info.stage.move + " →";
    $("clickVal").textContent = "+" + money(E.clickValue(st));
  }

  /* ---------- left column ---------- */
  let rankKey = "";
  function renderRank() {
    const st = App.st, r = st.rank;
    const key = r + "|" + st.stage;
    if (key === rankKey) return;
    rankKey = key;
    const ranks = r <= 2 ? [1, 2, 3] : [r - 1, r, r + 1];
    const rows = ranks.map((k) => {
      const e = E.boardAt(st, k);
      return `<li class="${e.you ? "you" : ""}"><span>#${k > 999 ? "999+" : k}</span><span>${A.esc(e.name)} <small>${e.you ? "you" : A.esc(e.by)}</small></span></li>`;
    }).join("");
    $("rankCard").innerHTML = `<div class="rank-top"><span class="eyebrow">World AI ranking</span><span class="fict">just a game</span></div><div class="rank-big"><b>${r > 999 ? "#999+" : "#" + r}</b></div><ol class="rank-list">${rows}</ol>`;
  }

  let goalKey = "";
  function renderGoal() {
    const c = E.currentGoal(App.st), key = c ? `${c.index}|${c.have}|${c.done}` : "none" + App.st.stage;
    if (key === goalKey) return;
    goalKey = key;
    const el = $("goal");
    el.classList.toggle("done", !!(c && c.done));
    if (!c) { el.innerHTML = `<div class="goal-top"><span class="tag">Goals</span></div><h3>All done here. Fill the bar to move on!</h3>`; return; }
    el.innerHTML = `<div class="goal-top"><span class="tag">${c.done ? "Goal complete!" : "Goal"}</span><span class="goal-reward">Reward <b>${money(c.reward)}</b></span></div><h3>${fill(c.goal.text)}</h3>` +
      (c.done ? `<button class="buy" data-claim>Claim ${money(c.reward)}</button>` : `<div class="mini"><span style="width:${(c.have / c.need) * 100}%"></span><em>${c.goal.kind === "rank" ? "#" + Math.min(999, App.st.rank) : c.have + " / " + c.need}</em></div>`);
  }

  let susKey = "";
  function renderSus() {
    const st = App.st, el = $("sus");
    if (!st.revealed) {
      if (susKey !== "locked") { susKey = "locked"; el.className = "card impact"; el.innerHTML = `<span class="ico">${A.icon("lock")}</span><div><h3>Environmental impact</h3><p>Not measured yet.</p></div>`; }
      return;
    }
    const s = E.sustainability(st), oc = E.offsetCost(st), fr = E.fineRate(st);
    const key = [s, st.offsets, st.cash >= oc, Math.floor(st.day / 3)].join("|");
    if (key === susKey) return;
    susKey = key;
    const [label, color] = App.rating(s), end = G.endings[E.endingFor(st)];
    const fines = fr ? `<div class="sus-fines bad">Fines about every ${Math.round(fr.every)} s</div>` : `<div class="sus-fines">No fines (stay above 65)</div>`;
    el.className = "card sus";
    el.innerHTML = `<span class="eyebrow">Sustainability</span><div class="sus-score">${App.gauge(s)}<div><b style="color:${s < 40 ? "var(--coral-dark)" : "var(--ink)"}">${s}</b><br><span class="pill" style="background:${color}">${label}</span></div></div>` +
      fines + `<p class="sus-size">Ending so far: <b>${end.title}</b> · your size: −${E.sizePressure(st)}</p>` +
      `<div class="fp-list">${App.footprintRows(st.footprint)}</div>` +
      (st.offsets < 3 ? `<button class="buy gold" data-offset ${st.cash < oc ? "disabled" : ""}>Carbon offsets +3 · ${money(oc)}</button>` : "");
  }

  /* ---------- shop ---------- */
  const TABS = {
    hardware: { title: "Hardware", color: "blue", icon: "chip" }, ai: { title: "AI upgrades", color: "gold", icon: "up" },
    green: { title: "Green upgrades", color: "green", icon: "leaf" }, facts: { title: "Real facts", color: "coral", icon: "book" },
    badges: { title: "Badges", color: "violet", icon: "medal" },
  };
  let tabsKey = "";
  function renderTabs() {
    const st = App.st, unread = st.facts.filter((f) => !st.read.includes(f)).length;
    const greenReady = st.revealed ? E.greenUpgrades(st).filter((g) => E.greenStatus(st, g) === "available").length : 0;
    const aiReady = E.aiUpgrades(st).filter((u) => E.upgradeStatus(st, u) === "available").length;
    const key = App.tab + unread + "|" + greenReady + "|" + aiReady;
    if (key === tabsKey) return;
    tabsKey = key;
    $("tabs").innerHTML = Object.entries(TABS).map(([id, t]) => {
      const dot = id === "facts" ? unread : id === "green" ? greenReady : id === "ai" ? aiReady : 0;
      return `<button class="tab ${t.color}" role="tab" aria-selected="${App.tab === id}" aria-label="${t.title}" title="${t.title}" data-tab="${id}">${A.icon(t.icon)}${dot ? `<span class="dot">${dot}</span>` : ""}</button>`;
    }).join("");
  }
  const stars = (n) => `<span class="stars">${[0, 1, 2].map((i) => A.icon(i < n ? "star" : "starOff")).join("")}</span>`;
  const buyN = (gid) => (App.amount === "max" ? Math.max(1, E.maxAffordable(App.st, gid)) : Number(App.amount));
  function hardwareCard(g) {
    const st = App.st, o = st.owned[g.id], ms = G.MILESTONES, k = E.stars(st, g.id), lo = k ? ms[k - 1] : 0, hi = ms[Math.min(k, 2)];
    const n = buyN(g.id), c = n === 1 ? E.genCost(st, g.id) : E.genCostN(st, g.id, n);
    const bar = k >= 3 ? `<span style="width:100%"></span><em>max</em>` : `<span style="width:${Math.min(100, ((o - lo) / (hi - lo)) * 100)}%"></span><em>${o}/${hi}</em>`;
    return `<article class="item"><div class="thumb" style="background:var(--blue-soft)">${A.ART[g.id]}</div><div><h3>${g.name} <span class="owned">×${o}</span></h3>` +
      `<p class="earn-line">+${money(E.genIncome(st, g.id))}/s each</p><div class="mile">${stars(k)}<div class="mini">${bar}</div></div></div>` +
      `<button class="buy" data-buy="${g.id}" ${st.cash < c ? "disabled" : ""}><small>BUY${n > 1 ? " ×" + n : ""}</small>${money(c)}</button></article>`;
  }
  function aiCard(u) {
    const st = App.st, status = E.upgradeStatus(st, u), e = u.effect, chips = [];
    if (e.all) chips.push(`<span class="chip-s gold">income ×${e.all}</span>`);
    if (e.gen) chips.push(`<span class="chip-s gold">${E.genById[e.gen].name} ×${e.mult}</span>`);
    if (e.click) chips.push(`<span class="chip-s gold">answers ×${e.click}</span>`);
    if (e.power) chips.push(`<span class="chip-s neg">+${Math.round((e.power - 1) * 100)}% power</span>`);
    if (u.s && st.revealed) chips.push(`<span class="chip-s neg">${u.s} sustainability</span>`);
    const need = u.req ? Object.entries(u.req).map(([gid, n]) => `Needs ${n} ${E.genById[gid].name}`).join(", ") : "";
    const right = status === "locked" ? `<span class="need">${need}</span>` : `<button class="buy" data-up="${u.id}" ${st.cash < u.cost ? "disabled" : ""}><small>BUY</small>${money(u.cost)}</button>`;
    return `<article class="item ${status === "locked" ? "locked" : ""}"><div class="thumb" style="background:var(--gold-soft)">${A.icon(u.icon)}</div><div><h3>${fill(u.name)}</h3><div class="chips-row">${chips.join("")}</div></div>${right}</article>`;
  }
  function greenCard(g) {
    const st = App.st, status = E.greenStatus(st, g), c = E.greenCost(g);
    const chips = `<span class="chip-s pos">+${g.s} sustainability</span><span class="chip-s neg">income −${Math.round((1 - g.income) * 100)}%</span>`;
    const right = status === "needsFact" ? `<button class="linkish" data-gofact="${g.fact}">Read the fact to unlock</button>` : `<button class="buy" data-green="${g.id}" ${st.cash < c ? "disabled" : ""}><small>BUY</small>${money(c)}</button>`;
    return `<article class="item ${status === "needsFact" ? "locked" : ""}"><div class="thumb" style="background:var(--mint-soft)">${A.icon(g.icon)}</div><div><h3>${g.name}</h3><div class="chips-row">${chips}</div></div>${right}</article>`;
  }
  function factCard(id) {
    const st = App.st, f = G.facts[id], read = st.read.includes(id), unlocks = G.greenUpgrades.find((g) => g.fact === id);
    if (!read) return `<article class="fact unread" id="fact-${id}"><h3>${f.title}</h3><button class="buy gold" data-read="${id}">Read</button></article>`;
    const src = f.url ? `<a href="${f.url}" target="_blank" rel="noopener">${f.source}</a>` : f.source;
    return `<article class="fact" id="fact-${id}"><h3>${f.title}</h3><p class="body">${f.text}</p><p class="src">${src}</p>${unlocks ? `<p class="uses">${A.icon("leaf")} Unlocks: ${unlocks.name}</p>` : ""}</article>`;
  }
  // Newest and best first; owned things folded into one line at the end.
  function panelBody() {
    const st = App.st;
    if (App.tab === "hardware") {
      const next = G.generators.find((g) => g.stage > st.stage);
      return E.visibleGenerators(st).slice().reverse().map(hardwareCard).join("") +
        (next ? `<article class="item locked"><div class="thumb" style="background:#ece8ef">${A.ART[next.id]}</div><div><h3>${next.name}</h3><p class="stats">Unlocks in stage ${next.stage}</p></div><span class="ico">${A.icon("lock")}</span></article>` : "");
    }
    if (App.tab === "ai") {
      const list = E.aiUpgrades(st).slice().reverse(), owned = list.filter((u) => E.upgradeStatus(st, u) === "owned").length;
      const open = list.filter((u) => E.upgradeStatus(st, u) === "available"), locked = list.filter((u) => E.upgradeStatus(st, u) === "locked");
      return open.concat(locked).map(aiCard).join("") + (owned ? `<p class="owned-line">${owned} upgrade${owned > 1 ? "s" : ""} owned</p>` : "") + (!open.length && !locked.length ? `<p class="owned-line">Nothing new yet. Keep growing!</p>` : "");
    }
    if (App.tab === "green") {
      if (!st.revealed) return `<article class="fact more">${A.icon("lock")} Unlocks in the office.</article>`;
      const list = E.greenUpgrades(st).slice().reverse(), owned = list.filter((g) => E.greenStatus(st, g) === "owned").length;
      const open = list.filter((g) => E.greenStatus(st, g) === "available"), locked = list.filter((g) => E.greenStatus(st, g) === "needsFact");
      return open.concat(locked).map(greenCard).join("") + (owned ? `<p class="owned-line">${owned} green upgrade${owned > 1 ? "s" : ""} owned</p>` : "");
    }
    if (App.tab === "facts") {
      const unread = st.facts.filter((f) => !st.read.includes(f)).reverse(), read = st.read.slice().reverse();
      return unread.concat(read).map(factCard).join("") || `<article class="fact more">${A.icon("lock")} Facts unlock as you grow.</article>`;
    }
    const all = App.collection();
    return `<p class="owned-line">${all.length} / ${G.badges.length} collected</p><div class="badges">` +
      G.badges.map((b) => { const e = all.includes(b.id); return `<div class="badge ${e ? "" : "locked"}">${A.medal(b, e)}<b>${e ? b.name : "???"}</b><span>${b.how}</span></div>`; }).join("") + `</div>`;
  }
  let panelKey = "";
  function renderPanel(force) {
    const st = App.st;
    const afford = App.tab === "hardware" ? E.visibleGenerators(st).map((g) => { const n = buyN(g.id); return n + ":" + (st.cash >= (n === 1 ? E.genCost(st, g.id) : E.genCostN(st, g.id, n))); }).join(",")
      : App.tab === "ai" ? E.aiUpgrades(st).map((u) => st.cash >= u.cost).join(",") : App.tab === "green" ? E.greenUpgrades(st).map((g) => st.cash >= E.greenCost(g)).join(",") : "";
    const key = [App.tab, App.amount, st.stage, JSON.stringify(st.owned), Object.keys(st.upgrades).length, st.green.length, st.read.length, st.facts.length, st.badges.length, st.revealed, afford].join("|");
    if (!force && key === panelKey) return;
    panelKey = key;
    const t = TABS[App.tab], body = $("panel").querySelector(".panel-body"), scroll = body ? body.scrollTop : 0;
    const amount = App.tab === "hardware" ? `<div class="amount" role="group" aria-label="Buy amount">${["1", "10", "max"].map((a) => `<button data-amt="${a}" aria-pressed="${App.amount === a}">${a === "max" ? "Max" : "×" + a}</button>`).join("")}</div>` : "";
    $("panel").innerHTML = `<div class="panel-head ${t.color}"><h2>${t.title}</h2>${amount}</div><div class="panel-body">${panelBody()}</div>`;
    $("panel").querySelector(".panel-body").scrollTop = scroll;
  }

  /* ---------- news bar ---------- */
  let tickerTop = null;
  function renderTicker() {
    const st = App.st;
    if (st.news[0] === tickerTop) return;
    tickerTop = st.news[0];
    const line = (st.news.length ? st.news.slice(0, 6).map((n) => n.text) : [fill("{name} is born in a garage.")]).join("     •     ") + "     •     ";
    $("tickerText").textContent = line + line;
  }

  /* ---------- toasts ---------- */
  App.toast = (html, kind, life = 6000) => {
    const el = document.createElement("div");
    el.className = "toast card " + (kind || "");
    el.innerHTML = html;
    const box = $("toasts");
    box.prepend(el);
    while (box.children.length > 3) box.lastChild.remove();
    const kill = () => el.remove();
    el.addEventListener("click", kill);
    setTimeout(kill, life);
  };
  function cashHit(amount) {
    const chip = $("cashChip");
    chip.classList.remove("flash");
    void chip.offsetWidth;
    chip.classList.add("flash");
    const f = document.createElement("span"), r = chip.getBoundingClientRect();
    f.className = "floater";
    f.style.position = "fixed";
    f.style.color = "var(--coral)";
    f.textContent = "−" + money(amount);
    f.style.left = r.left + r.width / 2 + "px";
    f.style.top = r.bottom + 8 + "px";
    document.body.appendChild(f);
    setTimeout(() => f.remove(), 900);
  }
  function drainToasts() {
    const st = App.st;
    while (st.toasts.length) {
      const t = st.toasts.shift();
      if (t.type === "fine") {
        cashHit(t.amount);
        App.toast(`<span class="t-ico" style="background:#fde3dc">${A.icon("note")}</span><div><b>Fined −${money(t.amount)}</b>Low sustainability = more fines.</div>`, "fine", 4500);
      } else if (t.type === "badge") {
        const b = badge(t.id);
        App.collect(t.id);
        App.toast(`${A.medal(b, true)}<div><span class="eyebrow">Badge unlocked</span><b>${b.name}</b></div>`, "", 5000);
      } else if (t.type === "fact") {
        App.toast(`<span class="t-ico">${A.icon("book")}</span><div><b>New real fact</b>${G.facts[t.id].title}</div>`, "", 5000);
      } else if (t.type === "rank") {
        App.toast(`<span class="t-ico">${A.icon("trophy")}</span><div><b>${A.esc(t.text)}</b></div>`, "good", 5000);
      } else App.toast(`<div>${A.esc(t.text)}</div>`, t.kind, 5000);
    }
  }

  /* ---------- input ---------- */
  $("bubble").addEventListener("click", () => {
    const st = App.st;
    if (!App.running || App.modalOpen || st.ended) return;
    const v = E.click(st);
    $("promptText").textContent = `“${E.currentPrompt(st)}”`;
    const wr = $("world").getBoundingClientRect(), br = $("bubble").getBoundingClientRect(), f = document.createElement("span");
    f.className = "floater";
    f.textContent = "+" + money(v);
    f.style.left = br.left - wr.left + br.width / 2 + (Math.random() * 40 - 20) + "px";
    f.style.top = br.top - wr.top - 8 + "px";
    $("world").appendChild(f);
    setTimeout(() => f.remove(), 900);
  });
  $("tabs").addEventListener("click", (ev) => { const b = ev.target.closest("[data-tab]"); if (b) { App.tab = b.dataset.tab; tabsKey = ""; renderTabs(); renderPanel(true); } });
  $("panel").addEventListener("click", (ev) => {
    const t = ev.target.closest("button"), st = App.st;
    if (!t || t.disabled || App.modalOpen) return;
    if (t.dataset.amt) App.amount = t.dataset.amt;
    else if (t.dataset.buy) E.buyGenN(st, t.dataset.buy, buyN(t.dataset.buy));
    else if (t.dataset.up) E.buyUpgrade(st, t.dataset.up);
    else if (t.dataset.green) E.buyGreen(st, t.dataset.green);
    else if (t.dataset.read) {
      const g = E.readFact(st, t.dataset.read);
      if (g && st.revealed) App.toast(`<span class="t-ico">${A.icon("leaf")}</span><div><b>Green upgrade unlocked</b>${g.name}</div>`, "good");
    } else if (t.dataset.gofact) {
      App.tab = "facts"; tabsKey = ""; renderTabs(); renderPanel(true);
      const el = document.getElementById("fact-" + t.dataset.gofact);
      if (el) el.scrollIntoView({ block: "center" });
      return;
    }
    renderPanel(true);
  });
  $("goal").addEventListener("click", (ev) => { if (ev.target.closest("[data-claim]")) { E.claimGoal(App.st); goalKey = ""; } });
  $("sus").addEventListener("click", (ev) => { if (ev.target.closest("[data-offset]")) { E.buyOffset(App.st); susKey = ""; } });
  $("moveBtn").addEventListener("click", () => { if (!App.modalOpen && E.moveStage(App.st)) { renderAll(true); App.save(); } });
  document.querySelectorAll("[data-icon]").forEach((el) => { el.innerHTML = A.icon(el.dataset.icon); });

  /* ---------- loop ---------- */
  function renderAll(force) {
    if (force) { sceneKey = panelKey = rankKey = goalKey = susKey = tabsKey = ""; }
    renderHud(); renderScene(); renderRank(); renderGoal(); renderSus(); renderTabs(); renderPanel(); renderTicker();
    if (!App.modalOpen) drainToasts();
  }
  App.renderAll = renderAll;
  App.start = (st) => {
    App.st = st;
    App.running = true;
    $("world").hidden = false;
    $("app").hidden = false;
    $("newsbar").hidden = false;
    $("promptText").textContent = `“${E.currentPrompt(st)}”`;
    applyFrame();
    renderAll(true);
  };
  let last = performance.now(), lastRender = 0, lastSave = 0;
  function frame(now) {
    const dt = Math.min((now - last) / 1000, 1) * SPEED;
    last = now;
    const st = App.st;
    if (st && App.running && !App.modalOpen && !st.ended) {
      E.tick(st, dt);
      if (st.queue.length && window.Screens) window.Screens.openModal(st.queue[0]);
    }
    if (st && App.running && now - lastRender > 100) { lastRender = now; renderAll(); }
    if (now - lastSave > 5000) { lastSave = now; App.save(); }
    requestAnimationFrame(frame);
  }
  requestAnimationFrame(frame);
  window.addEventListener("beforeunload", () => App.save());
})();
