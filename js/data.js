/* Core game data: stages, hardware, AI upgrades, green upgrades and decisions.
 * Text, facts, news, badges, goals and the ranking live in content.js.
 * "{name}" in any text is replaced by the player's start-up name.
 */
(function (root) {
  const GAME = root.GAME || (root.GAME = {});

  // 1 real second of play = 1 day in the life of the start-up.
  GAME.DAYS_PER_SEC = 1;

  // Real-world reference values used for equivalences (sources in content.js facts).
  GAME.REF = {
    kgCo2PerCarYear: 4600, // US EPA: typical passenger car ≈ 4.6 t CO2 / year
    m3PerTonneCo2: 556, // 1 t CO2 at 25 °C and 1 atm ≈ 556 m³ (ideal gas law)
    olympicPoolL: 2.5e6, // 50 m × 25 m × 2 m
    olympicPoolM3: 2500,
    showerL: 65, // ≈ an 8-minute shower (US EPA WaterSense)
    homeKwhYear: 10500, // average US home ≈ 10,500 kWh / year (US EIA)
    phoneChargeKwh: 0.015, // one smartphone charge ≈ 15 Wh including losses
    smartphoneKg: 0.2,
    truckKg: 40000,
    hardwareKgPerKw: 10, // an 8-GPU AI server ≈ 130 kg for ≈ 10 kW
  };

  /* Stages. Progress to the next stage = total money earned. When the bar is
   * full the player presses the "move" button to go to the next place. */
  GAME.stages = [
    { id: 1, name: "The Garage", icon: "garage", goal: 8e4, move: "Move to the office",
      intro: "It's just you, a laptop and a garage. Answer prompts to earn your first dollars, then buy hardware so {name} earns money on its own." },
    { id: 2, name: "The Office", icon: "office", goal: 1e8, move: "Open a data centre",
      intro: "{name} has real users now. You've rented an office, hired your first coworkers and filled a wall with servers." },
    { id: 3, name: "The Data Centre", icon: "server", goal: 8.5e9, move: "Build an AI campus",
      intro: "Millions of people use {name} every day. Renting servers isn't enough anymore: it's time for your own data centre." },
    { id: 4, name: "The AI Campus", icon: "factory", goal: 1.4e12, move: "Go global",
      intro: "{name} is one of the biggest AI companies on Earth. Your campus uses as much electricity as a whole city." },
    { id: 5, name: "The Planet", icon: "globe", goal: 6.9e13, move: "Launch superintelligence",
      intro: "A rival lab says it is months away from superintelligence. Whoever gets there first wins everything. Your board wants more power. Now." },
  ];

  /* Hardware: bought again and again, cost ×1.15 each time.
   * kw = IT power of ONE unit (before cooling overhead).
   * Owning 10, 25 and 50 of one item doubles its income each time (stars). */
  GAME.generators = [
    { id: "gpu", name: "Gaming GPU", stage: 1, cost: 15, income: 0.6, kw: 0.35, desc: "A second-hand graphics card." },
    { id: "workstation", name: "AI workstation", stage: 1, cost: 130, income: 5, kw: 1.5, desc: "Four GPUs, one very loud fan." },
    { id: "server", name: "AI server", stage: 2, cost: 1400, income: 40, kw: 10, desc: "8 top AI chips in one box." },
    { id: "cluster", name: "GPU cluster", stage: 2, cost: 15000, income: 300, kw: 120, desc: "A whole cabinet of servers." },
    { id: "datacenter", name: "Data centre hall", stage: 3, cost: 2e5, income: 3000, kw: 5000, desc: "5 MW of servers, cables and cooling." },
    { id: "campus", name: "Hyperscale campus", stage: 4, cost: 3e7, income: 2.5e5, kw: 1e5, desc: "100 MW, as much power as 80,000 homes." },
    { id: "gigafactory", name: "AI gigafactory", stage: 5, cost: 1.5e9, income: 1e7, kw: 1e6, desc: "1 GW: a whole power plant for one AI." },
  ];
  GAME.MILESTONES = [10, 25, 50];

  /* AI upgrades: bought once. More income, often more power, and later some
   * cost sustainability (s). effect: click ×, gen ×, all ×, power ×, oneOffKwh. */
  GAME.upgrades = [
    { id: "templates", name: "Prompt templates", icon: "note", stage: 1, cost: 30,
      desc: "Answer prompts faster. Each answer earns ×2.", effect: { click: 2 } },
    { id: "overclock", name: "Overclock the GPUs", icon: "flame", stage: 1, cost: 120, req: { gpu: 3 },
      desc: "Gaming GPUs earn ×2.", effect: { gen: "gpu", mult: 2 } },
    { id: "finetune", name: "Fine-tune an open model", icon: "flask", stage: 1, cost: 700, req: { workstation: 3 },
      desc: "AI workstations earn ×2.", effect: { gen: "workstation", mult: 2 } },
    { id: "app", name: "Launch the {name} app", icon: "phone", stage: 2, cost: 2500,
      desc: "Everyone can use {name} from their phone. All income ×1.5.", effect: { all: 1.5 },
      news: "The {name} app hits #1 on the app store." },
    { id: "batching", name: "Smarter batching", icon: "box", stage: 2, cost: 9000, req: { server: 5 },
      desc: "AI servers earn ×2.", effect: { gen: "server", mult: 2 } },
    { id: "train1", name: "Train your own model", icon: "brain", stage: 2, cost: 12000,
      desc: "Weeks of training on hundreds of GPUs. All income ×1.5. Uses 50 MWh in one go.",
      effect: { all: 1.5, oneOffKwh: 5e4 }, fact: "training", news: "{name} unveils its first home-grown AI model." },
    { id: "interconnect", name: "Faster interconnect", icon: "plug", stage: 2, cost: 6e4, req: { cluster: 5 },
      desc: "GPU clusters earn ×2.", effect: { gen: "cluster", mult: 2 } },
    { id: "images", name: "Launch image generation", icon: "image", stage: 3, cost: 5e5, s: -2,
      desc: "All income ×1.5. Images need far more energy than text: +25% power.",
      effect: { all: 1.5, power: 1.25 }, fact: "images", news: "{name} Images goes viral: 40 million pictures of cats in space on day one." },
    { id: "efficiency", name: "Efficient inference chips", icon: "chip", stage: 3, cost: 1.5e6,
      desc: "−40% energy per prompt! Cheaper prompts bring more users: all income ×1.5.",
      effect: { all: 1.5, power: 1.2 }, fact: "rebound", news: "{name} cuts energy per prompt by 40%. Prompts get cheaper and usage doubles." },
    { id: "train2", name: "Train a 10× bigger model", icon: "brain", stage: 3, cost: 4e6, s: -2,
      desc: "All income ×1.5. Training uses 1,300 MWh, about as much as GPT-3's training run.",
      effect: { all: 1.5, oneOffKwh: 1.3e6 }, news: "{name}'s new model tops every benchmark." },
    { id: "customchips", name: "Custom AI chips", icon: "chip", stage: 3, cost: 6e6, req: { datacenter: 5 },
      desc: "Data centre halls earn ×2.", effect: { gen: "datacenter", mult: 2 } },
    { id: "video", name: "Launch video generation", icon: "film", stage: 4, cost: 4e7, s: -4,
      desc: "All income ×1.5. Video is the most energy-hungry content there is: +50% power.",
      effect: { all: 1.5, power: 1.5 }, news: "{name} Video launches. Top request: 'a hot dog dancing in the rain'." },
    { id: "train3", name: "Train a frontier model", icon: "brain", stage: 4, cost: 2e8, s: -3,
      desc: "All income ×1.5. Training uses 50 GWh, what 5,000 homes use in a year.",
      effect: { all: 1.5, oneOffKwh: 5e7 } },
    { id: "optical", name: "Optical networking", icon: "plug", stage: 4, cost: 2.5e8, req: { campus: 5 },
      desc: "Hyperscale campuses earn ×2.", effect: { gen: "campus", mult: 2 } },
    { id: "agents", name: "AI agents everywhere", icon: "robot", stage: 5, cost: 2e10, s: -4,
      desc: "AIs now talk to other AIs, 24/7. All income ×1.5, +30% power.",
      effect: { all: 1.5, power: 1.3 }, news: "Most of {name}'s 'users' are now other AIs." },
    { id: "train4", name: "Train the last model", icon: "brain", stage: 5, cost: 8e10, s: -4,
      desc: "The last step before superintelligence. All income ×1.5. Training uses 1 TWh.",
      effect: { all: 1.5, oneOffKwh: 1e9 } },
  ];

  /* Green upgrades: bought once, available after the sustainability score
   * appears. They raise sustainability (which lowers income) and cut the real
   * footprint. Each needs its real fact to be read first. Cost = costFrac ×
   * the size of that stage (its goal minus the previous goal). */
  GAME.greenUpgrades = [
    { id: "leds", name: "Switch off what nobody uses", icon: "bulb", stage: 2, costFrac: 0.02, s: 3, fact: "prompt",
      desc: "Smart power strips and LED lights. Small, but it adds up.", set: { powerMult: 0.97 } },
    { id: "refurb", name: "Buy refurbished servers", icon: "recycle", stage: 2, costFrac: 0.05, s: 5, fact: "manufacturing",
      desc: "Second-hand servers skip the most polluting step: manufacturing.", set: { lifespanMult: 1.3 } },
    { id: "solarRoof", name: "Solar panels on the roof", icon: "sun", stage: 2, costFrac: 0.08, s: 4, fact: "carbonIntensity",
      desc: "Some of your electricity now comes from the sun.", set: { ciMult: 0.9 } },
    { id: "waterLoop", name: "Closed-loop water cooling", icon: "drop", stage: 3, costFrac: 0.03, s: 5, fact: "water",
      desc: "Reuse the same water instead of evaporating it.", set: { wueMult: 0.5 } },
    { id: "heatReuse", name: "Heat nearby homes", icon: "house", stage: 3, costFrac: 0.05, s: 6, fact: "pue",
      desc: "Pipe your servers' waste heat to the town's heating network.", set: { pueAdd: -0.05 } },
    { id: "carbonAware", name: "Carbon-aware scheduling", icon: "clock", stage: 3, costFrac: 0.07, s: 5, fact: "dataCentres",
      desc: "Run the heavy jobs when the grid is full of wind and sun.", set: { ciMult: 0.85 } },
    { id: "transparency", name: "Publish your real energy use", icon: "note", stage: 4, costFrac: 0.02, s: 4, fact: "reporting",
      desc: "No greenwashing: report energy, water and emissions every year." },
    { id: "repair", name: "Repair and resell old servers", icon: "recycle", stage: 4, costFrac: 0.04, s: 6, fact: "ewaste",
      desc: "Old machines get a second life instead of becoming e-waste.", set: { lifespanMult: 1.4 } },
    { id: "limitVideo", name: "Make video generation opt-in", icon: "film", stage: 4, costFrac: 0.06, s: 7, fact: "images",
      desc: "Users must ask for video on purpose. Far less energy wasted.", set: { powerMult: 0.85 } },
    { id: "energyPrice", name: "Price prompts by their energy", icon: "bolt", stage: 5, costFrac: 0.02, s: 7, fact: "rebound",
      desc: "Heavy prompts cost more, so efficiency stops fuelling the rebound effect.", set: { powerMult: 0.85 } },
    { id: "computeCap", name: "Sign a global compute cap", icon: "globe", stage: 5, costFrac: 0.04, s: 8, fact: "usGrid",
      desc: "You and the other labs agree to limit how much power AI can use." },
  ];

  /* Decisions: appear at fixed moments (stage + progress inside it).
   * option: s (sustainability), bonusSec (cash = N seconds of income),
   * costFrac (share of current cash), set (footprint factors), news. */
  GAME.decisions = [
    {
      id: "energy", icon: "bolt", title: "Where does your power come from?",
      trigger: { stage: 2, progress: 0.1 }, fact: "carbonIntensity",
      text: "{name} is filling a real server room. You need an electricity contract.",
      options: [
        { label: "Cheapest power: coal & gas", detail: "About 750 g of CO₂ per kWh. Saves you money now.",
          s: -20, bonusSec: 45, set: { ci: 0.75 }, news: "{name} signs a cheap power deal with a coal-and-gas supplier." },
        { label: "Standard grid mix", detail: "About 450 g of CO₂ per kWh, close to the world average.", s: 0, set: { ci: 0.45 } },
        { label: "Renewable contract (wind & solar)", detail: "About 10–50 g of CO₂ per kWh. Costs 40% of your cash.",
          s: 20, costFrac: 0.4, set: { ci: 0.03 }, news: "{name} signs a wind and solar power contract." },
      ],
    },
    {
      id: "investors", icon: "cash", title: "The investors are calling",
      trigger: { stage: 2, progress: 0.5 }, fact: "bigTech",
      text: "A big venture fund wants to triple your budget, as long as you promise hyper-growth.",
      options: [
        { label: "Growth at all costs", detail: "Big cash injection. Sustainability is 'a problem for later'.",
          s: -10, bonusSec: 90, news: "{name} raises a mega-round: 'Growth first, everything else later.'" },
        { label: "Take the money, with climate targets in the contract", detail: "A smaller cash injection, but binding emission targets.",
          s: 5, bonusSec: 30, news: "{name}'s funding round includes binding climate targets." },
      ],
    },
    {
      id: "cooling", icon: "drop", title: "Cooling your data centre",
      trigger: { stage: 3, progress: 0 }, fact: "pue",
      text: "Servers turn almost all their electricity into heat. Your data centre needs a place and a way to stay cool.",
      options: [
        { label: "Desert site + water (evaporative) cooling", detail: "Cheap land and tax breaks. Evaporates millions of litres of water in a dry region.",
          s: -15, bonusSec: 60, set: { pue: 1.2, wue: 1.8, biome: "desert" }, news: "{name} builds its data centre in the desert. Tax breaks included." },
        { label: "Air conditioning (chillers)", detail: "Uses little water, but needs much more electricity.",
          s: -5, set: { pue: 1.6, wue: 0.2, biome: "grass" } },
        { label: "Nordic site: cold-air cooling + heat reuse", detail: "Cold outside air does the cooling, and waste heat warms nearby homes. Costs 35% of your cash.",
          s: 15, costFrac: 0.35, set: { pue: 1.1, wue: 0.1, biome: "snow" }, news: "{name}'s Nordic data centre will heat 5,000 local homes with its waste heat." },
      ],
    },
    {
      id: "hardware", icon: "chip", title: "A new chip generation is out",
      trigger: { stage: 3, progress: 0.5 }, fact: "ewaste",
      text: "The new chips are twice as fast. Your current servers are only two years old.",
      options: [
        { label: "Replace everything, every year", detail: "Always the fastest. Old servers go to the dump.",
          s: -10, bonusSec: 60, set: { lifespan: 365 }, news: "{name} replaces 100,000 servers that were only two years old." },
        { label: "Upgrade on the usual 3-year cycle", detail: "The industry standard.", s: 0, set: { lifespan: 1095 } },
        { label: "Keep servers 6 years, refurbish and resell the old ones", detail: "Less e-waste and less mining. Costs 20% of your cash.",
          s: 10, costFrac: 0.2, set: { lifespan: 2190 }, news: "{name} will keep its servers twice as long and resell the old ones." },
      ],
    },
    {
      id: "model", icon: "brain", title: "Model strategy",
      trigger: { stage: 4, progress: 0 }, fact: "rightSize",
      text: "Your huge new model is ready. How do you answer billions of requests?",
      options: [
        { label: "Use the biggest model for everything (even 'hi')", detail: "Best quality everywhere. +30% energy.",
          s: -10, bonusSec: 60, set: { powerMult: 1.3 } },
        { label: "Send each request to the smallest model that can handle it", detail: "Small tasks get small models. −30% energy. Costs 20% of your cash.",
          s: 10, costFrac: 0.2, set: { powerMult: 0.7 }, news: "{name} now answers 'hi' with a tiny model. Energy use drops 30%." },
      ],
    },
    {
      id: "drought", icon: "sun", title: "Drought",
      trigger: { stage: 4, progress: 0.5 }, fact: "water",
      text: "A severe drought hits the region around your campus. Your cooling uses as much water as a town of 50,000 people. The mayor asks you to cut back.",
      textDesert: "A severe drought hits the desert around your data centres. Your cooling towers evaporate as much water as a town of 100,000 people. Wells are running dry, and the mayor begs you to cut back.",
      options: [
        { label: "Keep everything running and pay the fines", detail: "Costs 15% of your cash. The town rations water.",
          s: -10, costFrac: 0.15, news: "Town rations drinking water as {name}'s campus keeps running." },
        { label: "Switch to waterless cooling + fund local water projects", detail: "Costs 30% of your cash. More electricity, much less water.",
          s: 8, costFrac: 0.3, set: { wueMult: 0.4, pueAdd: 0.15 }, news: "{name} switches to waterless cooling during the drought." },
      ],
    },
    {
      id: "race", icon: "flag", title: "The race",
      trigger: { stage: 5, progress: 0 }, fact: "nuclear",
      text: "A rival lab claims it is six months from superintelligence. Your board wants more power, now. Renewable projects take years to connect to the grid, but gas turbines can be installed in months.",
      options: [
        { label: "Build private gas turbines next to the campuses", detail: "Huge cash boost. Massive emissions.",
          s: -15, bonusSec: 120, set: { ciBlend: 0.49 }, news: "{name} installs private gas turbines: 'We cannot lose this race.'" },
        { label: "Invest in new renewables + nuclear (slower)", detail: "Costs 30% of your cash.",
          s: 10, costFrac: 0.3, set: { ciBlend: 0.02 }, news: "{name} funds new wind farms and a nuclear restart. Rivals mock its 'slow' plan." },
      ],
    },
  ];

  root.GAME = GAME;
})(typeof window !== "undefined" ? window : globalThis);
