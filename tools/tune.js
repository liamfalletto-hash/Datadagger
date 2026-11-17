// Finds stage goals so that a "middle" bot (max ~3 purchases/s) spends TARGET
// minutes in each stage. Real players take roughly 1.25× longer than the bot.
const { run } = require("./sim.js");
const G = globalThis.GAME;
const TARGET = (process.env.TARGET || "2.0,3.2,3.6,3.6,3.6").split(",").map(Number);
function dur(i) {
  let sum = 0;
  for (const seed of [1, 2, 3]) sum += Number(run("middle", 3, seed).stages.split(" | ")[i]);
  return sum / 3;
}
for (let i = 0; i < 5; i++) {
  const prev = i ? G.stages[i - 1].goal : 1;
  let lo = Math.log10(prev * 1.5), hi = Math.log10(prev) + 9;
  for (let it = 0; it < 20; it++) {
    const mid = (lo + hi) / 2;
    G.stages[i].goal = Math.pow(10, mid);
    if (dur(i) < TARGET[i]) lo = mid; else hi = mid;
  }
  G.stages[i].goal = Number(Math.pow(10, (lo + hi) / 2).toPrecision(2));
  console.log(`stage ${i + 1}: goal ${G.stages[i].goal.toExponential(1)}`);
}
console.log(JSON.stringify(G.stages.map((s) => s.goal)));
for (const s of ["dirty", "middle", "green"]) { const r = run(s, 3); console.log(s, r.total, r.stages, "S=" + r.S, r.ending, "green=" + r.green, "press=" + r.press); }
