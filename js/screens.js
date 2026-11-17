/* Start screen, ranking intro, pop-ups and the ending. */
(function () {
  const G = window.GAME, E = window.Engine, A = window.AetherArt, App = window.App;
  const $ = App.$, money = App.money, fmt = App.fmt;
  const reduce = window.matchMedia && matchMedia("(prefers-reduced-motion: reduce)").matches;
  const fill = (t) => E.fill(App.st, t);
  const head = (icon, kicker, title, bg) => `<div class="m-head"><span class="m-ico" style="background:${bg || "var(--gold-soft)"}">${A.icon(icon)}</span><div><span class="eyebrow">${kicker}</span><h2>${title}</h2></div></div>`;
  const factBox = (id) => { const f = G.facts[id]; return f ? `<div class="factbox"><b>Real fact: ${f.title}</b>${f.text}<small>Source: ${f.source}</small></div>` : ""; };
  const sChip = (s) => (s ? `<span class="chip-s ${s > 0 ? "pos" : "neg"}">${s > 0 ? "+" : ""}${s} sustainability</span>` : `<span class="chip-s">±0 sustainability</span>`);

  /* ---------- start screen ---------- */
  const IDEAS = ["Nimbus", "Cortexa", "Lumen", "Polaris", "Kite", "Brainwave", "Orbit", "Sparrow", "Quanta", "Echo"];
  function boot() {
    const picks = IDEAS.slice().sort(() => Math.random() - 0.5).slice(0, 3);
    $("suggest").innerHTML = picks.map((n) => `<button type="button" data-n="${n}">${n}</button>`).join("");
    $("suggest").addEventListener("click", (e) => { const b = e.target.closest("button"); if (b) $("nameInput").value = b.dataset.n; $("nameInput").focus(); });
    const saved = App.loadSave();
    if (saved) {
      const c = $("continueBtn");
      c.hidden = false;
      c.textContent = `Continue ${saved.name} (stage ${saved.stage}: ${G.stages[saved.stage - 1].name}) →`;
      c.addEventListener("click", () => { $("start").remove(); App.start(saved); });
    }
    $("startForm").addEventListener("submit", (e) => {
      e.preventDefault();
      App.clearSave();
      const st = E.newState($("nameInput").value || picks[0]);
      $("start").remove();
      intro(st);
    });
    setTimeout(() => $("nameInput").focus(), 50);
  }

  /* ---------- ranking intro: hundreds of AIs, then you at the bottom ---------- */
  function intro(st) {
    if (reduce) { App.start(st); return; }
    const box = $("intro"), list = $("introList");
    box.classList.remove("hidden");
    let rows = G.brands.map((b, i) => `<div class="intro-row top"><span class="r">#${i + 1}</span><span class="n">${b.name}<small>${b.by}</small></span><span class="u"></span></div>`).join("");
    for (let r = 11; r <= 999; r++) rows += `<div class="intro-row"><span class="r">#${r}</span><span class="n">${G.rivalName(r)}</span><span class="u"></span></div>`;
    rows += `<div class="intro-row you" id="introYou"><span class="r">#999+</span><span class="n">${A.esc(st.name)}<small>that's you</small></span><span class="u">1 user</span></div>`;
    list.innerHTML = rows;
    const win = box.querySelector(".intro-window");
    requestAnimationFrame(() => requestAnimationFrame(() => { list.style.transform = `translateY(${-(list.scrollHeight - win.clientHeight)}px)`; }));
    const cap = $("introCaption"), timers = [], later = (fn, ms) => timers.push(setTimeout(fn, ms));
    later(() => { cap.textContent = "These are the world's AIs."; }, 400);
    later(() => { $("introYou").classList.add("show"); cap.textContent = `${st.name} starts at the very bottom.`; }, 5000);
    later(() => { cap.textContent = "Time to climb."; }, 6800);
    let done = false;
    const finish = () => {
      if (done) return;
      done = true;
      timers.forEach(clearTimeout);
      $("introFrame").classList.add("shrink");
      box.classList.add("fade");
      App.start(st);
      const stage = $("world"), z = App.toScreen(App.zoom || [480, 345]);
      stage.style.transformOrigin = `${z[0]}px ${z[1]}px`;
      stage.style.transform = "scale(2.6)";
      stage.getBoundingClientRect();
      stage.classList.add("stage-zoom");
      stage.style.transform = "scale(1)";
      App.modalOpen = true;
      setTimeout(() => { box.remove(); stage.classList.remove("stage-zoom"); stage.style.transform = ""; App.modalOpen = false; welcome(); }, 1700);
    };
    later(finish, 8200);
    box.addEventListener("click", finish);
  }
  function welcome() {
    App.modalOpen = true;
    $("modalCard").className = "modal-card card";
    $("modalCard").innerHTML = head("garage", "Stage 1 of 5", "The Garage") +
      `<ul class="howto"><li><b>Tap the speech bubble</b> to earn money.</li><li><b>Buy hardware</b> on the right.</li><li><b>Fill the bar</b> at the top to move on.</li></ul><button class="buy" data-close-simple>Let's go</button>`;
    $("modal").classList.remove("hidden");
  }

  /* ---------- pop-ups ---------- */
  function openModal(item) {
    const st = App.st, card = $("modalCard");
    App.modalOpen = true;
    card.className = "modal-card card";
    let h = "";
    if (item.type === "stage") {
      const s = G.stages[item.stage - 1], gens = G.generators.filter((g) => g.stage === item.stage).map((g) => g.name).join(", ");
      h = head(s.icon, `Stage ${item.stage} of ${G.stages.length}`, s.name) + `<p>${fill(s.intro)}</p>${gens ? `<p class="hint">New hardware: <b>${gens}</b></p>` : ""}<button class="buy" data-close>Let's go</button>`;
    } else if (item.type === "fine") {
      card.classList.add("alert");
      const fp = st.footprint;
      h = head("note", "Breaking news", `${A.esc(st.name)} has been fined`, "#fde3dc") + `<div class="big-fine">−${money(item.amount > 1e15 ? Math.max(1000, E.incomePerSec(st) * 60) : item.amount)}</div>` +
        `<p>You didn't report your energy use. From now on, AI companies must <b>measure their impact</b>.</p>` +
        `<h3 style="margin:12px 0 4px;font-family:var(--display)">New: your Sustainability score (${E.sustainability(st)})</h3><ul class="howto"><li>Growing and dirty choices <b>lower it</b>. Green upgrades <b>raise it</b>.</li><li>Below 65 you get <b>fined</b>, more often the lower it goes.</li><li>It decides the <b>ending</b>: 70+ good, below 40 bad.</li></ul>` +
        `<div class="mini-grid"><div>CO₂ so far<b>${E.fmtMass(fp.co2)}</b>${App.eq.co2(fp.co2)}</div><div>Electricity so far<b>${E.fmtEnergy(fp.kwh)}</b>${App.eq.energy(fp.kwh)}</div></div><button class="buy" data-close>Got it</button>`;
    } else if (item.type === "decision") {
      const d = E.decById[item.id], inc = E.incomePerSec(st);
      h = head(d.icon, "Decision", d.title) + `<p>${fill(st.factors.biome === "desert" && d.textDesert ? d.textDesert : d.text)}</p>${factBox(d.fact)}<div class="opts">` +
        d.options.map((o, i) => `<button class="opt" data-opt="${i}"><b>${o.label}</b><span>${o.detail}</span><div class="chips-row">${sChip(o.s)}${o.costFrac ? `<span class="chip-s neg">−${money(Math.max(0, st.cash) * o.costFrac)}</span>` : ""}${o.bonusSec ? `<span class="chip-s gold">+${money(inc * o.bonusSec)}</span>` : ""}</div></button>`).join("") +
        `</div><p class="hint">Your sustainability: <b>${E.sustainability(st)}</b></p>`;
    } else if (item.type === "press") {
      const q = G.press[item.fact], read = st.read.includes(item.fact);
      h = head("mic", "Press conference", "A journalist has a question", "var(--blue-soft)") + `<p style="font-family:var(--display);font-size:19px">“${q.q}”</p>` +
        `<div class="opts">${(item.order || [0, 1, 2]).map((i) => `<button class="opt" data-ans="${i}"><b>${q.options[i]}</b></button>`).join("")}</div><p class="hint">Right answer: <b>${money(Math.max(100, E.incomePerSec(st) * 40))}</b>${read ? "" : ". Tip: read your real facts!"}</p><div id="pressResult"></div>`;
    } else if (item.type === "final") {
      h = head("brain", "Stage 5 complete", "Superintelligence is ready") + `<p>${A.esc(st.name)}'s last model has finished training. It is smarter than every human who ever lived, combined.</p><p>Your sustainability: <b>${E.sustainability(st)} / 100</b>. What kind of world will it wake up in?</p><button class="buy gold" data-launch>Launch superintelligence</button>`;
    }
    card.innerHTML = h;
    $("modal").classList.remove("hidden");
  }
  function closeModal(fromQueue = true) {
    if (fromQueue) App.st.queue.shift();
    App.modalOpen = false;
    $("modal").classList.add("hidden");
    App.save();
    App.renderAll(true);
  }
  $("modalCard").addEventListener("click", (ev) => {
    const b = ev.target.closest("button"), st = App.st;
    if (!b) return;
    const item = st && st.queue[0];
    if (b.hasAttribute("data-close-simple")) closeModal(false);
    else if (b.hasAttribute("data-close")) closeModal();
    else if (b.dataset.opt !== undefined && item && item.type === "decision") { E.decide(st, item.id, Number(b.dataset.opt)); closeModal(); }
    else if (b.dataset.ans !== undefined && item && item.type === "press") {
      const r = E.answerPress(st, item.fact, Number(b.dataset.ans));
      if (!r) return closeModal();
      b.closest(".opts").querySelectorAll("button").forEach((x) => { x.disabled = true; if (Number(x.dataset.ans) === r.answer) x.style.background = "var(--go)"; else if (x === b) x.style.background = "var(--coral)"; });
      const f = G.facts[item.fact];
      $("pressResult").innerHTML = `<div class="factbox" style="background:${r.ok ? "var(--mint-soft)" : "#fde3dc"}"><b>${r.ok ? `Correct! +${money(r.reward)}` : "Not quite. No reward this time."}</b>${f.text}<small>Source: ${f.source}</small></div><button class="buy" data-close>Continue</button>`;
    } else if (b.hasAttribute("data-launch")) { st.queue.shift(); App.modalOpen = false; $("modal").classList.add("hidden"); E.finish(st); ending(); }
  });

  /* ---------- ending ---------- */
  function ending() {
    const st = App.st, key = st.ending, end = G.endings[key], fp = st.footprint;
    App.clearSave();
    const coll = App.collect({ good: "longgame", mid: "usual", bad: "hellobad" }[key]);
    if (["longgame", "usual", "hellobad"].every((b) => coll.includes(b))) { E.earnBadge(st, "allends"); App.collect("allends"); }
    let delay = 0.3;
    const d = (x) => { const v = delay; delay += x; return `style="animation-delay:${v.toFixed(1)}s"`; };
    const story = end.paragraphs.map((p) => `<p ${d(1.1)}>${fill(p)}</p>`).join("");
    const kw = E.facilityPowerKW(st), share = ((kw * 8760) / 415e9) * 100;
    const choices = G.decisions.filter((x) => st.decisions[x.id] !== undefined).map((x) => { const o = x.options[st.decisions[x.id]]; return `<div class="fp-row">${A.icon(x.icon)}<div><b>${o.label}</b><div class="chips-row">${sChip(o.s)}</div></div></div>`; }).join("");
    const greens = st.green.map((id) => E.greenById[id].name).join(", ") || "none";
    const el = $("ending");
    el.className = "ending " + key;
    el.innerHTML = `<div class="ending-inner">
      <div class="card ending-hero"><span class="m-ico">${A.icon(end.icon)}</span><h1>${end.title}</h1></div>
      <div class="card story">${story}<p ${d(0.6)} class="hint">${end.note}</p></div>
      <div class="card fade-late" ${d(0.4)}><h2>${A.esc(st.name)} finished #${st.rank} in the world ranking</h2><div class="end-grid">${App.footprintRows(fp, true)}</div>
        <p class="hint">At the end you drew ${E.fmtPower(kw)} around the clock. Over a year that's ${E.fmtEnergy(kw * 8760)}, or ${share >= 1 ? Math.round(share) : share.toFixed(2)}% of what all the world's data centres used in 2024 (about 415 TWh, IEA).</p></div>
      <div class="card fade-late" ${d(0.4)}><h2>Your choices · sustainability ${E.sustainability(st)}/100</h2><div class="fp-list">${choices || "<p>No decisions made.</p>"}</div><p class="hint">Green upgrades: ${greens}. Fines paid: ${money(st.finesPaid)} (${st.finesCount}). Press conferences: ${st.pressRight} right out of ${st.pressRight + st.pressWrong}.</p></div>
      <div class="card fade-late" ${d(0.4)}><h2>5 real facts to remember</h2><ul class="takeaways">${G.takeaways.map((t) => `<li>${A.icon(t.icon)}<span>${t.text}<small>Source: ${t.source}</small></span></li>`).join("")}</ul></div>
      <div class="card fade-late" ${d(0.4)}><h2>Badges this game (${st.badges.length})</h2><div class="end-badges">${st.badges.map((b) => A.medal(G.badges.find((x) => x.id === b), true)).join("")}</div></div>
      <button class="buy gold fade-late" ${d(0)} id="againBtn">Play again: can you reach a different ending?</button>
    </div>`;
    el.classList.remove("hidden");
    el.scrollTop = 0;
    el.onclick = (e) => { if (e.target.id === "againBtn") location.reload(); else el.classList.add("skip"); };
  }

  window.Screens = { openModal };
  boot();
})();
