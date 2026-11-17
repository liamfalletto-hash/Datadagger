# Launch Your AI

*The cloud is not in the sky.*

An educational idle game about the real environmental cost of AI. You name your own AI start-up and grow it from a garage to a planet-sized superintelligence, climbing a (fictional) world ranking past ChatGPT, Gemini, Claude and the rest. Every dollar you earn costs electricity, CO₂, water and e-waste, and the world around you shows it.

## How to play

**Open `index.html` in a web browser** by double-clicking it. Nothing to install; your progress saves automatically.

1. **Name your AI start-up** on the black start screen and watch where it starts in the world ranking.
2. **Tap the speech bubble** to answer prompts. **Buy hardware** in the shop: it appears in your room. Own 10, 25 and 50 of one item to double its income.
3. **Fill the progress bar**, then press the move button. There are 5 places:
   1. The Garage
   2. The Office
   3. The Data Centre
   4. The AI Campus
   5. The Planet
4. **In the office you get fined**, and your **Sustainability score** appears. It starts high (85) because you're small, and drops as you grow. From then on:
   - Below 65 you get **fined** again and again: the lower the score, the more often and the bigger the fines.
   - **AI upgrades** boost income but often cost power and sustainability. **Green upgrades** raise sustainability but cost a share of income. Each green upgrade is unlocked by reading its real fact.
   - Decisions (energy, cooling, hardware, models, drought, the race) move the score.
   - The world around you changes: a little grey at 50, clearly damaged below 40, on fire below 15.
5. **Press conferences** ask about the real facts you've unlocked. Right answers pay.
6. **Goals** give rewards, and **badges** are kept between games.
7. Your final score decides the ending: 70+ is good, below 40 is bad. The end screen shows your footprint and 5 real facts to remember.

**Dashboard:** the button at the top right opens your stats: press-conference questions answered right and wrong, real facts read, sustainability and CO₂ over time, footprint, time in each place, decisions, upgrades and badges.

**Developer mode (for presentations):** open `dev.html` instead of `index.html`. You get unlimited money and every fact unlocked. A DEV bar under the progress bar lets you:
- jump between places (◀ ▶) and fill the progress bar
- change the speed (×1, ×5, ×20)
- set the sustainability score (90, 55, 30, 8)
- trigger a press question or a fine

The dashboard shows sample end-of-game data, with a switch to live data. Nothing is saved in developer mode.

A full game takes about **20 minutes**. For a quick class demo, add `#fast` to the address (`index.html#fast`) to play 5× faster.

## Facts and fiction

The story and the ranking are fiction. Every **Real fact** is sourced (IEA, peer-reviewed papers, Google, the UN Global E-waste Monitor, Ireland's CSO, the Uptime Institute, the IPCC…). Your footprint uses realistic ratios: CO₂ per kWh depends on your energy source, cooling overhead and water use on your cooling choice, e-waste on how long you keep servers.

## Project structure

```
index.html             the page
css/style.css          base sticker-style UI
css/screens.css        start screen, ranking intro, pop-ups, ending
css/layout.css         full-screen world, floating panels, news bar
css/mobile.css         phone layout (slim top bar, pinned scene, stacked panels)
js/data.js             stages, hardware, AI upgrades, green upgrades, decisions
js/content.js          real facts, press questions, news, goals, badges, ranking, endings
js/engine.js           game rules (no display code)
js/art.js              drawing helpers, icons, badges, landscape, people
js/scenes/*.js         the five places
js/ui.js               game screen and loop
js/screens.js          start screen, intro animation, pop-ups, ending
js/dashboard.js        stats dashboard (quiz, facts, charts)
js/dev.js              developer mode (only active in dev.html)
dev.html               the game in developer mode
tools/sim.js           bot that plays the whole game to check balance
tools/tune.js          finds stage goals for a target play time
```

**To change text, facts, prices or decisions, edit `js/data.js` or `js/content.js`.** To check balance after a change (needs Node.js):

```bash
node tools/sim.js
```
