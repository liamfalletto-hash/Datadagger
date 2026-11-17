// Finds stage goals so that a "middle" bot (max ~3 purchases/s) spends TARGET minutes in each stage.
const G = (() => { require("./sim.js"); return globalThis.GAME; })();
const { run } = require("./sim.js");
const TARGET = [0.9, 1.5, 1.7, 1.9, 2.0];
function dur(strategy, i) {
  let sum = 0; const N = 3;
  for (let k = 0; k < N; k++) sum += Number(run(strategy, 3, "optimal").stages.split(" | ")[i]);
  return sum / N;
}
for (let i = 0; i < 5; i++) {
  const prev = i ? G.stages[i - 1].goal : 1;
  let lo = Math.log10(prev * 1.5), hi = Math.log10(prev) + 6;
  for (let it = 0; it < 18; it++) {
    const mid = (lo + hi) / 2;
    G.stages[i].goal = Math.pow(10, mid);
    if (dur("middle", i) < TARGET[i]) lo = mid; else hi = mid;
  }
  const g = Number(Math.pow(10, (lo + hi) / 2).toPrecision(2));
  G.stages[i].goal = g;
  console.log(`stage ${i + 1}: goal ${g.toExponential(1)}`);
}
console.log(JSON.stringify(G.stages.map((s) => s.goal)));
for (const m of ["optimal"]) for (const s of ["dirty", "middle", "green"]) { const r = run(s, 3, m); console.log(m, s, r.total, r.stages, "S=" + r.S, r.ending); }
