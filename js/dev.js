/* Developer mode for presentations: unlimited money, everything unlocked,
 * jump between places, change speed and sustainability, trigger events.
 * Only active when the page sets window.DEV_MODE = true (see dev.html). */
(function () {
  if (!window.DEV_MODE) return;
  const G = window.GAME, E = window.Engine, App = window.App, $ = App.$;
  const PRESET = {
    1: { gpu: 8, workstation: 3 },
    2: { gpu: 16, workstation: 4, server: 12, cluster: 3 },
    3: { gpu: 16, workstation: 4, server: 12, cluster: 3, datacenter: 4 },
    4: { gpu: 16, workstation: 4, server: 12, cluster: 3, datacenter: 6, campus: 8 },
    5: { gpu: 16, workstation: 4, server: 12, cluster: 3, datacenter: 6, campus: 8, gigafactory: 6 },
  };

  // Developer-mode bar under the progress bar.
  const bar = document.createElement("div");
  bar.className = "devbar";
  bar.innerHTML = `<span class="devtag">DEV</span>
    <button data-dev="prev" title="Previous place">◀</button><button data-dev="next" title="Next place">▶</button><button data-dev="fill">Fill bar</button>
    <span class="devsep"></span><button data-speed="1">×1</button><button data-speed="5">×5</button><button data-speed="20">×20</button>
    <span class="devsep"></span><span class="devlabel">Score</span><button data-score="90">90</button><button data-score="55">55</button><button data-score="30">30</button><button data-score="8">8</button>
    <span class="devsep"></span><button data-dev="press">Quiz</button><button data-dev="fine">Fine</button>`;
  document.querySelector(".stagecard").appendChild(bar);
  document.querySelector(".start-kicker").textContent = "Developer mode · unlimited money";

  function unlockAll(st) {
    for (const id of Object.keys(G.facts)) if (!st.facts.includes(id)) st.facts.push(id);
  }
  function goStage(k) {
    const st = App.st;
    if (!st || App.modalOpen) return;
    k = Math.max(1, Math.min(5, k));
    st.stage = k;
    const prev = k > 1 ? G.stages[k - 2].goal : 0, goal = G.stages[k - 1].goal;
    st.lifetime = prev + (goal - prev) * 0.15;
    for (const g of G.generators) st.owned[g.id] = PRESET[k][g.id] || 0;
    for (const d of G.decisions) if (d.trigger.stage < k) st.triggered["d_" + d.id] = true;
    st.stageDays[k - 1] = Math.floor(st.day);
    st.queue = [];
    st.rank = E.rankFor(st);
    st.passed = G.brands.map((_, i) => i + 1).filter((r) => r >= st.rank);
    E.addNews(st, `DEV: jumped to stage ${k}: ${G.stages[k - 1].name}.`, "milestone");
    App.renderAll(true);
  }
  function setScore(target) {
    const st = App.st;
    if (!st) return;
    st.revealed = true;
    st.triggered.fine = true;
    for (let i = 0; i < 60 && E.sustainability(st) !== target; i++) st.sBonus += Math.max(-10, Math.min(10, target - E.sustainability(st)));
    App.renderAll(true);
  }
  function quiz() {
    const st = App.st;
    if (!st || App.modalOpen) return;
    const ids = Object.keys(G.press), fid = ids[Math.floor(Math.random() * ids.length)];
    st.asked = st.asked.filter((x) => x !== fid);
    st.queue.push({ type: "press", fact: fid, order: [0, 1, 2].sort(() => Math.random() - 0.5) });
  }
  function fine() {
    const st = App.st;
    if (!st) return;
    const amount = Math.round(Math.max(1000, E.incomePerSec(st) * 8));
    st.finesPaid += amount;
    st.finesCount++;
    st.toasts.push({ type: "fine", amount });
    E.addNews(st, `{name} fined $${E.fmtNum(amount)} for pollution. CEO: 'A small price for progress.'`, "bad");
  }

  bar.addEventListener("click", (ev) => {
    const b = ev.target.closest("button");
    if (!b || !App.st) return;
    const st = App.st;
    if (b.dataset.speed) {
      App.speed = Number(b.dataset.speed);
      bar.querySelectorAll("[data-speed]").forEach((x) => x.classList.toggle("on", x === b));
    } else if (b.dataset.score) setScore(Number(b.dataset.score));
    else if (b.dataset.dev === "prev") goStage(st.stage - 1);
    else if (b.dataset.dev === "next") goStage(st.stage + 1);
    else if (b.dataset.dev === "fill") st.lifetime = Math.max(st.lifetime, E.stageInfo(st).stage.goal);
    else if (b.dataset.dev === "press") quiz();
    else if (b.dataset.dev === "fine") fine();
  });
  bar.querySelector('[data-speed="1"]').classList.add("on");

  // Unlimited money, all facts unlocked, nothing saved between sessions.
  const devBadges = [];
  App.collection = () => devBadges;
  App.collect = (id) => { if (!devBadges.includes(id)) devBadges.push(id); return devBadges; };
  App.save = () => {};
  App.loadSave = () => null;
  const start = App.start;
  App.start = (st) => { unlockAll(st); start(st); };
  setInterval(() => { if (App.st && !App.st.ended) App.st.cash = 1e21; }, 50);
})();
