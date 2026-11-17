/* AETHER — user interface. Reads the engine state and draws it. */
(function () {
  const G = window.GAME;
  const E = window.Engine;
  const R = G.REF;
  const SAVE_KEY = "aether-save-v1";
  const params = new URLSearchParams(location.search);
  // ?speed=5 (local file) or #fast (anywhere) speeds the game up for demos.
  const SPEED = location.hash === "#fast" ? 5 : Math.max(0.1, Math.min(50, Number(params.get("speed")) || 1));
  const $ = (id) => document.getElementById(id);
  const fmt = E.fmtNum;
  const money = (n) => (n < 0 ? "−$" + fmt(-n) : "$" + fmt(n));
  const TOTAL_FACTS = Object.keys(G.facts).length;

  let st = load() || E.newState();
  let modalOpen = false;
  let activeTab = "news";
  let buyAmt = "1";
  let genKey = "", upKey = "", bKey = "", choicesKey = "";
  let lastNewsTop = null, unreadNews = 0;
  let lastFactCount = -1, seenFacts = st.facts.length;
  let lastFrame = performance.now(), lastRender = 0, lastSave = 0, lastPuff = 0;

  /* ---------------- save / load ---------------- */
  function load() {
    try {
      const raw = localStorage.getItem(SAVE_KEY);
      if (!raw) return null;
      const s = E.deserialize(raw);
      return s && !s.ended ? s : null;
    } catch (e) { return null; }
  }
  function save() { try { localStorage.setItem(SAVE_KEY, E.serialize(st)); } catch (e) { /* storage unavailable */ } }
  function clearSave() { try { localStorage.removeItem(SAVE_KEY); } catch (e) { /* ignore */ } }

  /* ---------------- equivalences ---------------- */
  function eqEnergy(kwh) {
    const homes = kwh / R.homeKwhYear;
    if (homes < 1) return `≈ ${fmt(kwh / R.phoneChargeKwh)} phone charges`;
    return `≈ ${fmt(homes)} homes for a year`;
  }
  function co2Volume(kg) {
    const m3 = (kg / 1000) * R.m3PerTonneCo2;
    if (m3 < R.olympicPoolM3) return `fills ${fmt(m3)} m³`;
    if (m3 < 1e8) return `fills ${fmt(m3 / R.olympicPoolM3)} Olympic pools`;
    const side = Math.cbrt(m3);
    return `a CO₂ cube ${(side / 1000).toFixed(1)} km wide`;
  }
  function eqCo2(kg) {
    if (kg < R.kgCo2PerCarYear) return `gas that ${co2Volume(kg)}`;
    return `≈ ${fmt(kg / R.kgCo2PerCarYear)} cars for a year · ${co2Volume(kg)}`;
  }
  function eqWater(l) {
    if (l < R.olympicPoolL) return `≈ ${fmt(l / R.showerL)} showers`;
    return `≈ ${fmt(l / R.olympicPoolL)} Olympic pools`;
  }
  function eqEwaste(kg) {
    if (kg < 5000) return `≈ ${fmt(kg / R.smartphoneKg)} smartphones`;
    return `≈ ${fmt(kg / R.truckKg)} lorry-loads`;
  }
  function footprintCells(fp, cls) {
    return `
      <div class="${cls}"><div class="fp-label">⚡ Electricity</div><div class="fp-value">${E.fmtEnergy(fp.kwh)}</div><div class="fp-eq">${eqEnergy(fp.kwh)}</div></div>
      <div class="${cls}"><div class="fp-label">🏭 CO₂ emitted</div><div class="fp-value">${E.fmtMass(fp.co2)}</div><div class="fp-eq">${eqCo2(fp.co2)}</div></div>
      <div class="${cls}"><div class="fp-label">💧 Water evaporated</div><div class="fp-value">${E.fmtWater(fp.water)}</div><div class="fp-eq">${eqWater(fp.water)}</div></div>
      <div class="${cls}"><div class="fp-label">♻️ E-waste</div><div class="fp-value">${E.fmtMass(fp.ewaste)}</div><div class="fp-eq">${eqEwaste(fp.ewaste)}</div></div>`;
  }

  function rating(s) {
    if (s < 20) return ["Very low", "var(--bad)"];
    if (s < 40) return ["Low", "var(--bad)"];
    if (s < 55) return ["Medium", "var(--warn)"];
    if (s < 70) return ["Fair", "var(--warn)"];
    if (s < 85) return ["Good", "var(--good)"];
    return ["Excellent", "var(--good)"];
  }

  function factHTML(id, cls) {
    const f = G.facts[id];
    if (!f) return "";
    const src = f.url ? `<a href="${f.url}" target="_blank" rel="noopener">${f.source}</a>` : f.source;
    if (cls === "factbox") {
      return `<div class="factbox"><div class="fb-title">📊 Real fact: ${f.icon} ${f.title}</div>${f.text}<div class="fb-src">Source: ${src}</div></div>`;
    }
    return `<div class="fact"><div class="fact-title">${f.icon} ${f.title}</div>${f.text}<div class="fact-src">Source: ${src}</div></div>`;
  }

  function sChip(s) {
    if (!s) return `<span class="chip neu">🌍 ±0</span>`;
    return `<span class="chip ${s > 0 ? "pos" : "neg"}">🌍 ${s > 0 ? "+" : "−"}${Math.abs(s)} sustainability</span>`;
  }

  /* ---------------- top bar & progress ---------------- */
  function renderTop() {
    $("cash").textContent = money(st.cash);
    $("income").textContent = "+" + money(E.incomePerSec(st)) + "/s";
    $("users").textContent = fmt(E.users(st));
    $("power").textContent = E.fmtPower(E.facilityPowerKW(st));
    const y = Math.floor(st.day / 365) + 1, d = Math.floor(st.day % 365) + 1;
    $("day").textContent = `Y${y} · D${d}`;

    const info = E.stageInfo(st);
    $("stageName").textContent = `Stage ${st.stage} of ${G.stages.length} · ${info.stage.icon} ${info.stage.name}`;
    $("stageNext").textContent = info.next
      ? `Next: ${info.next.icon} ${info.next.name} (earn ${money(info.stage.goal)} in total)`
      : `Next: 🧠 Superintelligence (earn ${money(info.stage.goal)} in total)`;
    const pct = Math.floor(info.progress * 100);
    $("stageBar").style.width = info.progress * 100 + "%";
    $("stagePct").textContent = pct + "%";
  }

  /* ---------------- shop ---------------- */
  function renderGens() {
    const vis = E.visibleGenerators(st);
    const locked = G.generators.find((g) => g.stage > st.stage);
    const key = vis.map((g) => g.id).join() + "|" + (locked ? locked.id : "");
    const box = $("gens");
    if (key !== genKey) {
      genKey = key;
      box.innerHTML = vis.map((g) => `
        <button class="item" data-gen="${g.id}">
          <span class="icon">${g.icon}</span>
          <span><span class="name">${g.name}</span><span class="desc"> · ${g.desc}</span>
            <span class="meta" data-meta></span></span>
          <span class="right"><span class="owned" data-owned>0</span><br><span class="cost" data-cost></span></span>
        </button>`).join("") +
        (locked ? `<button class="item" disabled><span class="icon">🔒</span><span><span class="name">${locked.name}</span><span class="desc"> · Unlocks at stage ${locked.stage}: ${G.stages[locked.stage - 1].name}</span></span><span></span></button>` : "");
    }
    for (const el of box.querySelectorAll("[data-gen]")) {
      const id = el.dataset.gen, g = E.genById[id];
      const n = buyAmt === "max" ? Math.max(1, E.maxAffordable(st, id)) : Number(buyAmt);
      const c = n === 1 ? E.genCost(st, id) : E.genCostN(st, id, n);
      el.disabled = st.cash < c;
      el.querySelector("[data-cost]").innerHTML = (n > 1 ? `<span class="qty">×${n} </span>` : "") + money(c);
      el.querySelector("[data-owned]").textContent = st.owned[id];
      el.querySelector("[data-meta]").innerHTML = `<span class="inc">+${money(E.genIncome(st, id))}/s</span> · <span class="pow">⚡ ${E.fmtPower(g.kw)}</span> each`;
    }
  }

  function renderUps() {
    const vis = E.visibleUpgrades(st).sort((a, b) => a.cost - b.cost);
    const key = vis.map((u) => u.id).join();
    const box = $("ups");
    if (key !== upKey) {
      upKey = key;
      box.innerHTML = vis.length
        ? vis.map((u) => `
          <button class="item upgrade" data-up="${u.id}">
            <span class="icon">${u.icon}</span>
            <span><span class="name">${u.name}</span><span class="desc" style="display:block">${u.desc}</span></span>
            <span class="right"><span class="cost">${money(u.cost)}</span></span>
          </button>`).join("")
        : `<div class="empty">No upgrades right now. Buy more hardware to unlock some.</div>`;
    }
    for (const el of box.querySelectorAll("[data-up]")) el.disabled = st.cash < E.upById[el.dataset.up].cost;
  }

  /* ---------------- scene ---------------- */
  function lerp(a, b, t) { return a + (b - a) * t; }
  function mix(c1, c2, t) {
    const p = (c) => [1, 3, 5].map((i) => parseInt(c.slice(i, i + 2), 16));
    const a = p(c1), b = p(c2);
    return "#" + a.map((v, i) => Math.round(lerp(v, b[i], t)).toString(16).padStart(2, "0")).join("");
  }
  function pollution() {
    if (!st.revealed) return Math.min(0.15, (st.stage - 1) * 0.1);
    const s = E.sustainability(st);
    const severity = Math.min(1, 0.35 + (st.stage - 1) / 4);
    return Math.max(0, Math.min(1, (1 - s / 100) * severity));
  }
  const captions = ["The view from your bedroom", "The view from your warehouse", "Your first data centres", "Your hyperscale campuses", "Planet Aether"];
  function renderScene(now) {
    const p = pollution();
    const sky = $("sky"), ground = $("ground");
    sky.style.setProperty("--sky1", mix("#4aa3ff", "#4a3a30", p));
    sky.style.setProperty("--sky2", mix("#bfe6ff", "#d9823f", p));
    ground.style.setProperty("--ground1", mix("#4c9a4c", "#7a6440", p));
    ground.style.setProperty("--ground2", mix("#2f6b35", "#3e3020", p));
    $("smog").style.opacity = (p * 0.85).toFixed(2);
    const sun = $("sun");
    sun.textContent = p > 0.55 ? "🔴" : p > 0.3 ? "🌥️" : "☀️";
    sun.style.opacity = (1 - p * 0.4).toFixed(2);
    const alive = Math.round(7 * (1 - p));
    const treeStr = "🌳".repeat(alive) + "🪵".repeat(7 - alive);
    if ($("trees").textContent !== treeStr) $("trees").textContent = treeStr;
    $("sceneCaption").textContent = captions[st.stage - 1];
    $("scene").classList.toggle("heat", st.day < st.heatUntil);

    // Buildings: biggest first, max 28 icons.
    const icons = ["💻"];
    for (const g of [...G.generators].reverse()) {
      const n = Math.min(st.owned[g.id], 10);
      for (let i = 0; i < n && icons.length < 28; i++) icons.push(g.icon);
    }
    const key = icons.join("");
    if (key !== bKey) {
      bKey = key;
      $("buildings").innerHTML = icons.map((i) => `<span class="b">${i}</span>`).join("");
    }

    // Smoke from fossil power.
    const smoky = (st.revealed ? st.factors.ci : 0.45) > 0.3 && st.stage >= 2;
    if (smoky && now - lastPuff > 1400 - p * 900) {
      lastPuff = now;
      const puff = document.createElement("span");
      puff.className = "puff";
      puff.textContent = "💨";
      puff.style.left = 45 + Math.random() * 50 + "%";
      $("smoke").appendChild(puff);
      setTimeout(() => puff.remove(), 5000);
    }
  }

  /* ---------------- sustainability ---------------- */
  function renderSustain() {
    $("impactLocked").classList.toggle("hidden", st.revealed);
    $("sustainCard").classList.toggle("hidden", !st.revealed);
    if (!st.revealed) return;
    const s = E.sustainability(st);
    const [label, color] = rating(s);
    $("sScore").textContent = s;
    $("sScore").style.color = color;
    const r = $("sRating");
    r.textContent = label;
    r.style.background = color;
    r.style.color = "#0b1016";
    $("sGauge").style.left = `calc(${s}% - 2px)`;
    const end = G.endings[E.endingFor(st)];
    $("endingForecast").innerHTML = `Heading for:<b>${end.icon} ${end.title}</b>`;
    const m = E.sMult(st);
    $("sMultLine").innerHTML = `Income ×<b>${m.toFixed(2)}</b>: ${s < 50 ? "cutting corners pays… for now." : s > 50 ? "doing things right costs money." : "neutral."} <span class="muted">(70+ = good ending, below 40 = bad ending)</span>`;
    $("footprint").innerHTML = footprintCells(st.footprint, "fp");

    const btn = $("offsetBtn");
    if (st.offsets >= 3) {
      btn.disabled = true;
      btn.textContent = "🏷️ Carbon offsets (sold out)";
      $("offsetNote").textContent = "";
    } else {
      const c = E.offsetCost(st);
      btn.disabled = st.cash < c;
      btn.textContent = `🏷️ Buy carbon offsets · ${money(c)}`;
      $("offsetNote").textContent = `+3 sustainability · ${3 - st.offsets} left`;
    }

    const ck = JSON.stringify(st.decisions) + st.offsets;
    if (ck !== choicesKey) {
      choicesKey = ck;
      $("choices").innerHTML = choicesHTML() || `<li class="muted">None yet.</li>`;
    }
  }

  function choicesHTML() {
    let html = "";
    for (const d of G.decisions) {
      const idx = st.decisions[d.id];
      if (idx === undefined) continue;
      const o = d.options[idx];
      html += `<li><span>${d.icon} ${o.label}</span>${sChip(o.s)}</li>`;
    }
    if (st.offsets) html += `<li><span>🏷️ Carbon offsets ×${st.offsets}</span>${sChip(st.offsets * 3)}</li>`;
    return html;
  }

  /* ---------------- news & facts ---------------- */
  function renderFeeds() {
    if (st.news[0] !== lastNewsTop) {
      const idx = lastNewsTop ? st.news.indexOf(lastNewsTop) : st.news.length;
      if (activeTab !== "news") unreadNews += idx < 0 ? st.news.length : idx;
      lastNewsTop = st.news[0];
      $("newsList").innerHTML = st.news.length
        ? st.news.map((n) => `<div class="news-item ${n.kind}"><span class="when">Day ${n.day + 1}</span>${n.text}</div>`).join("")
        : `<div class="empty">No news yet. Nobody has heard of Aether.</div>`;
    }
    const nb = $("newsBadge");
    nb.textContent = unreadNews;
    nb.classList.toggle("hidden", !unreadNews || activeTab === "news");

    if (st.facts.length !== lastFactCount) {
      lastFactCount = st.facts.length;
      $("factCount").textContent = `${st.facts.length}/${TOTAL_FACTS}`;
      const left = TOTAL_FACTS - st.facts.length;
      $("factList").innerHTML = [...st.facts].reverse().map((id) => factHTML(id)).join("") +
        (left ? `<div class="fact locked">🔒 ${left} more real facts to discover as Aether grows</div>` : "");
    }
    if (activeTab === "facts") seenFacts = st.facts.length;
    const fb = $("factBadge"), newF = st.facts.length - seenFacts;
    fb.textContent = newF;
    fb.classList.toggle("hidden", newF <= 0);
  }

  function setTab(tab) {
    activeTab = tab;
    document.querySelectorAll(".tab").forEach((t) => t.classList.toggle("active", t.dataset.tab === tab));
    $("newsList").classList.toggle("hidden", tab !== "news");
    $("factList").classList.toggle("hidden", tab !== "facts");
    if (tab === "news") unreadNews = 0;
    if (tab === "facts") seenFacts = st.facts.length;
  }

  /* ---------------- toasts ---------------- */
  function drainToasts() {
    while (st.toasts.length) {
      const t = st.toasts.shift();
      const el = document.createElement("div");
      let life = 7000;
      if (t.type === "fact") {
        const f = G.facts[t.id];
        el.className = "toast";
        el.innerHTML = `<div class="t-kicker">📊 Real fact unlocked</div><div class="t-title">${f.icon} ${f.title}</div>${f.text}<div class="t-src">Source: ${f.source} · saved in the Real facts tab</div>`;
        life = 16000;
      } else {
        el.className = "toast " + (t.kind || "");
        el.textContent = t.text;
        life = 5000;
      }
      const box = $("toasts");
      box.appendChild(el);
      const maxToasts = window.innerWidth < 760 ? 1 : 3;
      while (box.children.length > maxToasts) box.firstChild.remove();
      const kill = () => { el.classList.add("out"); setTimeout(() => el.remove(), 300); };
      el.addEventListener("click", kill);
      setTimeout(kill, life);
    }
  }

  /* ---------------- modals ---------------- */
  function openModal(item) {
    modalOpen = true;
    const card = $("modalCard");
    card.className = "modal-card";
    let html = "";
    if (item.type === "intro") {
      html = `
        <div class="modal-icon">💻</div>
        <div class="modal-kicker">A game about the real cost of AI</div>
        <h2>AETHER</h2>
        <p>You're alone in an empty room with a laptop and an idea: <b>Aether</b>, an AI that can answer anything.</p>
        <p>Your goal: turn it into the most powerful AI company on Earth.</p>
        <ul class="howto">
          <li>🖱️ <b>Answer prompts</b> to earn your first dollars.</li>
          <li>🎮 <b>Buy hardware</b> so Aether earns money on its own.</li>
          <li>📈 <b>Fill the progress bar</b> to reach the next stage (5 stages in total).</li>
          <li>📰 <b>Read the news</b> and collect <b>real facts</b> along the way.</li>
        </ul>
        <button class="btn" data-close>Start ▶</button>`;
    } else if (item.type === "stage") {
      const s = G.stages[item.stage - 1];
      const unlocked = G.generators.filter((g) => g.stage === item.stage).map((g) => `${g.icon} ${g.name}`).join(", ");
      html = `
        <div class="modal-icon">${s.icon}</div>
        <div class="modal-kicker">Stage ${item.stage} of ${G.stages.length}</div>
        <h2>${s.name}</h2>
        <p>${s.intro}</p>
        ${unlocked ? `<p class="hint">New hardware unlocked: <b>${unlocked}</b></p>` : ""}
        <button class="btn" data-close>Continue</button>`;
    } else if (item.type === "fine") {
      card.classList.add("alert");
      html = `
        <div class="modal-icon">⚖️</div>
        <div class="modal-kicker">Breaking: Aether fined</div>
        <h2>You've been fined for hiding your energy use</h2>
        <div class="big-number">−${money(item.amount)}</div>
        ${st.cash < 0 ? `<p class="hint">You're now <b>${money(st.cash)}</b> in debt. Keep earning to pay it back.</p>` : ""}
        <p>The environment agency has fined Aether for not reporting the electricity its servers use. A new law now requires every AI company to <b>measure and publish its environmental impact</b>.</p>
        ${factHTML("reporting", "factbox")}
        <h2 style="font-size:19px;margin-top:18px">📊 New: your Sustainability score</h2>
        <p>From now on, your choices change your <b>Sustainability</b> score (0–100). Now you need to take it into account:</p>
        <ul class="howto">
          <li>💰 <b>Polluting pays.</b> A low score boosts your income (up to ×1.3), and a high score slows it down (down to ×0.7).</li>
          <li>🎬 <b>Your score decides how the story ends.</b> 70 or more leads to a good ending, and below 40 to a bad one.</li>
          <li>⚖️ Polluters also risk <b>fines</b> and <b>heatwaves</b> that slow down their servers.</li>
        </ul>
        <p>Since day 1, while nobody was counting, Aether has already used:</p>
        <div class="mini-fp">
          <div>⚡ Electricity<b>${E.fmtEnergy(st.footprint.kwh)}</b>${eqEnergy(st.footprint.kwh)}</div>
          <div>🏭 CO₂<b>${E.fmtMass(st.footprint.co2)}</b>${eqCo2(st.footprint.co2)}</div>
        </div>
        ${factHTML("co2Volume", "factbox")}
        <button class="btn" data-close>Got it. Show me my score</button>`;
    } else if (item.type === "decision") {
      const d = E.decById[item.id];
      const text = st.factors.desert && d.textDesert ? d.textDesert : d.text;
      const inc = E.incomePerSec(st);
      html = `
        <div class="modal-icon">${d.icon}</div>
        <div class="modal-kicker">Decision</div>
        <h2>${d.title}</h2>
        <p>${text}</p>
        ${factHTML(d.fact, "factbox")}
        <div class="options">
          ${d.options.map((o, i) => `
            <button class="option" data-opt="${i}">
              <div class="opt-label">${o.label}</div>
              <div class="opt-detail">${o.detail}</div>
              <div class="opt-chips">${sChip(o.s)}
                ${o.costFrac ? `<span class="chip cash">−${money(Math.max(0, st.cash) * o.costFrac)}</span>` : ""}
                ${o.bonusSec ? `<span class="chip cash">+${money(inc * o.bonusSec)}</span>` : ""}
              </div>
            </button>`).join("")}
        </div>
        <div class="hint">🌍 Your sustainability is <b>${E.sustainability(st)}</b>. Lower sustainability means more income now, but a worse ending.</div>`;
    } else if (item.type === "final") {
      const s = E.sustainability(st);
      html = `
        <div class="modal-icon">🧠</div>
        <div class="modal-kicker">Stage 5 complete</div>
        <h2>Superintelligence is ready</h2>
        <p>Aether-∞ has finished training. It is smarter than every human who ever lived, combined.</p>
        <p>Your final sustainability score: <b>${s}/100</b>.</p>
        <p>What kind of world will it wake up in?</p>
        <button class="btn" data-launch>🚀 Launch superintelligence</button>`;
    }
    card.innerHTML = html;
    $("modal").classList.remove("hidden");
    const first = card.querySelector("button");
    if (first) first.focus({ preventScroll: true });
  }

  function closeModal() {
    st.queue.shift();
    modalOpen = false;
    $("modal").classList.add("hidden");
    lastFrame = performance.now();
    save();
  }

  $("modalCard").addEventListener("click", (ev) => {
    const btn = ev.target.closest("button");
    if (!btn) return;
    const item = st.queue[0];
    if (btn.hasAttribute("data-close")) closeModal();
    else if (btn.dataset.opt !== undefined && item && item.type === "decision") {
      const d = E.decById[item.id], o = d.options[Number(btn.dataset.opt)];
      E.decide(st, item.id, Number(btn.dataset.opt));
      st.toasts.push({ type: "msg", kind: o.s > 0 ? "good" : o.s < 0 ? "bad" : "", text: `${d.icon} ${o.label}: sustainability ${o.s >= 0 ? "+" : "−"}${Math.abs(o.s)}. Now ${E.sustainability(st)}/100.` });
      closeModal();
    } else if (btn.hasAttribute("data-launch")) {
      st.queue.shift();
      modalOpen = false;
      $("modal").classList.add("hidden");
      E.finish(st);
      showEnding();
    }
  });

  /* ---------------- ending ---------------- */
  function showEnding() {
    clearSave();
    const key = st.ending || E.endingFor(st);
    const end = G.endings[key];
    const fp = st.footprint;
    const finalKw = E.facilityPowerKW(st);
    const share = ((finalKw * 8760) / 415e9) * 100;
    let delay = 0.4;
    const step = (d) => { const v = delay; delay += d; return `style="animation-delay:${v.toFixed(1)}s"`; };
    const story = end.paragraphs.map((p) => `<p ${step(1.2)}>${p}</p>`).join("");
    const el = $("ending");
    el.className = "ending " + key;
    el.innerHTML = `
      <div class="ending-inner">
        <div class="ending-icon">${end.icon}</div>
        <h1>${end.title}</h1>
        <div class="story">${story}</div>
        <p class="ending-note" ${step(1.2)}>${end.note}</p>

        <section class="ending-section" ${step(0.6)}>
          <h2>Your footprint · sustainability ${E.sustainability(st)}/100 · ${Math.floor(st.day)} days</h2>
          <div class="end-fp">${footprintCells(fp, "fp")}</div>
          <p class="muted">At the end, Aether's data centres drew <b>${E.fmtPower(finalKw)}</b> around the clock. Over a year that adds up to ${E.fmtEnergy(finalKw * 8760)}, or ${share >= 1 ? Math.round(share) : share.toFixed(2)}% of what <b>all the world's data centres</b> used in 2024 (~415 TWh, IEA).</p>
        </section>

        <section class="ending-section" ${step(0.6)}>
          <h2>Your choices</h2>
          <ul class="choices">${choicesHTML() || `<li class="muted">No choices made.</li>`}</ul>
        </section>

        <section class="ending-section" ${step(0.6)}>
          <h2>5 real facts to remember</h2>
          <ul class="takeaways">
            ${G.takeaways.map((t) => `<li><span class="ta-icon">${t.icon}</span><span>${t.text}<span class="ta-src">Source: ${t.source}</span></span></li>`).join("")}
          </ul>
          <p class="muted">You collected ${st.facts.length} of ${TOTAL_FACTS} real facts during the game.</p>
        </section>

        <button class="btn fade" id="againBtn" ${step(0)}>↺ Play again: can you reach a different ending?</button>
        <p class="ending-note skip-hint" style="animation-delay:1.5s">Click anywhere to skip the animation.</p>
      </div>`;
    el.classList.remove("hidden");
    el.scrollTop = 0;
    $("againBtn").addEventListener("click", () => newGame());
    el.onclick = (ev) => { if (ev.target.id !== "againBtn") el.classList.add("skip"); };
  }

  function newGame() {
    clearSave();
    st = E.newState();
    modalOpen = false;
    genKey = upKey = bKey = choicesKey = "";
    lastNewsTop = null; unreadNews = 0; lastFactCount = -1; seenFacts = 0;
    $("modal").classList.add("hidden");
    $("ending").classList.add("hidden");
    $("toasts").innerHTML = "";
    setTab("news");
    lastFrame = performance.now();
  }

  /* ---------------- input ---------------- */
  $("clickBtn").addEventListener("click", (ev) => {
    if (modalOpen || st.ended) return;
    const v = E.click(st);
    const f = document.createElement("span");
    f.className = "floater";
    f.textContent = "+" + money(v);
    const rect = $("clickBtn").getBoundingClientRect();
    const x = ev.clientX || rect.left + rect.width / 2;
    const y = ev.clientY || rect.top + rect.height / 2;
    f.style.left = x - 20 + (Math.random() * 30 - 15) + "px";
    f.style.top = y - 20 + "px";
    document.body.appendChild(f);
    setTimeout(() => f.remove(), 900);
    $("promptText").textContent = `“${E.currentPrompt(st)}”`;
  });
  $("gens").addEventListener("click", (ev) => {
    const b = ev.target.closest("[data-gen]");
    if (!b || modalOpen) return;
    const id = b.dataset.gen;
    const n = buyAmt === "max" ? Math.max(1, E.maxAffordable(st, id)) : Number(buyAmt);
    E.buyGenN(st, id, n);
  });
  document.querySelectorAll("[data-amt]").forEach((b) => b.addEventListener("click", () => {
    buyAmt = b.dataset.amt;
    document.querySelectorAll("[data-amt]").forEach((x) => x.classList.toggle("active", x === b));
  }));
  $("ups").addEventListener("click", (ev) => {
    const b = ev.target.closest("[data-up]");
    if (b && !modalOpen && E.buyUpgrade(st, b.dataset.up)) upKey = "";
  });
  $("offsetBtn").addEventListener("click", () => { if (!modalOpen) E.buyOffset(st); });
  document.querySelectorAll(".tab").forEach((t) => t.addEventListener("click", () => setTab(t.dataset.tab)));
  // Two-click confirmation (browser confirm() dialogs are blocked in some viewers).
  let restartArmed = null;
  $("restartBtn").addEventListener("click", () => {
    const btn = $("restartBtn");
    if (restartArmed) {
      clearTimeout(restartArmed);
      restartArmed = null;
      btn.textContent = "↺ New game";
      newGame();
      return;
    }
    btn.textContent = "Click again to restart (progress will be lost)";
    restartArmed = setTimeout(() => { restartArmed = null; btn.textContent = "↺ New game"; }, 3000);
  });
  window.addEventListener("beforeunload", () => { if (!st.ended) save(); });

  /* ---------------- main loop ---------------- */
  function render(now) {
    renderTop();
    renderGens();
    renderUps();
    renderScene(now);
    renderSustain();
    renderFeeds();
    if (!modalOpen) drainToasts();
    $("clickVal").textContent = "+" + money(E.clickValue(st));
  }

  function frame(now) {
    const dt = Math.min((now - lastFrame) / 1000, 1) * SPEED;
    lastFrame = now;
    if (!modalOpen && !st.ended) {
      E.tick(st, dt);
      if (st.queue.length) openModal(st.queue[0]);
    }
    if (now - lastRender > 100) { lastRender = now; render(now); }
    if (now - lastSave > 5000) { lastSave = now; if (!st.ended) save(); }
    requestAnimationFrame(frame);
  }

  $("promptText").textContent = `“${E.currentPrompt(st)}”`;
  render(performance.now());
  requestAnimationFrame(frame);
})();
