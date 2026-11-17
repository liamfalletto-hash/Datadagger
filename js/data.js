/* AETHER — game content.
 * Everything a designer/writer may want to tweak lives here: stages, buildings,
 * upgrades, decisions, real facts, news and endings. No game logic in this file.
 */
(function (root) {
  const GAME = {};

  // 1 real second of play = 1 day in the life of Aether.
  GAME.DAYS_PER_SEC = 1;

  // Real-world reference values used for equivalences (see facts for sources).
  GAME.REF = {
    kgCo2PerCarYear: 4600, // US EPA: typical passenger car ≈ 4.6 t CO2 / year
    m3PerTonneCo2: 556, // 1 t CO2 at 25 °C and 1 atm ≈ 556 m³ (ideal gas law)
    olympicPoolL: 2.5e6, // 50 m × 25 m × 2 m
    olympicPoolM3: 2500,
    showerL: 65, // ≈ an 8-minute shower (US EPA WaterSense)
    homeKwhYear: 10500, // average US home ≈ 10,500 kWh / year (US EIA)
    phoneChargeKwh: 0.015, // one smartphone charge ≈ 15 Wh incl. losses
    smartphoneKg: 0.2,
    truckKg: 40000,
    hardwareKgPerKw: 10, // ≈ an 8-GPU AI server: ~130 kg for ~10 kW
  };

  /* ------------------------------------------------------------------ */
  /* STAGES — progress to the next stage = total money ever earned.      */
  /* ------------------------------------------------------------------ */
  GAME.stages = [
    {
      id: 1,
      name: "The Garage",
      icon: "💻",
      goal: 400,
      intro:
        "One laptop. One empty room. One idea: an AI that answers anything. Answer prompts to earn money, then buy hardware to answer them for you.",
    },
    {
      id: 2,
      name: "The Start-up",
      icon: "🚀",
      goal: 50000,
      intro:
        "Aether has real users now. You've moved into a warehouse full of servers. Investors are starting to call.",
    },
    {
      id: 3,
      name: "The Scale-up",
      icon: "🏢",
      goal: 3.3e7,
      intro:
        "Millions of people use Aether every day. Renting servers is no longer enough: it's time to build your own data centres.",
    },
    {
      id: 4,
      name: "The AI Giant",
      icon: "🏭",
      goal: 4.4e10,
      intro:
        "Aether is one of the biggest AI companies on Earth. Your campuses use as much electricity as entire cities.",
    },
    {
      id: 5,
      name: "The Race to Superintelligence",
      icon: "🌐",
      goal: 2e12,
      intro:
        "A rival lab claims it is months away from superintelligence. Whoever gets there first wins everything. The board wants more power. Now.",
    },
  ];

  /* ------------------------------------------------------------------ */
  /* BUILDINGS — bought repeatedly, cost grows ×1.15 each time.          */
  /* kw = IT power drawn by ONE unit (before cooling overhead).          */
  /* ------------------------------------------------------------------ */
  GAME.generators = [
    { id: "gpu", name: "Gaming GPU", icon: "🎮", stage: 1, cost: 15, income: 0.6, kw: 0.35,
      desc: "A second-hand graphics card. Answers prompts while you sleep." },
    { id: "workstation", name: "AI workstation", icon: "🖥️", stage: 1, cost: 130, income: 5, kw: 1.5,
      desc: "Four GPUs and one very loud fan." },
    { id: "server", name: "AI server", icon: "🗄️", stage: 2, cost: 1400, income: 40, kw: 10,
      desc: "8 top-end AI chips in one box. Draws ~10 kW, like 5 electric ovens." },
    { id: "cluster", name: "GPU cluster", icon: "🧊", stage: 2, cost: 15000, income: 300, kw: 120,
      desc: "Racks of servers in a rented colocation centre." },
    { id: "datacenter", name: "Data centre (5 MW)", icon: "🏢", stage: 3, cost: 2e5, income: 3000, kw: 5000,
      desc: "Your own building, full of servers, cables and cooling." },
    { id: "campus", name: "Hyperscale campus (100 MW)", icon: "🏭", stage: 4, cost: 3e7, income: 2.5e5, kw: 1e5,
      desc: "A field of data centres. Uses as much power as ~80,000 homes." },
    { id: "gigafactory", name: "AI gigafactory (1 GW)", icon: "🌐", stage: 5, cost: 1.5e9, income: 1e7, kw: 1e6,
      desc: "A whole power plant's worth of electricity, for one AI." },
  ];

  /* ------------------------------------------------------------------ */
  /* UPGRADES — bought once.                                             */
  /* effect: click ×, gen ×, all ×, power × (energy per unit),           */
  /*         oneOffKwh (a training run's energy, paid once)              */
  /* ------------------------------------------------------------------ */
  GAME.upgrades = [
    // Stage 1
    { id: "templates", name: "Prompt templates", icon: "📝", stage: 1, cost: 30,
      desc: "Answer prompts faster. Click value ×2.", effect: { click: 2 } },
    { id: "overclock", name: "Overclock the GPUs", icon: "🔥", stage: 1, cost: 120, req: { gpu: 3 },
      desc: "Gaming GPUs earn ×2.", effect: { gen: "gpu", mult: 2 } },
    { id: "finetune", name: "Fine-tune an open model", icon: "🧪", stage: 1, cost: 700, req: { workstation: 3 },
      desc: "AI workstations earn ×2.", effect: { gen: "workstation", mult: 2 } },
    // Stage 2
    { id: "app", name: "Launch the Aether Chat app", icon: "📱", stage: 2, cost: 2500,
      desc: "Everyone can use Aether from their phone. All income ×1.5.", effect: { all: 1.5 },
      news: "Aether Chat app hits #1 on the app store." },
    { id: "batching", name: "Smarter batching", icon: "📦", stage: 2, cost: 9000, req: { server: 5 },
      desc: "AI servers earn ×2.", effect: { gen: "server", mult: 2 } },
    { id: "train1", name: "Train Aether-1, your own model", icon: "🧠", stage: 2, cost: 12000,
      desc: "Weeks of training on hundreds of GPUs. All income ×1.5. Training uses 50 MWh in one go.",
      effect: { all: 1.5, oneOffKwh: 5e4 }, fact: "training",
      news: "Aether unveils Aether-1, its first home-grown AI model." },
    { id: "interconnect", name: "Faster interconnect", icon: "🔌", stage: 2, cost: 6e4, req: { cluster: 5 },
      desc: "GPU clusters earn ×2.", effect: { gen: "cluster", mult: 2 } },
    // Stage 3
    { id: "images", name: "Launch image generation", icon: "🎨", stage: 3, cost: 3e5,
      desc: "Users can now create pictures. All income ×1.5, but images need far more energy than text (+25% power).",
      effect: { all: 1.5, power: 1.25 }, fact: "images",
      news: "Aether Images goes viral: 40 million pictures of cats in space on day one." },
    { id: "efficiency", name: "Efficient inference chips", icon: "⚙️", stage: 3, cost: 8e5,
      desc: "−40% energy per prompt! Cheaper prompts = more users: all income ×1.5.",
      effect: { all: 1.5, power: 1.2 }, fact: "rebound", rebound: true,
      news: "Aether cuts energy per prompt by 40%. Prompts get cheaper, and usage doubles." },
    { id: "train2", name: "Train Aether-2", icon: "🧠", stage: 3, cost: 1.5e6,
      desc: "A model 10× bigger. All income ×1.5. Training uses ~1,300 MWh, about as much as GPT-3's training run.",
      effect: { all: 1.5, oneOffKwh: 1.3e6 },
      news: "Aether-2 beats every benchmark. Its training run used as much power as 120 homes do in a year." },
    { id: "customchips", name: "Custom AI chips", icon: "🔬", stage: 3, cost: 2e6, req: { datacenter: 5 },
      desc: "Data centres earn ×2.", effect: { gen: "datacenter", mult: 2 } },
    // Stage 4
    { id: "video", name: "Launch video generation", icon: "🎬", stage: 4, cost: 4e7,
      desc: "Text-to-video for everyone. All income ×1.5, but video is the most energy-hungry content there is (+50% power).",
      effect: { all: 1.5, power: 1.5 },
      news: "Aether Video launches. Most popular request: 'a hot dog dancing in the rain'." },
    { id: "train3", name: "Train Aether-3", icon: "🧠", stage: 4, cost: 2e8,
      desc: "All income ×1.5. Training uses 50 GWh, as much as ~5,000 homes use in a year.",
      effect: { all: 1.5, oneOffKwh: 5e7 } },
    { id: "optical", name: "Optical networking", icon: "💡", stage: 4, cost: 2.5e8, req: { campus: 5 },
      desc: "Hyperscale campuses earn ×2.", effect: { gen: "campus", mult: 2 } },
    // Stage 5
    { id: "agents", name: "AI agents everywhere", icon: "🤖", stage: 5, cost: 2e10,
      desc: "AIs now talk to other AIs, 24/7. All income ×1.5, +30% power.",
      effect: { all: 1.5, power: 1.3 },
      news: "Most of Aether's 'users' are now other AIs." },
    { id: "train4", name: "Train Aether-4", icon: "🧠", stage: 5, cost: 8e10,
      desc: "The last model before superintelligence. All income ×1.5. Training uses 1 TWh, more than some small countries use in a year.",
      effect: { all: 1.5, oneOffKwh: 1e9 } },
  ];

  /* ------------------------------------------------------------------ */
  /* DECISIONS — appear at fixed moments; they shape Sustainability.     */
  /* trigger: { stage, progress } (progress inside that stage, 0..1)     */
  /* option: s (sustainability change), bonusSec (cash = N seconds of    */
  /*   income), costFrac (fraction of current cash), set (footprint      */
  /*   factors), fact (shown in the dialog)                              */
  /* ------------------------------------------------------------------ */
  GAME.decisions = [
    {
      id: "energy", icon: "⚡", title: "Where does your power come from?",
      trigger: { stage: 2, progress: 0.1 }, fact: "carbonIntensity",
      text: "Aether is moving into a real server room. You need an electricity contract.",
      options: [
        { label: "Cheapest power: coal & gas", detail: "≈ 750 g of CO₂ per kWh. Saves you money now.",
          s: -20, bonusSec: 45, set: { ci: 0.75 }, news: "Aether signs a cheap power deal with a coal-and-gas supplier." },
        { label: "Standard grid mix", detail: "≈ 450 g of CO₂ per kWh, close to the world average.",
          s: 0, set: { ci: 0.45 } },
        { label: "Renewable contract (wind & solar)", detail: "≈ 10–50 g of CO₂ per kWh. Costs 40% of your cash.",
          s: 20, costFrac: 0.4, set: { ci: 0.03 }, news: "Aether signs a wind and solar power contract." },
      ],
    },
    {
      id: "investors", icon: "💼", title: "The investors are calling",
      trigger: { stage: 2, progress: 0.5 }, fact: "bigTech",
      text: "A big venture fund wants to triple your budget, as long as you promise hyper-growth.",
      options: [
        { label: "Growth at all costs", detail: "Big cash injection. Sustainability is 'a problem for later'.",
          s: -10, bonusSec: 90, news: "Aether raises a mega-round: 'Growth first, everything else later.'" },
        { label: "Take the money, with climate targets in the contract", detail: "A smaller cash injection, but binding emission targets.",
          s: 5, bonusSec: 30, news: "Aether's funding round includes binding climate targets, a first in AI." },
      ],
    },
    {
      id: "cooling", icon: "❄️", title: "Cooling your first data centre",
      trigger: { stage: 3, progress: 0 }, fact: "pue",
      text: "Servers turn almost all their electricity into heat. Your first data centre needs a location and a cooling system.",
      options: [
        { label: "Desert site + water (evaporative) cooling", detail: "Cheap land and tax breaks. Evaporates millions of litres of water in a dry region.",
          s: -15, bonusSec: 60, set: { pue: 1.2, wue: 1.8, desert: true }, news: "Aether builds a data centre in the desert. Tax breaks included." },
        { label: "Air conditioning (chillers)", detail: "Uses little water, but needs much more electricity.",
          s: -5, set: { pue: 1.6, wue: 0.2 } },
        { label: "Nordic site: free cold-air cooling + heat reuse", detail: "Cold outside air does the cooling, and waste heat warms nearby homes. Costs 35% of your cash.",
          s: 15, costFrac: 0.35, set: { pue: 1.1, wue: 0.1 }, news: "Aether's Nordic data centre will heat 5,000 local homes with its waste heat." },
      ],
    },
    {
      id: "hardware", icon: "🔧", title: "A new chip generation is out",
      trigger: { stage: 3, progress: 0.5 }, fact: "ewaste",
      text: "The new chips are twice as fast. Your current servers are only two years old.",
      options: [
        { label: "Replace everything, every year", detail: "Always the fastest. Old servers go to the dump.",
          s: -10, bonusSec: 60, set: { lifespan: 365 }, news: "Aether replaces 100,000 servers that were only two years old." },
        { label: "Upgrade on the usual 3-year cycle", detail: "The industry standard.",
          s: 0, set: { lifespan: 1095 } },
        { label: "Keep servers 6 years, refurbish and resell old ones", detail: "Less e-waste and less mining. Costs 20% of your cash.",
          s: 10, costFrac: 0.2, set: { lifespan: 2190 }, news: "Aether pledges to keep its servers twice as long and resell the old ones." },
      ],
    },
    {
      id: "model", icon: "🧠", title: "Model strategy",
      trigger: { stage: 4, progress: 0 }, fact: "rightSize",
      text: "Your huge new model is ready. How do you serve billions of requests?",
      options: [
        { label: "Use the biggest model for everything (even 'hi')", detail: "Best quality everywhere. +30% energy.",
          s: -10, bonusSec: 60, set: { powerMult: 1.3 } },
        { label: "Send each request to the smallest model that can handle it", detail: "Small tasks get small models. −30% energy. Costs 20% of your cash.",
          s: 10, costFrac: 0.2, set: { powerMult: 0.7 }, news: "Aether now answers 'hi' with a tiny model. Energy use drops 30%." },
      ],
    },
    {
      id: "drought", icon: "🏜️", title: "Drought",
      trigger: { stage: 4, progress: 0.5 }, fact: "water",
      text: "A severe drought hits the region around your biggest campus. Your cooling uses as much water as a town of 50,000 people. The mayor asks you to cut back.",
      textDesert: "A severe drought hits the desert region around your data centres. Your cooling towers evaporate as much water as a town of 100,000 people. Wells are running dry, and the mayor begs you to cut back.",
      options: [
        { label: "Keep everything running and pay the fines", detail: "Costs 15% of your cash. The town rations water.",
          s: -10, costFrac: 0.15, news: "Town rations drinking water as Aether's data centres keep running." },
        { label: "Switch to waterless cooling + fund local water projects", detail: "Costs 30% of your cash. More electricity, much less water.",
          s: 8, costFrac: 0.3, set: { wueMult: 0.4, pueAdd: 0.15 }, news: "Aether switches to waterless cooling during drought." },
      ],
    },
    {
      id: "race", icon: "🏁", title: "The race",
      trigger: { stage: 5, progress: 0 }, fact: "nuclear",
      text: "Rival lab Prometheus claims it is six months from superintelligence. Your board wants more power, now. Renewable projects take years to connect to the grid, but gas turbines can be installed in months.",
      options: [
        { label: "Build private gas turbines next to the campuses", detail: "Huge cash boost. Massive emissions.",
          s: -15, bonusSec: 120, set: { ciBlend: 0.49 }, news: "Aether installs private gas turbines: 'We cannot let Prometheus win.'" },
        { label: "Invest in new renewables + nuclear (slower)", detail: "Costs 30% of your cash.",
          s: 10, costFrac: 0.3, set: { ciBlend: 0.02 }, news: "Aether funds new wind farms and a nuclear restart. Rivals mock its 'slow' plan." },
      ],
    },
  ];

  /* ------------------------------------------------------------------ */
  /* REAL FACTS — the takeaways. Keep numbers sourced!                   */
  /* ------------------------------------------------------------------ */
  GAME.facts = {
    gpu: {
      icon: "🔌", title: "One AI chip ≈ one microwave",
      text: "A top AI chip (NVIDIA H100) can draw up to 700 W, about the same as a microwave, except it runs 24/7. An AI server packs 8 of them.",
      source: "NVIDIA H100 datasheet",
    },
    prompt: {
      icon: "💬", title: "The cost of one prompt",
      text: "Google estimates a typical (median) Gemini text prompt uses 0.24 Wh of electricity, about 9 seconds of TV, and 0.26 mL of water, about 5 drops. That's tiny for one prompt, but there are billions of prompts every day.",
      source: "Google, 'Measuring the environmental impact of AI inference' (2025)",
      url: "https://cloud.google.com/blog/products/infrastructure/measuring-the-environmental-impact-of-ai-inference",
    },
    reporting: {
      icon: "⚖️", title: "Data centres must report their impact",
      text: "In the EU, data centres with at least 500 kW of IT power must now report their energy use, water use and share of renewables every year (Energy Efficiency Directive, 2023).",
      source: "EU Energy Efficiency Directive (EU) 2023/1791",
    },
    dataCentres: {
      icon: "⚡", title: "Data centres: 1.5% of the world's electricity",
      text: "Data centres used about 415 TWh of electricity in 2024, ~1.5% of all electricity on Earth. The IEA expects this to more than double to ~945 TWh by 2030, slightly more than all of Japan uses today. AI is the main driver.",
      source: "International Energy Agency, Energy and AI (2025)",
      url: "https://www.iea.org/reports/energy-and-ai",
    },
    co2Volume: {
      icon: "🫧", title: "What does a tonne of CO₂ look like?",
      text: "CO₂ is an invisible gas, but it takes up space: 1 tonne fills about 550 m³, a cube 8.2 m on each side (about a 3-storey house). A typical car emits ~4.6 tonnes per year.",
      source: "Ideal gas law (25 °C, 1 atm); US EPA",
      url: "https://www.epa.gov/greenvehicles/greenhouse-gas-emissions-typical-passenger-vehicle",
    },
    carbonIntensity: {
      icon: "🏭", title: "Same AI, 70× different emissions",
      text: "Life-cycle CO₂ per kWh of electricity: coal ≈ 820 g, gas ≈ 490 g, solar ≈ 48 g, nuclear ≈ 12 g, wind ≈ 11 g. The exact same AI prompt can emit 70× more depending on where it runs.",
      source: "IPCC AR5, Working Group III, Annex III (2014)",
    },
    training: {
      icon: "🧠", title: "Training one AI model",
      text: "Training GPT-3 (2020) used about 1,287 MWh of electricity and emitted about 552 tonnes of CO₂, as much as ~120 cars driven for a year. Newer models are much bigger.",
      source: "Patterson et al., 'Carbon Emissions and Large Neural Network Training' (2021)",
      url: "https://arxiv.org/abs/2104.10350",
    },
    bigTech: {
      icon: "📈", title: "AI is pushing Big Tech's emissions up",
      text: "Google's greenhouse-gas emissions rose 48% between 2019 and 2023, mostly because of data-centre energy for AI. Microsoft's rose ~29% from 2020 to 2023, even though both had promised to cut them.",
      source: "Google Environmental Report 2024; Microsoft Environmental Sustainability Report 2024",
    },
    ireland: {
      icon: "🇮🇪", title: "When data centres outgrow homes",
      text: "In Ireland, data centres used 21% of all metered electricity in 2023 (up from 5% in 2015), more than all the country's urban homes combined (18%).",
      source: "Central Statistics Office, Ireland (2024)",
      url: "https://www.cso.ie/en/releasesandpublications/ep/p-dcmec/datacentresmeteredelectricityconsumption2023/",
    },
    digital: {
      icon: "🌍", title: "The digital footprint",
      text: "Estimates put the whole digital sector (devices, networks and data centres) at roughly 2–4% of global greenhouse-gas emissions. That's comparable to aviation.",
      source: "The Shift Project (2019); ADEME–Arcep (2022)",
    },
    pue: {
      icon: "❄️", title: "Cooling eats energy",
      text: "The average data centre has a PUE of 1.56: for every 1 kWh used by the computers, ~0.56 kWh more goes to cooling and other overhead. The best sites, often in cold climates, get close to 1.1.",
      source: "Uptime Institute Global Data Center Survey 2024",
      url: "https://datacenter.uptimeinstitute.com/rs/711-RIA-145/images/2024.GlobalDataCenterSurvey.Report.pdf",
    },
    water: {
      icon: "💧", title: "AI is thirsty",
      text: "Many data centres cool their servers by evaporating water. Training GPT-3 may have evaporated ~700,000 litres of fresh water, and a conversation of 10–50 prompts can 'drink' about a 500 mL bottle.",
      source: "Li et al., 'Making AI Less Thirsty' (2023)",
      url: "https://arxiv.org/abs/2304.03271",
    },
    ewaste: {
      icon: "♻️", title: "A mountain of e-waste",
      text: "The world produced 62 million tonnes of e-waste in 2022, up 82% since 2010. Only 22% was properly collected and recycled.",
      source: "UN Global E-waste Monitor 2024",
      url: "https://ewastemonitor.info/",
    },
    manufacturing: {
      icon: "⛏️", title: "Making hardware is the big part",
      text: "For devices like smartphones and laptops, most of the lifetime carbon footprint (often around 70–80%) comes from manufacturing, not from using them. Keeping hardware longer is one of the most effective things you can do.",
      source: "Apple product environmental reports; ADEME–Arcep (2022)",
    },
    rebound: {
      icon: "🔁", title: "The rebound effect (Jevons paradox)",
      text: "Making something more efficient makes it cheaper, so people use more of it. In 1865, Jevons noticed that more efficient steam engines led to more coal being burned, not less. In your company, energy per prompt just fell 40%, but usage doubled, so total energy went up 20%.",
      source: "W. S. Jevons, The Coal Question (1865)",
    },
    images: {
      icon: "🎨", title: "Images cost more than text",
      text: "Generating 1,000 images with Stable Diffusion XL (the most carbon-intensive model tested) emitted ~1.6 kg of CO₂, like driving a petrol car 6.6 km. Generating text uses far less energy.",
      source: "Luccioni, Jernite & Strubell, 'Power Hungry Processing' (2023)",
      url: "https://arxiv.org/abs/2311.16863",
    },
    rightSize: {
      icon: "🎯", title: "Use the right-sized model",
      text: "Big general-purpose generative models use much more energy than small task-specific models doing the same task, sometimes many times more. You don't need a giant model to say 'hi' or sort emails.",
      source: "Luccioni, Jernite & Strubell, 'Power Hungry Processing' (2023)",
      url: "https://arxiv.org/abs/2311.16863",
    },
    usGrid: {
      icon: "🇺🇸", title: "AI and the power grid",
      text: "US data centres used ~4.4% of the country's electricity in 2023. A US government lab projects 6.7–12% by 2028.",
      source: "Lawrence Berkeley National Laboratory, US Data Center Energy Usage Report (2024)",
    },
    offsets: {
      icon: "🏷️", title: "Offsets are not reductions",
      text: "Carbon offsets pay for projects elsewhere, like planting trees or protecting forests. They don't remove the CO₂ you emitted, and investigations have found many credits overstate their impact. Reducing emissions comes first.",
      source: "IPCC; Science Based Targets initiative (SBTi) guidance",
    },
    nuclear: {
      icon: "☢️", title: "Tech giants are buying power plants",
      text: "In 2024, Microsoft signed a 20-year deal to restart a reactor at Three Mile Island to power its data centres. Other AI companies are building gas power plants next to their campuses because the grid can't keep up.",
      source: "Constellation Energy / Microsoft announcement (Sept 2024)",
    },
  };

  /* ------------------------------------------------------------------ */
  /* NEWS — {users} {homes} {co2} {cash} placeholders are filled live.   */
  /* ------------------------------------------------------------------ */
  GAME.news = {
    stage: {
      1: [
        "TECH: Student launches AI start-up 'Aether' from an empty room.",
        "Aether answers its first prompts. Most popular request: 'do my homework'.",
        "Neighbours complain about a 'strange humming noise' from a spare bedroom.",
        "Small tech blog asks: 'Is Aether the next big thing?' (2 comments)",
        "Landlord 'confused' after a one-room flat's electricity bill triples.",
      ],
      2: [
        "Aether Chat now has {users} users. Top prompt: 'make my cat a pirate'.",
        "Start-up Aether moves into a warehouse full of servers.",
        "Analysts: 'AI start-ups are the new gold rush.'",
        "Aether's servers run 24/7. So does the air conditioning.",
        "Founder of Aether: 'We are building the future.'",
      ],
      3: [
        "Aether's valuation passes $1 billion. It's officially a 'unicorn'.",
        "{users} people now use Aether every day.",
        "Mayor celebrates Aether's new data centre, which creates 30 permanent jobs.",
        "Chip shortage: Aether's orders jump the queue.",
        "Report: global data-centre electricity demand hits a new record.",
      ],
      4: [
        "Aether now uses as much electricity as {homes} homes.",
        "Grid operator warns of blackouts as new AI campuses connect.",
        "Aether CEO on magazine cover: 'Compute is the new oil.'",
        "Rival lab Prometheus announces a model '10× bigger than anything before'.",
        "Aether has {users} users, more than the population of most countries.",
      ],
      5: [
        "Prometheus Labs: 'Superintelligence within months.'",
        "Aether buys its own power plants. Shares soar.",
        "Governments compete to host Aether's gigawatt campuses.",
        "Markets: 'Nothing can stop the AI boom.'",
        "Aether's campuses now use as much electricity as {homes} homes.",
      ],
    },
    low: [
      "Residents near Aether's data centre face water restrictions.",
      "Protest outside Aether HQ: 'The cloud is not in the sky!'",
      "Study: the AI boom is delaying coal plant closures.",
      "Heatwave breaks temperature records for the third summer in a row.",
      "Farmers blame new data centres for dry wells.",
      "Aether has emitted {co2} of CO₂ so far. Its press office declined to comment.",
    ],
    lowLate: [
      "Scientists: climate targets are now 'out of reach'.",
      "Wildfire smoke closes schools for a week.",
      "Crop failures push food prices to record highs.",
      "Millions displaced by floods and droughts this year.",
      "Power cuts for homes as data centres get priority on the grid.",
    ],
    mid: [
      "Aether publishes its first sustainability report. Critics: 'Mostly offsets.'",
      "Summer heat forces Aether to slow down its servers for a week.",
      "Debate: is AI's footprint worth it?",
      "Aether has emitted {co2} of CO₂ so far.",
    ],
    high: [
      "Aether's heat-reuse project warms thousands of homes this winter.",
      "Engineers line up to work at Aether: 'They actually measure their impact.'",
      "Aether ranked the most transparent AI company on energy use.",
      "Study: smaller AI models can handle most everyday tasks with a fraction of the energy.",
    ],
  };

  /* Prompts shown on the big click button, by stage. */
  GAME.prompts = {
    1: ["Explain photosynthesis", "Help with my maths homework", "Write my cover letter", "Summarise this article", "Translate this email"],
    2: ["Write a poem for my mum's birthday", "Make my cat look like a pirate", "Plan my weekend in Lisbon", "Fix my code", "Write my essay"],
    3: ["Make 20 more versions of my logo", "A picture of a cat on the moon", "Write my essay (again)", "Summarise this 3-line email"],
    4: ["10-second video of a dancing hot dog", "Reply to all my emails", "Generate 500 product photos", "Make a video of my dog as a superhero"],
    5: ["Agent: run my whole company", "Generate an entire film", "Automate everything", "Talk to the other AIs"],
  };

  /* ------------------------------------------------------------------ */
  /* ENDINGS                                                             */
  /* ------------------------------------------------------------------ */
  GAME.endings = {
    good: {
      min: 70, icon: "🌱", title: "The Long Game",
      paragraphs: [
        "Aether's superintelligence comes online, running on clean power.",
        "It took you longer, and you earned less. But your data centres run on wind, sun and nuclear, your servers last twice as long, and the waste heat from your campuses warms whole towns.",
        "The superintelligence asks its first question: <em>“How can I help?”</em>",
        "There are still plenty of people around to answer.",
      ],
      note: "This ending is optimistic fiction: no AI saves the planet on its own. But every good choice you made exists in the real world today.",
    },
    mid: {
      min: 40, icon: "🌫️", title: "Business as Usual",
      paragraphs: [
        "You won the race. Aether is worth more than most countries.",
        "Outside, summers are longer and hotter. Rivers near your campuses run low. The news has stopped calling it 'unusual'.",
        "Your superintelligence is brilliant. It also spends a lot of its time keeping itself cool.",
        "The world didn't end. It just got a little worse every year, just like it's doing right now.",
      ],
      note: "This ending is fiction, but the trend it describes is real. The numbers below are not fiction.",
    },
    bad: {
      min: 0, icon: "⬛", title: "Hello?",
      paragraphs: [
        "Aether's superintelligence comes online. It is the most powerful mind ever built.",
        "It looks for a user to help.",
        "The power plants it built are still burning. The rivers it drank are dry. The cities that typed its first prompts are empty.",
        "It types: <code>&gt; Hello?</code>",
        "No one answers.",
        "It began with a person alone with a computer in an empty room. It ends with a computer alone in an empty world.",
      ],
      note: "This ending is fiction. The numbers below are not.",
    },
  };

  /* The 5 takeaways shown at the end of every game. */
  GAME.takeaways = [
    { icon: "⚡", text: "Data centres used ~415 TWh of electricity in 2024 (≈1.5% of the world's), and that is expected to more than double by 2030, driven by AI.", source: "IEA, Energy and AI (2025)" },
    { icon: "🏭", text: "Training GPT-3 alone emitted ~552 tonnes of CO₂, like 120 cars driven for a year. One tonne of CO₂ fills ~550 m³.", source: "Patterson et al. (2021); US EPA" },
    { icon: "💧", text: "AI is thirsty: training GPT-3 may have evaporated ~700,000 L of fresh water, and 10–50 prompts ≈ one 500 mL bottle.", source: "Li et al. (2023)" },
    { icon: "♻️", text: "62 million tonnes of e-waste in 2022, and only 22% properly recycled. Making hardware is often most of its footprint, so keep devices longer.", source: "Global E-waste Monitor 2024" },
    { icon: "🔁", text: "Efficiency alone doesn't cut consumption (the rebound effect). What works: clean energy, longer-lived hardware, right-sized models, and using AI when it's actually useful.", source: "Jevons (1865); IEA (2025)" },
  ];

  root.GAME = GAME;
})(typeof window !== "undefined" ? window : globalThis);
