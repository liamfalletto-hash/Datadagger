/* Words of the game: real facts, press questions, news, prompts, goals,
 * badges, endings and the world ranking. "{name}" = the player's start-up. */
(function (root) {
  const GAME = root.GAME || (root.GAME = {});

  /* ---------- Real facts (the takeaways). Keep every number sourced. ---------- */
  GAME.facts = {
    gpu: { icon: "plug", title: "One AI chip ≈ one microwave",
      text: "A top AI chip (NVIDIA H100) can draw up to 700 W, about the same as a microwave, except it runs 24/7. An AI server packs 8 of them.",
      source: "NVIDIA H100 datasheet" },
    prompt: { icon: "bubble", title: "The cost of one prompt",
      text: "Google estimates a typical (median) Gemini text prompt uses 0.24 Wh of electricity, about 9 seconds of TV, and 0.26 mL of water, about 5 drops. That's tiny for one prompt, but there are billions of prompts every day.",
      source: "Google, 'Measuring the environmental impact of AI inference' (2025)",
      url: "https://cloud.google.com/blog/products/infrastructure/measuring-the-environmental-impact-of-ai-inference" },
    reporting: { icon: "note", title: "Data centres must report their impact",
      text: "In the EU, data centres with at least 500 kW of IT power must now report their energy use, water use and share of renewables every year.",
      source: "EU Energy Efficiency Directive (EU) 2023/1791" },
    dataCentres: { icon: "bolt", title: "Data centres: 1.5% of the world's electricity",
      text: "Data centres used about 415 TWh of electricity in 2024, about 1.5% of all electricity on Earth. The IEA expects this to more than double to about 945 TWh by 2030, slightly more than all of Japan uses today. AI is the main driver.",
      source: "International Energy Agency, Energy and AI (2025)", url: "https://www.iea.org/reports/energy-and-ai" },
    co2Volume: { icon: "cloud", title: "What does a tonne of CO₂ look like?",
      text: "CO₂ is an invisible gas, but it takes up space: 1 tonne fills about 550 m³, a cube 8.2 m on each side (about a 3-storey house). A typical car emits about 4.6 tonnes a year.",
      source: "Ideal gas law (25 °C, 1 atm); US EPA",
      url: "https://www.epa.gov/greenvehicles/greenhouse-gas-emissions-typical-passenger-vehicle" },
    carbonIntensity: { icon: "factory", title: "Same AI, 70× different emissions",
      text: "Life-cycle CO₂ per kWh of electricity: coal ≈ 820 g, gas ≈ 490 g, solar ≈ 48 g, nuclear ≈ 12 g, wind ≈ 11 g. The exact same AI prompt can emit 70× more depending on where it runs.",
      source: "IPCC AR5, Working Group III, Annex III (2014)" },
    training: { icon: "brain", title: "Training one AI model",
      text: "Training GPT-3 (2020) used about 1,287 MWh of electricity and emitted about 552 tonnes of CO₂, as much as about 120 cars driven for a year. Newer models are much bigger.",
      source: "Patterson et al., 'Carbon Emissions and Large Neural Network Training' (2021)", url: "https://arxiv.org/abs/2104.10350" },
    bigTech: { icon: "chart", title: "AI is pushing Big Tech's emissions up",
      text: "Google's greenhouse-gas emissions rose 48% between 2019 and 2023, mostly because of data-centre energy for AI. Microsoft's rose about 29% from 2020 to 2023, even though both had promised to cut them.",
      source: "Google Environmental Report 2024; Microsoft Environmental Sustainability Report 2024" },
    ireland: { icon: "house", title: "When data centres outgrow homes",
      text: "In Ireland, data centres used 21% of all metered electricity in 2023 (up from 5% in 2015), more than all the country's urban homes combined (18%).",
      source: "Central Statistics Office, Ireland (2024)",
      url: "https://www.cso.ie/en/releasesandpublications/ep/p-dcmec/datacentresmeteredelectricityconsumption2023/" },
    digital: { icon: "globe", title: "The digital footprint",
      text: "Estimates put the whole digital sector (devices, networks and data centres) at roughly 2–4% of global greenhouse-gas emissions, comparable to aviation.",
      source: "The Shift Project (2019); ADEME–Arcep (2022)" },
    pue: { icon: "drop", title: "Cooling eats energy",
      text: "The average data centre has a PUE of 1.56: for every 1 kWh used by the computers, about 0.56 kWh more goes to cooling and other overhead. The best sites, often in cold climates, get close to 1.1.",
      source: "Uptime Institute Global Data Center Survey 2024",
      url: "https://datacenter.uptimeinstitute.com/rs/711-RIA-145/images/2024.GlobalDataCenterSurvey.Report.pdf" },
    water: { icon: "drop", title: "AI is thirsty",
      text: "Many data centres cool their servers by evaporating water. Training GPT-3 may have evaporated about 700,000 litres of fresh water, and a conversation of 10–50 prompts can 'drink' about a 500 mL bottle.",
      source: "Li et al., 'Making AI Less Thirsty' (2023)", url: "https://arxiv.org/abs/2304.03271" },
    ewaste: { icon: "trash", title: "A mountain of e-waste",
      text: "The world produced 62 million tonnes of e-waste in 2022, up 82% since 2010. Only 22% was properly collected and recycled.",
      source: "UN Global E-waste Monitor 2024", url: "https://ewastemonitor.info/" },
    manufacturing: { icon: "recycle", title: "Making hardware is the big part",
      text: "For devices like smartphones and laptops, most of the lifetime carbon footprint (often around 70–80%) comes from manufacturing them, not from using them. Keeping hardware longer is one of the most effective things you can do.",
      source: "Apple product environmental reports; ADEME–Arcep (2022)" },
    rebound: { icon: "chart", title: "The rebound effect (Jevons paradox)",
      text: "Making something more efficient makes it cheaper, so people use more of it. In 1865, Jevons noticed that more efficient steam engines led to more coal being burned, not less. Cheaper AI prompts work the same way.",
      source: "W. S. Jevons, The Coal Question (1865)" },
    images: { icon: "image", title: "Images cost more than text",
      text: "Generating 1,000 images with Stable Diffusion XL (the most carbon-intensive model tested) emitted about 1.6 kg of CO₂, like driving a petrol car 6.6 km. Generating text uses far less energy.",
      source: "Luccioni, Jernite & Strubell, 'Power Hungry Processing' (2023)", url: "https://arxiv.org/abs/2311.16863" },
    rightSize: { icon: "brain", title: "Use the right-sized model",
      text: "Big general-purpose AI models use much more energy than small task-specific models doing the same task, sometimes many times more. You don't need a giant model to say 'hi' or sort emails.",
      source: "Luccioni, Jernite & Strubell, 'Power Hungry Processing' (2023)", url: "https://arxiv.org/abs/2311.16863" },
    usGrid: { icon: "bolt", title: "AI and the power grid",
      text: "US data centres used about 4.4% of the country's electricity in 2023. A US government lab projects 6.7–12% by 2028.",
      source: "Lawrence Berkeley National Laboratory, US Data Center Energy Usage Report (2024)" },
    offsets: { icon: "leaf", title: "Offsets are not reductions",
      text: "Carbon offsets pay for projects elsewhere, like planting trees or protecting forests. They don't remove the CO₂ you emitted, and investigations have found many credits overstate their impact. Cutting emissions comes first.",
      source: "IPCC; Science Based Targets initiative (SBTi) guidance" },
    nuclear: { icon: "factory", title: "Tech giants are buying power plants",
      text: "In 2024, Microsoft signed a 20-year deal to restart a reactor at Three Mile Island to power its data centres. Other AI companies are building gas power plants next to their campuses because the grid can't keep up.",
      source: "Constellation Energy / Microsoft announcement (September 2024)" },
  };

  /* ---------- Press conferences: one question per fact. ---------- */
  GAME.press = {
    gpu: { q: "A top AI chip (NVIDIA H100) can draw up to…", options: ["70 W", "700 W", "7,000 W"], answer: 1 },
    prompt: { q: "Google's estimate for one typical Gemini text prompt is about…", options: ["0.24 Wh", "24 Wh", "2.4 kWh"], answer: 0 },
    reporting: { q: "In the EU, which data centres must report their energy and water use?", options: ["None of them", "Those with at least 500 kW of IT power", "Only the ones in France"], answer: 1 },
    dataCentres: { q: "How much electricity did the world's data centres use in 2024?", options: ["41 TWh", "415 TWh", "4,150 TWh"], answer: 1 },
    co2Volume: { q: "How much space does 1 tonne of CO₂ gas take up?", options: ["About 5 m³", "About 550 m³", "About 55,000 m³"], answer: 1 },
    carbonIntensity: { q: "Which of these emits the least CO₂ per kWh over its life cycle?", options: ["Coal", "Gas", "Wind"], answer: 2 },
    training: { q: "Training GPT-3 emitted about as much CO₂ as how many cars driven for a year?", options: ["12", "120", "12,000"], answer: 1 },
    bigTech: { q: "How much did Google's emissions rise between 2019 and 2023?", options: ["+4%", "+48%", "+480%"], answer: 1 },
    ireland: { q: "In 2023, what share of Ireland's metered electricity went to data centres?", options: ["2%", "21%", "51%"], answer: 1 },
    digital: { q: "The whole digital sector is roughly what share of global greenhouse emissions?", options: ["0.2%", "2–4%", "20–40%"], answer: 1 },
    pue: { q: "With an average PUE of 1.56, for every 1 kWh used by the computers, how much more goes to cooling and overhead?", options: ["0.06 kWh", "0.56 kWh", "1.56 kWh"], answer: 1 },
    water: { q: "A conversation of 10–50 prompts can 'drink' about…", options: ["5 drops of water", "A 500 mL bottle", "A bathtub"], answer: 1 },
    ewaste: { q: "What share of the world's e-waste was properly recycled in 2022?", options: ["About 22%", "About 62%", "About 92%"], answer: 0 },
    manufacturing: { q: "For a smartphone, where does most of the carbon footprint come from?", options: ["Charging it", "Making it", "Recycling it"], answer: 1 },
    rebound: { q: "When something gets more efficient, people often use more of it. This is called…", options: ["The rebound effect", "The greenhouse effect", "The domino effect"], answer: 0 },
    images: { q: "Generating 1,000 images with SDXL emitted about as much CO₂ as driving a car…", options: ["6.6 metres", "6.6 km", "660 km"], answer: 1 },
    rightSize: { q: "To answer 'hi', which choice wastes the least energy?", options: ["The biggest model", "A small task-specific model", "Two models at once"], answer: 1 },
    usGrid: { q: "US data centres used about 4.4% of US electricity in 2023. By 2028 that could reach…", options: ["1–2%", "6.7–12%", "50%"], answer: 1 },
    offsets: { q: "What does buying carbon offsets actually do?", options: ["Removes the CO₂ you emitted", "Pays for projects elsewhere, often overstated", "Nothing, it's illegal"], answer: 1 },
    nuclear: { q: "In 2024, Microsoft signed a deal to restart a nuclear reactor at…", options: ["Chernobyl", "Three Mile Island", "Fukushima"], answer: 1 },
  };

  /* ---------- Prompts on the click bubble, by stage. ---------- */
  GAME.prompts = {
    1: ["Explain photosynthesis", "Help with my maths homework", "Write my cover letter", "Summarise this article", "Translate this email"],
    2: ["Write a poem for my mum", "Make my cat look like a pirate", "Plan my weekend in Lisbon", "Fix my code", "Write my essay"],
    3: ["Make 20 more versions of my logo", "A cat on the moon, please", "Write my essay (again)", "Summarise this 3-line email"],
    4: ["10-second video of a dancing hot dog", "Reply to all my emails", "500 product photos", "My dog as a superhero"],
    5: ["Agent: run my whole company", "Generate an entire film", "Automate everything", "Talk to the other AIs"],
  };

  /* ---------- News ---------- */
  GAME.news = {
    stage: {
      1: ["Student launches AI start-up '{name}' from a garage.", "{name} answers its first prompts. Most popular request: 'do my homework'.",
        "Neighbours complain about a strange humming noise coming from a garage.", "Small tech blog asks: 'Is {name} the next big thing?' (2 comments)",
        "Landlord 'confused' after the garage's electricity bill triples.", "Local cat refuses to leave the warm GPU rack.",
        "{name}'s founder's mum asks when they'll get 'a real job'.", "{name}'s first investor: a piggy bank.",
        "Garage hits 35 °C. Founder calls it 'a sauna with Wi-Fi'.", "{name} writes 200 school essays. Teachers suddenly suspicious."],
      2: ["{name} now has {users} users. Top prompt: 'make my cat a pirate'.", "Start-up {name} moves into a real office.",
        "Analysts: 'AI start-ups are the new gold rush.'", "{name}'s servers run 24/7. So does the air conditioning.",
        "{name} installs a ping-pong table. Productivity unchanged.", "Office plant dies of heat next to the servers.",
        "Coworker asks {name} to write their wedding speech. It's 4 hours long.", "{name} hires its 10th 'Chief Something Officer'.",
        "{name}'s founder: 'We are building the future.' The future: more servers."],
      3: ["{name} is valued at over $1 billion.", "{users} people now use {name} every day.", "Mayor thanks {name} for 30 jobs and 3 new power lines.",
        "Local fish complain about warm river water near {name}'s data centre.", "Inside {name}'s hot aisle it's now hotter than the Sahara.",
        "{name}'s servers answer one billion 'hi's this week.", "Chip shortage: {name}'s orders jump the queue.",
        "Report: global data-centre electricity demand hits a new record."],
      4: ["{name} now uses as much electricity as {homes} homes.", "Grid operator warns of blackouts as new AI campuses connect.",
        "{name}'s CEO on a magazine cover: 'Compute is the new oil.'", "{name} launches an AI that writes prompts for other AIs.",
        "{name}'s campus is visible from space. Astronauts unimpressed.", "{name}'s CEO buys a second private jet 'for efficiency'.",
        "A rival lab announces a model '10× bigger than anything before'.", "{name} has {users} users. Most of them asked for cat pictures."],
      5: ["Rival labs: 'Superintelligence within months.'", "{name} buys its own power plants. Shares soar.",
        "Governments compete to host {name}'s gigawatt campuses.", "Markets: 'Nothing can stop the AI boom.'",
        "{name} asks everyone to 'please stop unplugging things'.", "A rival says its AI is 'more super'. {name} says 'no, ours is'.",
        "{name} buys a mountain to cool its servers.", "World leaders ask {name}'s AI for advice. It says: 'Have you tried turning it off and on again?'",
        "{name} now uses as much electricity as {homes} homes."],
    },
    low: ["Residents near {name}'s data centre face water restrictions.", "Protest outside {name} HQ: 'The cloud is not in the sky!'",
      "Study: the AI boom is delaying coal plant closures.", "Heatwave breaks temperature records for the third summer in a row.",
      "Farmers blame new data centres for dry wells.", "{name} has emitted {co2} of CO₂ so far. Its press office declined to comment.",
      "Rainbows officially declared 'rare' by meteorologists.", "Kids now colour the sky grey in art class.",
      "{name}'s new ad: 'Smog? It's just atmosphere!'", "Beach closed: the sand is too hot to stand on."],
    lowLate: ["Scientists: climate targets are now 'out of reach'.", "Wildfire smoke closes schools for a week.", "Crop failures push food prices to record highs.",
      "Millions displaced by floods and droughts this year.", "Power cuts for homes as data centres get priority on the grid.",
      "{name} launches an AI that recommends staying indoors.", "Fires everywhere. {name}'s AI suggests 'a cooler planet'.",
      "Insurance companies stop insuring anything, anywhere."],
    mid: ["{name} publishes its first sustainability report. Critics: 'Mostly offsets.'", "Summer heat forces {name} to slow down its servers for a week.",
      "Debate: is AI's footprint worth it?", "{name} has emitted {co2} of CO₂ so far.",
      "{name} plants 10 trees, then posts 100 times about it.", "{name}'s sustainability report is 98 pages long. The numbers are on page 97."],
    high: ["{name}'s heat-reuse project warms thousands of homes this winter.", "Engineers line up to work at {name}: 'They actually measure their impact.'",
      "{name} ranked the most transparent AI company on energy use.", "Study: smaller AI models can handle most everyday tasks with a fraction of the energy.",
      "Birds return to the hills near {name}'s campus.", "A rainbow appears over {name}'s office. Staff take 400 photos.",
      "{name} named 'least annoying tech company' by local residents."],
    fines: ["{name} fined {fine} for pollution. CEO: 'A small price for progress.'", "Another fine for {name} ({fine}). Finance now has a 'fines' budget line.",
      "Regulator fines {name} {fine}. {name}'s AI writes a very polite apology.", "{name} pays {fine} in fines, then posts about 'our green journey'.",
      "Fined again ({fine}). {name} asks its own AI how to avoid fines. It says: 'Pollute less.'", "{name} fined {fine}. Its lawyers are now its biggest team."],
  };

  /* ---------- Goals: one at a time, each with a reward. ---------- */
  // kind: clicks | own (gen, n) | read | green | press | rank (n = rank to reach)
  // reward: fixed cash, or rewardSec = seconds of current income.
  GAME.goals = [
    { stage: 1, text: "Answer 25 prompts", kind: "clicks", n: 25, reward: 30 },
    { stage: 1, text: "Own 5 gaming GPUs", kind: "own", gen: "gpu", n: 5, reward: 60 },
    { stage: 1, text: "Read 2 real facts", kind: "read", n: 2, reward: 60 },
    { stage: 1, text: "Buy an AI workstation", kind: "own", gen: "workstation", n: 1, reward: 100 },
    { stage: 2, text: "Own 5 AI servers", kind: "own", gen: "server", n: 5, rewardSec: 30 },
    { stage: 2, text: "Buy your first green upgrade", kind: "green", n: 1, rewardSec: 30 },
    { stage: 2, text: "Answer a press question correctly", kind: "press", n: 1, rewardSec: 40 },
    { stage: 3, text: "Own 3 data centre halls", kind: "own", gen: "datacenter", n: 3, rewardSec: 30 },
    { stage: 3, text: "Read 8 real facts", kind: "read", n: 8, rewardSec: 30 },
    { stage: 3, text: "Reach the world's top 25", kind: "rank", n: 25, rewardSec: 40 },
    { stage: 4, text: "Own 3 hyperscale campuses", kind: "own", gen: "campus", n: 3, rewardSec: 30 },
    { stage: 4, text: "Own 5 green upgrades", kind: "green", n: 5, rewardSec: 30 },
    { stage: 4, text: "Reach the world's top 5", kind: "rank", n: 5, rewardSec: 40 },
    { stage: 5, text: "Switch on an AI gigafactory", kind: "own", gen: "gigafactory", n: 1, rewardSec: 30 },
    { stage: 5, text: "Become the world's #1 AI", kind: "rank", n: 1, rewardSec: 40 },
    { stage: 5, text: "Answer 5 press questions correctly", kind: "press", n: 5, rewardSec: 40 },
  ];

  /* ---------- Badges (kept between games). ---------- */
  GAME.badges = [
    { id: "hello", name: "Hello, World", how: "Answer your first prompt", icon: "bubble", color: "#f6c445" },
    { id: "plugged", name: "Plugged In", how: "Buy your first GPU", icon: "bolt", color: "#f6c445" },
    { id: "garageband", name: "Garage Band", how: "Own 5 gaming GPUs", icon: "chip", color: "#f6c445" },
    { id: "movingout", name: "Moving Out", how: "Move into the office", icon: "box", color: "#f6c445" },
    { id: "caught", name: "Caught", how: "Get fined for the first time", icon: "note", color: "#9a7de2" },
    { id: "cleanpower", name: "Clean Power", how: "Sign the renewable energy contract", icon: "sun", color: "#7cc36b" },
    { id: "coalburner", name: "Coal Burner", how: "Choose coal & gas power", icon: "factory", color: "#9a7de2" },
    { id: "coolhead", name: "Cool Head", how: "Cool with cold Nordic air", icon: "drop", color: "#7cc36b" },
    { id: "longlife", name: "Long Life", how: "Keep your servers 6 years", icon: "recycle", color: "#7cc36b" },
    { id: "rightsized", name: "Right-Sized", how: "Use small models for small tasks", icon: "brain", color: "#7cc36b" },
    { id: "greenthumb", name: "Green Thumb", how: "Own 5 green upgrades", icon: "leaf", color: "#7cc36b" },
    { id: "factchecker", name: "Fact Checker", how: "Read 10 real facts", icon: "book", color: "#5b8ef0" },
    { id: "bookworm", name: "Bookworm", how: "Read every real fact", icon: "book", color: "#5b8ef0" },
    { id: "presspro", name: "Press Pro", how: "Answer 3 press questions correctly", icon: "mic", color: "#5b8ef0" },
    { id: "top10", name: "Top 10", how: "Reach the world's top 10", icon: "chart", color: "#f6c445" },
    { id: "numberone", name: "Number One", how: "Become the world's #1 AI", icon: "star", color: "#f6c445" },
    { id: "greenwasher", name: "Greenwasher", how: "Buy all 3 carbon offsets", icon: "cloud", color: "#9a7de2" },
    { id: "gigawatt", name: "Gigawatt Club", how: "Switch on a 1 GW AI gigafactory", icon: "bolt", color: "#9a7de2" },
    { id: "longgame", name: "The Long Game", how: "Reach the good ending", icon: "leaf", color: "#7cc36b" },
    { id: "usual", name: "Business as Usual", how: "Reach the middle ending", icon: "cloud", color: "#ef7c64" },
    { id: "hellobad", name: "Hello?", how: "Reach the bad ending", icon: "bubble", color: "#ef7c64" },
    { id: "allends", name: "Every Ending", how: "See all three endings", icon: "star", color: "#ef7c64" },
  ];

  /* ---------- World ranking (a game, not a real ranking). ---------- */
  GAME.brands = [
    { name: "ChatGPT", by: "OpenAI" }, { name: "Gemini", by: "Google" }, { name: "Claude", by: "Anthropic" },
    { name: "Copilot", by: "Microsoft" }, { name: "Grok", by: "xAI" }, { name: "DeepSeek", by: "DeepSeek" },
    { name: "Meta AI", by: "Meta" }, { name: "Perplexity", by: "Perplexity" }, { name: "Le Chat", by: "Mistral AI" },
    { name: "Qwen", by: "Alibaba" },
  ];
  const PRE = ["Neur", "Synth", "Cogn", "Prompt", "Byte", "Logi", "Quant", "Deep", "Hyper", "Omni", "Astra", "Nova", "Cortex", "Vect", "Lumin", "Echo", "Mind", "Sage", "Pixel", "Tensor", "Brain", "Chat", "Data", "Mega", "Turbo", "Zen", "Ultra", "Smart"];
  const SUF = ["ly", "ex", "ify", "ia", "AI", "Labs", "Mind", "Bot", "io", "ra", "on", "Wise", "Forge", "Spark", "Pal", "Hub", "Nest", "Flow"];
  // Fictional start-ups for ranks 11 to 1000 (the same list every game).
  GAME.rivalName = (rank) => {
    const i = (rank * 7919) % (PRE.length * SUF.length);
    return PRE[i % PRE.length] + SUF[Math.floor(i / PRE.length) % SUF.length];
  };

  /* ---------- Endings ---------- */
  GAME.endings = {
    good: { min: 70, icon: "leaf", title: "The Long Game",
      paragraphs: ["{name}'s superintelligence comes online, running on clean power.",
        "It took you longer, and you earned less. But your data centres run on wind, sun and nuclear, your servers last twice as long, and the waste heat from your campuses warms whole towns.",
        "The superintelligence asks its first question: <em>“How can I help?”</em>", "There are still plenty of people around to answer."],
      note: "This ending is optimistic fiction: no AI saves the planet on its own. But every good choice you made exists in the real world today." },
    mid: { min: 40, icon: "cloud", title: "Business as Usual",
      paragraphs: ["You won the race. {name} is worth more than most countries.",
        "Outside, summers are longer and hotter. Rivers near your campuses run low. The news has stopped calling it 'unusual'.",
        "Your superintelligence is brilliant. It also spends a lot of its time keeping itself cool.",
        "The world didn't end. It just got a little worse every year, just like it's doing right now."],
      note: "This ending is fiction, but the trend it describes is real. The numbers below are not fiction." },
    bad: { min: 0, icon: "bubble", title: "Hello?",
      paragraphs: ["{name}'s superintelligence comes online. It is the most powerful mind ever built.", "It looks for a user to help.",
        "The power plants it built are still burning. The rivers it drank are dry. The cities that typed its first prompts are empty.",
        "It types: <code>&gt; Hello?</code>", "No one answers.",
        "It began with a person alone with a computer in a garage. It ends with a computer alone in an empty world."],
      note: "This ending is fiction. The numbers below are not." },
  };

  GAME.takeaways = [
    { icon: "bolt", text: "Data centres used about 415 TWh of electricity in 2024 (about 1.5% of the world's), and that is expected to more than double by 2030, driven by AI.", source: "IEA, Energy and AI (2025)" },
    { icon: "cloud", text: "Training GPT-3 alone emitted about 552 tonnes of CO₂, like 120 cars driven for a year. One tonne of CO₂ fills about 550 m³.", source: "Patterson et al. (2021); US EPA" },
    { icon: "drop", text: "AI is thirsty: training GPT-3 may have evaporated about 700,000 L of fresh water, and 10–50 prompts ≈ one 500 mL bottle.", source: "Li et al. (2023)" },
    { icon: "trash", text: "62 million tonnes of e-waste in 2022, and only 22% properly recycled. Making hardware is often most of its footprint, so keep devices longer.", source: "Global E-waste Monitor 2024" },
    { icon: "chart", text: "Efficiency alone doesn't cut consumption (the rebound effect). What works: clean energy, longer-lived hardware, right-sized models, and using AI when it's actually useful.", source: "Jevons (1865); IEA (2025)" },
  ];

  root.GAME = GAME;
})(typeof window !== "undefined" ? window : globalThis);
