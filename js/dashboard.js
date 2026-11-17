/* Player dashboard: quiz answers, facts read, and every other stat of the run.
 * Opens over the game (which pauses). In developer mode it can show sample
 * end-of-game data. */
(function () {
  const G = window.GAME, E = window.Engine, A = window.AetherArt, App = window.App;
  const $ = App.$, money = App.money, fmt = App.fmt;
  const INK = "#2b2433", LINE = "#5b8ef0";
  let view = window.DEV_MODE ? "sample" : "live";
  const charts = {};

  /* ---------- data ---------- */
  function statsFrom(st) {
    const press = st.pressLog.map((l) => { const q = G.press[l.fact]; return { q: q.q, picked: q.options[l.picked], right: q.options[l.answer], ok: l.ok }; });
    const facts = Object.keys(G.facts).map((id) => ({ title: G.facts[id].title, status: st.read.includes(id) ? "read" : st.facts.includes(id) ? "unread" : "locked" }));
    const ends = st.stageDays.slice(1).concat([Math.floor(st.day)]);
    const decisions = G.decisions.filter((d) => st.decisions[d.id] !== undefined).map((d) => { const o = d.options[st.decisions[d.id]]; return { title: d.title, label: o.label, s: o.s || 0 }; });
    return {
      name: st.name, rank: st.rank, stage: st.stage, day: Math.floor(st.day), revealed: st.revealed, s: E.sustainability(st),
      ending: st.revealed ? G.endings[E.endingFor(st)].title : null, lifetime: st.lifetime, finesPaid: st.finesPaid, finesCount: st.finesCount, clicks: st.clicks,
      press, facts, sHist: st.history.filter((h) => h.s !== null).map((h) => [h.d, h.s]), co2Hist: st.history.map((h) => [h.d, h.co2]),
      stageDays: st.stageDays.map((d, i) => Math.max(0, ends[i] - d)), footprint: st.footprint, decisions,
      ai: Object.keys(st.upgrades).length, green: st.green.length, badges: st.badges.slice(),
    };
  }

  // A plausible finished game, for demos.
  function sample(name) {
    const asked = ["gpu", "prompt", "dataCentres", "carbonIntensity", "training", "pue", "water", "ewaste", "rebound", "images"];
    const wrong = new Set(["pue", "training", "images"]);
    const press = asked.map((id) => { const q = G.press[id], ok = !wrong.has(id); return { q: q.q, picked: q.options[ok ? q.answer : (q.answer + 1) % 3], right: q.options[q.answer], ok }; });
    const unread = new Set(["nuclear", "usGrid", "offsets"]);
    const facts = Object.keys(G.facts).map((id) => ({ title: G.facts[id].title, status: unread.has(id) ? "unread" : "read" }));
    const sPath = [[160, 75], [250, 52], [330, 55], [420, 63], [520, 69], [610, 66], [700, 57], [800, 61], [900, 66], [1000, 64], [1150, 63]];
    const sAt = (d) => { for (let i = 0; i < sPath.length - 1; i++) { const [a, sa] = sPath[i], [b, sb] = sPath[i + 1]; if (d <= b) return sa + ((sb - sa) * (d - a)) / (b - a); } return 63; };
    const sHist = [], co2Hist = [];
    for (let d = 0; d <= 1150; d += 10) {
      if (d >= 160) sHist.push([d, Math.round(sAt(d) + Math.sin(d / 23) * 1.5)]);
      co2Hist.push([d, Math.round((1.2e11 * (Math.exp(d / 95) - 1)) / (Math.exp(1150 / 95) - 1))]);
    }
    const pick = { energy: 1, investors: 0, cooling: 2, hardware: 1, model: 1, drought: 1, race: 0 };
    const decisions = G.decisions.map((d) => { const o = d.options[pick[d.id]]; return { title: d.title, label: o.label, s: o.s || 0 }; });
    return {
      name: name || "Nimbus", rank: 1, stage: 5, day: 1150, revealed: true, s: 63, ending: G.endings.mid.title, lifetime: 6.9e13,
      finesPaid: 3.4e12, finesCount: 14, clicks: 1240, press, facts, sHist, co2Hist, stageDays: [150, 230, 270, 260, 240],
      footprint: { kwh: 4.3e11, co2: 1.2e11, water: 2.1e11, ewaste: 1.6e8 }, decisions, ai: 15, green: 6,
      badges: ["hello", "plugged", "garageband", "movingout", "caught", "coolhead", "rightsized", "greenthumb", "factchecker", "presspro", "top10", "numberone"],
    };
  }

  /* ---------- charts ---------- */
  // Single-series line/area chart with optional status zones and a hover crosshair.
  function lineChart(id, pts, o) {
    if (pts.length < 2) return `<p class="hint">Not enough data yet. Keep playing!</p>`;
    const W = 520, H = 200, L = 64, R = 14, T = 10, B = 24;
    const x0 = pts[0][0], x1 = pts[pts.length - 1][0], yMin = o.yMin, yMax = o.yMax;
    const X = (x) => L + ((x - x0) / (x1 - x0 || 1)) * (W - L - R), Y = (y) => T + (1 - (y - yMin) / (yMax - yMin || 1)) * (H - T - B);
    let s = "";
    for (const [from, to, col, label] of o.zones || []) {
      s += `<rect x="${L}" y="${Y(to).toFixed(1)}" width="${W - L - R}" height="${(Y(from) - Y(to)).toFixed(1)}" fill="${col}" opacity=".16"/><text x="${W - R - 6}" y="${(Y(to) + 13).toFixed(1)}" text-anchor="end" class="ch-zone">${label}</text>`;
    }
    for (const t of o.ticks) s += `<line x1="${L}" x2="${W - R}" y1="${Y(t).toFixed(1)}" y2="${Y(t).toFixed(1)}" stroke="${INK}" stroke-opacity=".1"/><text x="${L - 6}" y="${(Y(t) + 4).toFixed(1)}" text-anchor="end" class="ch-tick">${o.fmtY(t)}</text>`;
    s += `<text x="${L}" y="${H - 6}" class="ch-tick">Day ${x0}</text><text x="${W - R}" y="${H - 6}" text-anchor="end" class="ch-tick">Day ${x1}</text>`;
    const d = pts.map((p, i) => `${i ? "L" : "M"}${X(p[0]).toFixed(1)} ${Y(p[1]).toFixed(1)}`).join("");
    if (o.area) s += `<path d="${d}L${X(x1).toFixed(1)} ${Y(yMin).toFixed(1)}L${X(x0).toFixed(1)} ${Y(yMin).toFixed(1)}Z" fill="${LINE}" opacity=".15"/>`;
    s += `<path d="${d}" fill="none" stroke="${LINE}" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>`;
    const last = pts[pts.length - 1];
    s += `<circle cx="${X(last[0]).toFixed(1)}" cy="${Y(last[1]).toFixed(1)}" r="4" fill="${LINE}" stroke="#fffaf0" stroke-width="2"/>`;
    s += `<line class="ch-x" x1="0" x2="0" y1="${T}" y2="${H - B}" stroke="${INK}" stroke-opacity=".35" visibility="hidden"/><circle class="ch-dot" r="4.5" fill="${LINE}" stroke="#fffaf0" stroke-width="2" visibility="hidden"/>`;
    charts[id] = { pts, X, Y, W, H, fmtY: o.fmtY };
    return `<div class="chart-wrap" data-chart="${id}"><svg class="chart" viewBox="0 0 ${W} ${H}" role="img" aria-label="${o.label}">${s}</svg><div class="chart-tip" hidden></div></div>`;
  }
  function onHover(ev) {
    const wrap = ev.target.closest(".chart-wrap");
    if (!wrap) return;
    const c = charts[wrap.dataset.chart], svg = wrap.querySelector("svg"), r = svg.getBoundingClientRect(), k = r.width / c.W;
    const vx = (ev.clientX - r.left) / k;
    let best = c.pts[0];
    for (const p of c.pts) if (Math.abs(c.X(p[0]) - vx) < Math.abs(c.X(best[0]) - vx)) best = p;
    const px = c.X(best[0]), py = c.Y(best[1]);
    const xl = svg.querySelector(".ch-x"), dot = svg.querySelector(".ch-dot"), tip = wrap.querySelector(".chart-tip");
    xl.setAttribute("x1", px); xl.setAttribute("x2", px); xl.setAttribute("visibility", "visible");
    dot.setAttribute("cx", px); dot.setAttribute("cy", py); dot.setAttribute("visibility", "visible");
    tip.hidden = false;
    tip.innerHTML = `<b>${c.fmtY(best[1])}</b> day ${best[0]}`;
    tip.style.left = Math.min(r.width - 110, Math.max(0, px * k - 50)) + "px";
    tip.style.top = Math.max(0, py * k - 46) + "px";
  }
  function onLeave(ev) {
    const wrap = ev.target.closest && ev.target.closest(".chart-wrap");
    if (!wrap) return;
    wrap.querySelector(".chart-tip").hidden = true;
    wrap.querySelectorAll(".ch-x, .ch-dot").forEach((e) => e.setAttribute("visibility", "hidden"));
  }
  function barChart(rows) {
    const max = Math.max(1, ...rows.map((r) => r.value));
    return `<div class="bars">` + rows.map((r) => `<div class="bar-row" title="${r.label}: ${r.value} days"><span>${r.label}</span><div class="bar-track"><div class="bar-fill" style="width:${Math.max(r.value ? 3 : 0, (r.value / max) * 100)}%"></div></div><b>${r.value} d</b></div>`).join("") + `</div>`;
  }

  /* ---------- page ---------- */
  function render() {
    const s = view === "sample" ? sample(App.st && App.st.name) : statsFrom(App.st);
    const right = s.press.filter((p) => p.ok).length, total = s.press.length, pct = total ? Math.round((right / total) * 100) : 0;
    const read = s.facts.filter((f) => f.status === "read").length;
    const kpi = (label, value, sub, tone) => `<div class="card kpi ${tone || ""}"><span class="eyebrow">${label}</span><b>${value}</b><small>${sub}</small></div>`;
    const toggle = window.DEV_MODE ? `<div class="amount dash-toggle" role="group" aria-label="Data shown"><button data-view="sample" aria-pressed="${view === "sample"}">Sample end of game</button><button data-view="live" aria-pressed="${view === "live"}">Live</button></div>` : "";
    const quizRows = total ? s.press.map((p) => `<tr><td><span class="res ${p.ok ? "ok" : "no"}">${p.ok ? "✓ Right" : "✗ Wrong"}</span></td><td>${p.q}</td><td>${p.picked}</td><td>${p.right}</td></tr>`).join("") : "";
    const factRows = s.facts.map((f) => `<li class="${f.status}"><span class="fstat">${f.status === "read" ? "✓ Read" : f.status === "unread" ? "Not read" : "Locked"}</span>${f.title}</li>`).join("");
    const names = G.stages.map((g) => g.name);
    $("dash").innerHTML = `<div class="dash-inner">
      <header class="card dash-head"><div><span class="eyebrow">Dashboard${view === "sample" ? " · sample data" : ""}</span><h2>${A.esc(s.name)}</h2></div>${toggle}<button class="buy gold" data-dash-close>Back to the game</button></header>
      <section class="kpis">
        ${kpi("Quiz score", total ? `${right}/${total}` : "–", total ? `${pct}% correct` : "no press conference yet", total && pct >= 70 ? "good" : "")}
        ${kpi("Facts read", `${read}/${s.facts.length}`, "real facts")}
        ${kpi("Sustainability", s.revealed ? s.s : "–", s.ending ? `heading for: ${s.ending}` : "not measured yet", s.revealed ? (s.s >= 70 ? "good" : s.s < 40 ? "bad" : "") : "")}
        ${kpi("World rank", s.rank > 999 ? "#999+" : "#" + s.rank, `stage ${s.stage} of 5 · day ${s.day}`)}
        ${kpi("Money earned", money(s.lifetime), `${fmt(s.clicks)} prompts answered`)}
        ${kpi("Fines paid", money(s.finesPaid), `${s.finesCount} fines`, s.finesCount ? "bad" : "")}
      </section>
      <section class="dash-grid">
        <article class="card dash-card wide"><h3>Environment quiz (press conferences)</h3>
          ${total ? `<div class="split" aria-label="${right} right, ${total - right} wrong"><div class="seg ok" style="flex:${right}">${right} right</div>${total - right ? `<div class="seg no" style="flex:${total - right}">${total - right} wrong</div>` : ""}</div>
          <div class="table-wrap"><table class="qtable"><thead><tr><th>Result</th><th>Question</th><th>Answered</th><th>Correct answer</th></tr></thead><tbody>${quizRows}</tbody></table></div>` : `<p class="hint">No press conference yet. They start halfway through the garage.</p>`}
        </article>
        <article class="card dash-card"><h3>Real facts read</h3><div class="mini big-mini"><span style="width:${(read / s.facts.length) * 100}%"></span><em>${read} / ${s.facts.length}</em></div><ul class="factlist">${factRows}</ul></article>
        <article class="card dash-card"><h3>Sustainability over time</h3>${lineChart("s", s.sHist, { yMin: 0, yMax: 100, ticks: [0, 40, 70, 100], fmtY: (v) => String(Math.round(v)), label: "Sustainability score over time", zones: [[0, 40, "#ef7c64", "bad ending"], [40, 70, "#f6c445", "middle"], [70, 100, "#7cc36b", "good ending"]] })}
          <h3 style="margin-top:14px">CO₂ emitted (total)</h3>${lineChart("c", s.co2Hist, { yMin: 0, yMax: Math.max(1, ...s.co2Hist.map((p) => p[1])) * 1.05, ticks: [0, Math.max(1, ...s.co2Hist.map((p) => p[1]))], fmtY: (v) => (v < 1000 ? Math.round(v) + " kg" : fmt(v / 1000) + " t"), area: true, label: "CO2 emitted over time" })}</article>
        <article class="card dash-card"><h3>Footprint</h3><div class="fp-list">${App.footprintRows(s.footprint, true)}</div></article>
        <article class="card dash-card"><h3>Days in each place</h3>${barChart(s.stageDays.map((v, i) => ({ label: names[i], value: v })))}</article>
        <article class="card dash-card"><h3>Decisions</h3>${s.decisions.length ? `<div class="fp-list">${s.decisions.map((d) => `<div class="dec"><span>${d.title}</span><b>${d.label}</b><span class="chip-s ${d.s > 0 ? "pos" : d.s < 0 ? "neg" : ""}">${d.s > 0 ? "+" : ""}${d.s} sustainability</span></div>`).join("")}</div>` : `<p class="hint">No decisions yet.</p>`}</article>
        <article class="card dash-card"><h3>Upgrades and badges</h3><p class="dash-line">AI upgrades: <b>${s.ai} / ${G.upgrades.length}</b> · Green upgrades: <b>${s.green} / ${G.greenUpgrades.length}</b></p><div class="end-badges">${s.badges.map((b) => A.medal(G.badges.find((x) => x.id === b), true)).join("") || `<p class="hint">No badges yet.</p>`}</div></article>
      </section></div>`;
  }

  function open() {
    if (!App.st || App.modalOpen) return;
    App.modalOpen = true;
    render();
    $("dash").classList.remove("hidden");
    $("dash").scrollTop = 0;
  }
  function close() {
    $("dash").classList.add("hidden");
    App.modalOpen = false;
  }
  $("dash").addEventListener("click", (ev) => {
    const b = ev.target.closest("button");
    if (!b) return;
    if (b.hasAttribute("data-dash-close")) close();
    else if (b.dataset.view) { view = b.dataset.view; render(); }
  });
  $("dash").addEventListener("mousemove", onHover);
  $("dash").addEventListener("mouseleave", onLeave, true);
  document.addEventListener("keydown", (e) => { if (e.key === "Escape" && !$("dash").classList.contains("hidden")) close(); });
  $("dashBtn").addEventListener("click", open);
  window.Dashboard = { open, close, statsFrom, sample };
})();
