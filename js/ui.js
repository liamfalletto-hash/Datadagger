/* Main game screen: HUD, scene, left panels, shop and the game loop. */
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
      const vol = m3 < R.olympicPoolM3 ? `fills ${fmt(m3)} m³` : m3 < 1e8 ? `fills ${fmt(m3 / R.olympicPoolM3)} Olympic pools` : `a cube of CO₂ ${(Math.cbrt(m3) / 1000).toFixed(1)} km wide`;
      return kg < R.kgCo2PerCarYear ? `gas that ${vol}` : `≈ ${fmt(kg / R.kgCo2PerCarYear)} cars for a year · ${vol}`;
    },
    water: (l) => (l < R.olympicPoolL ? `≈ ${fmt(l / R.showerL)} showers` : `≈ ${fmt(l / R.olympicPoolL)} Olympic pools`),
    ewaste: (kg) => (kg < 5000 ? `≈ ${fmt(kg / R.smartphoneKg)} smartphones` : `≈ ${fmt(kg / R.truckKg)} lorry-loads`),
  };
  App.footprintRows = (fp) => [
    ["bolt", "Electricity", E.fmtEnergy(fp.kwh), App.eq.energy(fp.kwh)], ["cloud", "CO₂", E.fmtMass(fp.co2), App.eq.co2(fp.co2)],
    ["drop", "Water", E.fmtWater(fp.water), App.eq.water(fp.water)], ["trash", "E-waste", E.fmtMass(fp.ewaste), App.eq.ewaste(fp.ewaste)],
  ].map(([i, l, v, e]) => `<div class="fp-row">${A.icon(i)}<div><b>${v}</b><span>${l}: ${e}</span></div></div>`).join("");
  App.gauge = (v) => {
    const pt = (x, r) => { const a = Math.PI - (x / 100) * Math.PI; return [100 + r * Math.cos(a), 105 - r * Math.sin(a)]; };
    const arc = (a, b, c) => { const [x1, y1] = pt(a, 75), [x2, y2] = pt(b, 75); return `<path d="M${x1.toFixed(1)} ${y1.toFixed(1)}A75 75 0 0 1 ${x2.toFixed(1)} ${y2.toFixed(1)}" fill="none" stroke="${c}" stroke-width="20"/>`; };
    const a = Math.PI - (v / 100) * Math.PI, [tx, ty] = pt(v, 60), bx = 6 * Math.sin(a), by = 6 * Math.cos(a);
    return `<svg viewBox="0 0 200 118" aria-hidden="true"><path d="M25 105A75 75 0 0 1 175 105" fill="none" stroke="#2b2433" stroke-width="27"/>${arc(0, 40, "#ef7c64")}${arc(40, 70, "#f6c445")}${arc(70, 100, "#7cc36b")}<polygon points="${tx.toFixed(1)},${ty.toFixed(1)} ${(100 + bx).toFixed(1)},${(105 + by).toFixed(1)} ${(100 - bx).toFixed(1)},${(105 - by).toFixed(1)}" fill="#2b2433"/><circle cx="100" cy="105" r="10" fill="#fffaf0" stroke="#2b2433" stroke-width="3"/></svg>`;
  };
  App.rating = (s) => (s < 20 ? ["Very low", "#ef7c64"] : s < 40 ? ["Low", "#ef7c64"] : s < 55 ? ["Medium", "#f6c445"] : s < 70 ? ["Fair", "#f6c445"] : s < 85 ? ["Good", "#7cc36b"] : ["Excellent", "#7cc36b"]);

  /* ---------- scene ---------- */
  let sceneKey = "";
  App.view = () => {
    const st = App.st, e = E.eff(st);
    return { name: st.name, stage: st.stage, owned: st.owned, pollution: E.pollution(st), powerKw: E.itPowerKW(st), biome: st.factors.biome, ci: e.ci,
      badgeColors: st.badges.map((b) => badge(b).color) };
  };
  function renderScene(force) {
    const st = App.st, v = App.view();
    const key = [st.stage, JSON.stringify(st.owned), st.badges.length, Math.round(v.pollution * 12), v.biome, v.ci > 0.6, v.ci < 0.2, st.name].join("|");
    if (!force && key === sceneKey) return;
    sceneKey = key;
    const res = SC.forStage(st.stage, v);
    $("scene").innerHTML = res.svg;
    App.zoom = res.zoom;
    const b = $("bubble");
    b.style.left = (res.bubble[0] / 960) * 100 + "%";
    b.style.top = (res.bubble[1] / 690) * 100 + "%";
  }

  /* ---------- HUD ---------- */
  function renderHud() {
    const st = App.st, info = E.stageInfo(st), kw = E.facilityPowerKW(st);
    $("cash").textContent = money(st.cash);
    $("rate").textContent = `+${money(E.incomePerSec(st))}/s`;
    $("users").textContent = fmt(E.users(st));
    $("power").textContent = E.fmtPower(kw);
    $("day").textContent = `Day ${Math.floor(st.day % 365) + 1}`;
    $("year").textContent = `Year ${Math.floor(st.day / 365) + 1}`;
    $("stageName").textContent = info.stage.name;
    $("stageStep").textContent = `Stage ${st.stage} of ${G.stages.length}`;
    $("stageBar").style.width = info.progress * 100 + "%";
    $("stageLabel").textContent = info.ready ? "100% · ready!" : `${Math.floor(info.progress * 100)}% · earn ${money(info.stage.goal)} in total`;
    const mv = $("moveBtn");
    mv.classList.toggle("show", info.ready);
    mv.textContent = info.stage.move + " →";
    $("clickVal").textContent = "+" + money(E.clickValue(st));
  }

  /* ---------- left column ---------- */
  let rankKey = "";
  function renderRank() {
    const st = App.st, r = st.rank;
    const key = r + "|" + st.stage + "|" + (r === 1 ? Math.round(E.stageInfo(st).progress * 20) : 0);
    if (key === rankKey) return;
    rankKey = key;
    const ranks = r <= 4 ? [1, 2, 3, 4, 5] : [1, 2, 3, "gap", r - 1, r, r + 1];
    const rows = ranks.map((k) => {
      if (k === "gap") return `<li class="gap"><span>…</span><span></span></li>`;
      const e = E.boardAt(st, k);
      return `<li class="${e.you ? "you" : ""}"><span>#${k > 999 ? "999+" : k}</span><span>${A.esc(e.name)} <small>${e.you ? "you" : A.esc(e.by)}</small></span></li>`;
    }).join("");
    let next;
    if (r > 1) { const e = E.boardAt(st, r - 1); next = `Next to overtake: <b>${A.esc(e.name)}</b>`; }
    else { const lead = 1 + 9 * Math.max(0, Math.min(1, (E.stageInfo(st).progress - 0.3) / 0.7)); next = `<b>${A.esc(st.name)} is the world's #1 AI</b>${st.stage === 5 ? `, ${lead.toFixed(1)}× bigger than #2` : ""}.`; }
    $("rankCard").innerHTML = `<div class="rank-top"><span class="eyebrow">World AI ranking</span><span class="fict">just a game</span></div><div class="rank-big"><b>${r > 999 ? "#999+" : "#" + r}</b></div><ol class="rank-list">${rows}</ol><p class="rank-next">${next}</p>`;
  }

  let goalKey = "";
  function renderGoal() {
    const c = E.currentGoal(App.st), key = c ? `${c.index}|${c.have}|${c.done}` : "none" + App.st.stage;
    if (key === goalKey) return;
    goalKey = key;
    const el = $("goal");
    el.classList.toggle("done", !!(c && c.done));
    if (!c) { el.innerHTML = `<div class="goal-top"><span class="tag">Goals</span></div><h3>All goals done here. Fill the bar to move on!</h3>`; return; }
    el.innerHTML = `<div class="goal-top"><span class="tag">${c.done ? "Goal complete!" : "Goal"}</span><span class="goal-reward">Reward <b>${money(c.reward)}</b></span></div><h3>${fill(c.goal.text)}</h3>` +
      (c.done ? `<button class="buy" data-claim>Claim ${money(c.reward)}</button>` : `<div class="mini"><span style="width:${(c.have / c.need) * 100}%"></span><em>${c.goal.kind === "rank" ? "#" + Math.min(999, App.st.rank) : c.have + " / " + c.need}</em></div>`);
  }

  let susKey = "";
  function renderSus() {
    const st = App.st, el = $("sus");
    if (!st.revealed) {
      if (susKey !== "locked") { susKey = "locked"; el.className = "card impact"; el.innerHTML = `<span class="ico">${A.icon("lock")}</span><div><h3>Environmental impact</h3><p>Not measured yet. Nobody is asking… yet.</p></div>`; }
      return;
    }
    const s = E.sustainability(st), oc = E.offsetCost(st);
    const key = [s, st.offsets, st.cash >= oc, Math.floor(st.day / 2)].join("|");
    if (key === susKey) return;
    susKey = key;
    const [label, color] = App.rating(s), end = G.endings[E.endingFor(st)], m = E.sMult(st);
    el.className = "card sus";
    el.innerHTML = `<span class="eyebrow">Sustainability</span><div class="sus-top">${App.gauge(s)}<div class="sus-num"><b>${s}</b><small> / 100</small><br><span class="pill" style="background:${color}">${label}</span></div></div>` +
      `<p class="sus-line">Heading for: <b>${end.title}</b><br>Income ×<b>${m.toFixed(2)}</b> · ${s < 50 ? "cutting corners pays… for now" : "doing it right costs money"}</p>` +
      `<span class="eyebrow">Your footprint since day 1</span><div class="fp-list">${App.footprintRows(st.footprint)}</div>` +
      (st.offsets < 3 ? `<button class="buy gold" data-offset ${st.cash < oc ? "disabled" : ""}>Buy carbon offsets · ${money(oc)}</button><p class="sus-note">+3 sustainability each (${3 - st.offsets} left). Offsets don't remove your CO₂.</p>` : `<p class="sus-note">All carbon offsets bought. Your emissions didn't change.</p>`);
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
    const key = App.tab + unread + "|" + greenReady;
    if (key === tabsKey) return;
    tabsKey = key;
    $("tabs").innerHTML = Object.entries(TABS).map(([id, t]) => {
      const dot = id === "facts" && unread ? unread : id === "green" && greenReady ? greenReady : 0;
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
      `<p class="stats"><span class="earn">+${money(E.genIncome(st, g.id))}/s</span> · <span class="watt">${E.fmtPower(g.kw)}</span> each</p><div class="mile">${stars(k)}<div class="mini">${bar}</div></div></div>` +
      `<button class="buy" data-buy="${g.id}" ${st.cash < c ? "disabled" : ""}><small>BUY${n > 1 ? " ×" + n : ""}</small>${money(c)}</button></article>`;
  }
  function aiCard(u) {
    const st = App.st, status = E.upgradeStatus(st, u), e = u.effect, chips = [];
    if (e.all) chips.push(`<span class="chip-s gold">income ×${e.all}</span>`);
    if (e.gen) chips.push(`<span class="chip-s gold">${E.genById[e.gen].name} ×${e.mult}</span>`);
    if (e.click) chips.push(`<span class="chip-s gold">answers ×${e.click}</span>`);
    if (e.power) chips.push(`<span class="chip-s neg">+${Math.round((e.power - 1) * 100)}% power</span>`);
    if (u.s && st.revealed) chips.push(`<span class="chip-s neg">${u.s} sustainability</span>`);
    const need = u.req ? Object.entries(u.req).map(([gid, n]) => `Needs ${n} × ${E.genById[gid].name}`).join(", ") : "";
    const right = status === "owned" ? `<span class="pill read">Owned</span>` : status === "locked" ? `<span class="need">${need}</span>` : `<button class="buy" data-up="${u.id}" ${st.cash < u.cost ? "disabled" : ""}><small>BUY</small>${money(u.cost)}</button>`;
    return `<article class="item ${status === "locked" ? "locked" : ""}"><div class="thumb" style="background:var(--gold-soft)">${A.icon(u.icon)}</div><div><h3>${fill(u.name)}</h3><p class="stats">${fill(u.desc)}</p><div class="chips-row">${chips.join("")}</div></div>${right}</article>`;
  }
  function greenCard(g) {
    const st = App.st, status = E.greenStatus(st, g), c = E.greenCost(g), m = E.sMult(st);
    const drop = Math.round(((0.006 * g.s) / m) * 100);
    const chips = `<span class="chip-s pos">+${g.s} sustainability</span><span class="chip-s neg">income −${drop}%</span>`;
    let right;
    if (status === "owned") right = `<span class="pill read">Owned</span>`;
    else if (status === "needsFact") right = `<div style="text-align:right"><span class="need">Read the fact first</span><br><button class="linkish" data-gofact="${g.fact}">“${G.facts[g.fact].title}”</button></div>`;
    else right = `<button class="buy" data-green="${g.id}" ${st.cash < c ? "disabled" : ""}><small>BUY</small>${money(c)}</button>`;
    return `<article class="item ${status === "needsFact" ? "locked" : ""}"><div class="thumb" style="background:var(--mint-soft)">${A.icon(g.icon)}</div><div><h3>${g.name}</h3><p class="stats">${g.desc}</p><div class="chips-row">${chips}</div></div>${right}</article>`;
  }
  function factCard(id) {
    const st = App.st, f = G.facts[id], read = st.read.includes(id), unlocks = G.greenUpgrades.find((g) => g.fact === id);
    const src = f.url ? `<a href="${f.url}" target="_blank" rel="noopener">${f.source}</a>` : f.source;
    return `<article class="fact ${read ? "" : "unread"}" id="fact-${id}"><div class="fact-top"><span class="pill ${read ? "read" : "new"}">${read ? "Read" : "New"}</span></div><h3>${f.title}</h3><p class="body">${f.text}</p>` +
      (read ? `<p class="src">Source: ${src}</p><p class="uses">${A.icon("mic")} Can come up at a press conference</p>${unlocks ? `<p class="uses">${A.icon("leaf")} Unlocks green upgrade: ${unlocks.name}</p>` : ""}`
        : `<button class="buy gold" data-read="${id}">Read it</button>${unlocks ? `<p class="uses">${A.icon("leaf")} Unlocks a green upgrade</p>` : ""}`) + `</article>`;
  }
  function panelBody() {
    const st = App.st;
    if (App.tab === "hardware") {
      const next = G.generators.find((g) => g.stage > st.stage);
      return `<p class="hint">Everything you buy shows up in your company. Own 10, 25 and 50 of one item to double its income.</p>` +
        E.visibleGenerators(st).map(hardwareCard).join("") +
        (next ? `<article class="item locked"><div class="thumb" style="background:#ece8ef">${A.ART[next.id]}</div><div><h3>${next.name}</h3><p class="stats">${next.desc}</p><p class="stats"><b>Unlocks in stage ${next.stage}: ${G.stages[next.stage - 1].name}</b></p></div><span class="ico">${A.icon("lock")}</span></article>` : "");
    }
    if (App.tab === "ai") return `<p class="hint">Faster growth, more power. Some cost sustainability.</p>` + E.aiUpgrades(st).map(aiCard).join("");
    if (App.tab === "green") {
      if (!st.revealed) return `<p class="hint">Green upgrades appear once someone starts measuring your impact. Keep growing…</p><article class="fact more">${A.icon("lock")} Unlocks in the office.</article>`;
      return `<p class="hint">Cleaner company, less income. Each one is unlocked by reading its real fact.</p>` + E.greenUpgrades(st).map(greenCard).join("");
    }
    if (App.tab === "facts") {
      const left = Object.keys(G.facts).length - st.facts.length;
      return `<p class="hint">Read facts to prepare for press conferences (right answers pay) and to unlock green upgrades.</p>` +
        (st.facts.length ? [...st.facts].reverse().map(factCard).join("") : "") + (left ? `<article class="fact more">${A.icon("lock")} ${left} more facts unlock as you grow.</article>` : "");
    }
    const all = App.collection();
    return `<p class="hint">${all.length} of ${G.badges.length} badges collected. Badges stay between games. Each one earned this game hangs on your wall.</p><div class="badges">` +
      G.badges.map((b) => { const e = all.includes(b.id); return `<div class="badge ${e ? "" : "locked"}">${A.medal(b, e)}<b>${e ? b.name : "???"}</b><span>${b.how}</span></div>`; }).join("") + `</div>`;
  }
  let panelKey = "";
  function renderPanel(force) {
    const st = App.st;
    const afford = App.tab === "hardware" ? E.visibleGenerators(st).map((g) => { const n = buyN(g.id); return n + ":" + (st.cash >= (n === 1 ? E.genCost(st, g.id) : E.genCostN(st, g.id, n))); }).join(",")
      : App.tab === "ai" ? E.aiUpgrades(st).map((u) => st.cash >= u.cost).join(",") : App.tab === "green" ? E.greenUpgrades(st).map((g) => st.cash >= E.greenCost(g)).join(",") + Math.round(E.sMult(st) * 50) : "";
    const key = [App.tab, App.amount, st.stage, JSON.stringify(st.owned), Object.keys(st.upgrades).length, st.green.length, st.read.length, st.facts.length, st.badges.length, st.revealed, afford].join("|");
    if (!force && key === panelKey) return;
    panelKey = key;
    const t = TABS[App.tab], body = $("panel").querySelector(".panel-body"), scroll = body ? body.scrollTop : 0;
    const amount = App.tab === "hardware" ? `<div class="amount" role="group" aria-label="Buy amount">${["1", "10", "max"].map((a) => `<button data-amt="${a}" aria-pressed="${App.amount === a}">${a === "max" ? "Max" : "×" + a}</button>`).join("")}</div>` : "";
    $("panel").innerHTML = `<div class="panel-head ${t.color}"><h2>${t.title}</h2>${amount}</div><div class="panel-body">${panelBody()}</div>`;
    $("panel").querySelector(".panel-body").scrollTop = scroll;
  }

  /* ---------- news ticker ---------- */
  let tickerTop = null;
  function renderTicker() {
    const st = App.st;
    if (st.news[0] === tickerTop) return;
    tickerTop = st.news[0];
    const line = (st.news.length ? st.news.slice(0, 6).map((n) => n.text) : [fill("{name} is born in a garage.")]).join("   •   ") + "   •   ";
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
  function drainToasts() {
    const st = App.st;
    while (st.toasts.length) {
      const t = st.toasts.shift();
      if (t.type === "badge") {
        const b = badge(t.id);
        App.collect(t.id);
        App.toast(`${A.medal(b, true)}<div><span class="eyebrow">Badge unlocked</span><b>${b.name}</b>${b.how}</div>`, "", 6500);
      } else if (t.type === "fact") {
        const f = G.facts[t.id];
        App.toast(`<span class="t-ico">${A.icon("book")}</span><div><span class="eyebrow">New real fact</span><b>${f.title}</b>Read it in the Real facts tab.</div>`, "", 7000);
      } else if (t.type === "rank") {
        App.toast(`<span class="t-ico">${A.icon("trophy")}</span><div><b>${A.esc(t.text)}</b></div>`, "good", 6000);
      } else App.toast(`<div>${A.esc(t.text)}</div>`, t.kind, 6000);
    }
  }

  /* ---------- input ---------- */
  $("bubble").addEventListener("click", () => {
    const st = App.st;
    if (!App.running || App.modalOpen || st.ended) return;
    const v = E.click(st);
    $("promptText").textContent = `“${E.currentPrompt(st)}”`;
    const sr = $("stage").getBoundingClientRect(), br = $("bubble").getBoundingClientRect(), f = document.createElement("span");
    f.className = "floater";
    f.textContent = "+" + money(v);
    f.style.left = br.left - sr.left + br.width / 2 + (Math.random() * 40 - 20) + "px";
    f.style.top = br.top - sr.top - 8 + "px";
    $("stage").appendChild(f);
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
    $("app").hidden = false;
    $("promptText").textContent = `“${E.currentPrompt(st)}”`;
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
