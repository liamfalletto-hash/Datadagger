/* Art kit: isometric helpers, icons, badges, shop pictures, landscape and people. */
(function (root) {
  const INK = "#2b2433";
  const f1 = (n) => (+n).toFixed(1);

  function shade(hex, f) {
    const n = parseInt(hex.slice(1), 16);
    const ch = (v) => Math.max(0, Math.min(255, Math.round(v * f)));
    return "#" + ((1 << 24) | (ch(n >> 16) << 16) | (ch((n >> 8) & 255) << 8) | ch(n & 255)).toString(16).slice(1);
  }
  function mix(a, b, t) {
    t = Math.max(0, Math.min(1, t));
    const p = (c) => [1, 3, 5].map((i) => parseInt(c.slice(i, i + 2), 16));
    const A = p(a), B = p(b);
    return "#" + A.map((v, i) => Math.round(v + (B[i] - v) * t).toString(16).padStart(2, "0")).join("");
  }
  const esc = (s) => String(s).replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));

  // Isometric projection: x runs down-right, y runs down-left, z runs up.
  function makeIso(U, CX, CY) {
    const C = 0.8660254;
    const P = (x, y, z = 0) => [CX + (x - y) * U * C, CY + (x + y) * U * 0.5 - z * U];
    const pts = (list) => list.map((p) => P(p[0], p[1], p[2]).map(f1).join(",")).join(" ");
    const poly = (list, fill, extra = "") => `<polygon points="${pts(list)}" fill="${fill}" ${extra}/>`;
    const box = (x0, y0, z0, x1, y1, z1, col, o = {}) =>
      poly([[x0, y1, z0], [x1, y1, z0], [x1, y1, z1], [x0, y1, z1]], o.left || shade(col, 0.88)) +
      poly([[x1, y0, z0], [x1, y1, z0], [x1, y1, z1], [x1, y0, z1]], o.right || shade(col, 0.74)) +
      poly([[x0, y0, z1], [x1, y0, z1], [x1, y1, z1], [x0, y1, z1]], o.top || col);
    const m = (a, b, c, d, e, f) => `matrix(${[a, b, c, d].map((v) => v.toFixed(3)).join(",")},${f1(e)},${f1(f)})`;
    // Flat drawing on a surface in room units: u = reading direction, w = downward.
    const onX = (c, y0, z0, inner) => { const [e, f] = P(c, y0, z0); return `<g class="ns" transform="${m(U * C, -U * 0.5, 0, U, e, f)}">${inner}</g>`; };
    const onY = (c, x0, z0, inner) => { const [e, f] = P(x0, c, z0); return `<g class="ns" transform="${m(U * C, U * 0.5, 0, U, e, f)}">${inner}</g>`; };
    const onZ = (c, inner) => { const [e, f] = P(0, 0, c); return `<g class="ns" transform="${m(U * C, U * 0.5, -U * C, U * 0.5, e, f)}">${inner}</g>`; };
    const circ = (x, y, z, r, fill) => { const [sx, sy] = P(x, y, z); return `<ellipse cx="${f1(sx)}" cy="${f1(sy)}" rx="${f1(r * U * 1.2247)}" ry="${f1(r * U * 0.7071)}" fill="${fill}"/>`; };
    const cyl = (x, y, z0, z1, r, side, top) => {
      const [bx, by] = P(x, y, z0), [tx, ty] = P(x, y, z1), rx = r * U * 1.2247, ry = r * U * 0.7071;
      return `<path d="M${f1(bx - rx)} ${f1(by)}L${f1(tx - rx)} ${f1(ty)}L${f1(tx + rx)} ${f1(ty)}L${f1(bx + rx)} ${f1(by)}A${f1(rx)} ${f1(ry)} 0 0 1 ${f1(bx - rx)} ${f1(by)}Z" fill="${side}"/><ellipse cx="${f1(tx)}" cy="${f1(ty)}" rx="${f1(rx)}" ry="${f1(ry)}" fill="${top}"/>`;
    };
    return { P, poly, box, onX, onY, onZ, circ, cyl, U };
  }
  const txt = (u, w, size, str, extra = "") =>
    `<text transform="translate(${u} ${w}) scale(0.01)" font-size="${size * 100}" text-anchor="middle" stroke="none" fill="${INK}" ${extra}>${esc(str)}</text>`;

  /* ---------- Icons (24×24) ---------- */
  const PATHS = {
    cash: `<rect x="2" y="6" width="20" height="12" rx="2.5" fill="#86cf85"/><circle cx="12" cy="12" r="3" fill="#dff3d8"/>`,
    users: `<circle cx="9" cy="8.5" r="3.5" fill="#ffd9b8"/><path d="M2.8 20c.4-3.6 3-5.8 6.2-5.8s5.8 2.2 6.2 5.8z" fill="#7aa7f5"/><circle cx="17" cy="9" r="2.6" fill="#ffd9b8"/><path d="M16 14.3c2.8-.3 5 1.6 5.3 5" fill="none"/>`,
    bolt: `<path d="M13.5 2 4.5 13.5h6.5L9.5 22l10-12.5H13z" fill="#f6c445"/>`,
    clock: `<circle cx="12" cy="12" r="9" fill="#fff"/><path d="M12 7v5l3 2" fill="none"/>`,
    chip: `<rect x="5" y="5" width="14" height="14" rx="2.5" fill="#dce7ff"/><rect x="9" y="9" width="6" height="6" rx="1" fill="#5b8ef0"/><path d="M9 2v3M15 2v3M9 19v3M15 19v3M2 9h3M2 15h3M19 9h3M19 15h3" fill="none"/>`,
    up: `<path d="M12 3 20 12h-4.5v8.5h-7V12H4z" fill="#fff4cc"/>`,
    book: `<path d="M3 5.5C6 4 9.5 4.3 12 6.3 14.5 4.3 18 4 21 5.5v13c-3-1.5-6.5-1.2-9 .8-2.5-2-6-2.3-9-.8z" fill="#fff"/><path d="M12 6.3v13" fill="none"/>`,
    medal: `<path d="M7 2h4l2 5H9zM17 2h-4l-2 5h4z" fill="#ef7c64"/><circle cx="12" cy="14.5" r="6.5" fill="#f6c445"/><path d="m12 11.2 1 2.1 2.3.3-1.7 1.6.4 2.3-2-1.1-2 1.1.4-2.3-1.7-1.6 2.3-.3z" fill="#fff"/>`,
    lock: `<rect x="5" y="10.5" width="14" height="10.5" rx="2.5" fill="#cbc5d0"/><path d="M8 10.5V8a4 4 0 0 1 8 0v2.5" fill="none"/>`,
    star: `<path d="m12 2.8 2.8 5.7 6.3.9-4.6 4.4 1.1 6.2-5.6-3-5.6 3 1.1-6.2-4.6-4.4 6.3-.9z" fill="#f6c445"/>`,
    starOff: `<path d="m12 2.8 2.8 5.7 6.3.9-4.6 4.4 1.1 6.2-5.6-3-5.6 3 1.1-6.2-4.6-4.4 6.3-.9z" fill="#ddd7e1"/>`,
    mic: `<rect x="8.5" y="2.5" width="7" height="11" rx="3.5" fill="#5f6675"/><path d="M5 11a7 7 0 0 0 14 0M12 18v3.5M8.5 21.5h7" fill="none"/>`,
    leaf: `<path d="M4.5 19.5C4 10 10 4.5 20 4.5c.5 9.5-5.5 15.5-15.5 15z" fill="#7cc36b"/><path d="M4.5 19.5 13 11" fill="none"/>`,
    drop: `<path d="M12 2.5s6.5 7.2 6.5 11.5a6.5 6.5 0 0 1-13 0C5.5 9.7 12 2.5 12 2.5z" fill="#7cc6ef"/>`,
    cloud: `<path d="M7 19h10.5a4.2 4.2 0 0 0 .6-8.4A6.3 6.3 0 0 0 6.1 10 4.5 4.5 0 0 0 7 19z" fill="#d9d4de"/>`,
    trash: `<path d="M4 7h16M9 7V4h6v3" fill="none"/><path d="M6 7l1.2 13h9.6L18 7z" fill="#cbc5d0"/>`,
    box: `<path d="M3 7.5 12 3l9 4.5v9L12 21l-9-4.5z" fill="#d8aa69"/><path d="M3 7.5 12 12l9-4.5M12 12v9" fill="none"/>`,
    bubble: `<path d="M3.5 4.5h17v11h-9l-5 4v-4h-3z" fill="#fff"/>`,
    note: `<rect x="5" y="3" width="14" height="18" rx="2" fill="#fff"/><path d="M8 8h8M8 12h8M8 16h5" fill="none"/>`,
    flame: `<path d="M12 21c-4 0-6.5-2.7-6.5-6.2 0-3.7 3-5.4 3.5-9.3 2.7 1.6 3.5 4 3.3 5.6 1-.7 1.8-2 2-3.4 2 1.6 4.2 4.1 4.2 7.1 0 3.5-2.5 6.2-6.5 6.2z" fill="#ef7c64"/>`,
    flask: `<path d="M9 3h6M10 3v6l-5 9a2 2 0 0 0 1.8 3h10.4a2 2 0 0 0 1.8-3l-5-9V3" fill="#dff3df"/>`,
    garage: `<path d="M3 10 12 4l9 6v10H3z" fill="#f1e7d4"/><path d="M6.5 20v-7h11v7M6.5 15.5h11M6.5 18h11" fill="none"/>`,
    office: `<rect x="5" y="3" width="14" height="18" rx="1.5" fill="#dce7ff"/><path d="M8.5 7h2M13.5 7h2M8.5 11h2M13.5 11h2M8.5 15h2M13.5 15h2M10.5 21v-3h3v3" fill="none"/>`,
    server: `<rect x="4" y="3" width="16" height="6" rx="1.5" fill="#cbd3dc"/><rect x="4" y="11" width="16" height="6" rx="1.5" fill="#cbd3dc"/><path d="M7 6h5M7 14h5M4 20.5h16" fill="none"/><circle cx="16.5" cy="6" r="1" fill="#5cbf63"/><circle cx="16.5" cy="14" r="1" fill="#5cbf63"/>`,
    factory: `<path d="M3 21V11l5 3v-3l5 3V6h4v15z" fill="#cbc5d0"/><path d="M14 9h2" fill="none"/>`,
    globe: `<circle cx="12" cy="12" r="9" fill="#7cc6ef"/><path d="M6 8c2-1 4 0 4 2s-2 2-1 4 2 2 1 4c-3-1-5-4-5-7 0-1 .4-2 1-3zM14 5c2 .5 4 2 5 4-1 1-3 1-3 3s2 2 1 4c-1 1-3 0-3-2s-2-3-1-5 0-3 1-4z" fill="#7cc36b"/>`,
    phone: `<rect x="7" y="2.5" width="10" height="19" rx="2.5" fill="#dce7ff"/><path d="M10.5 18.5h3" fill="none"/>`,
    brain: `<path d="M11.5 4.5a3 3 0 0 0-5 2 3 3 0 0 0-2 5 3 3 0 0 0 2 5 3 3 0 0 0 5 2zM12.5 4.5a3 3 0 0 1 5 2 3 3 0 0 1 2 5 3 3 0 0 1-2 5 3 3 0 0 1-5 2z" fill="#ffc6d0"/>`,
    plug: `<path d="M9 2v5M15 2v5M12 17v5" fill="none"/><path d="M6 7h12v4a6 6 0 0 1-12 0z" fill="#cbd3dc"/>`,
    image: `<rect x="3" y="4" width="18" height="16" rx="2" fill="#dce7ff"/><circle cx="9" cy="9.5" r="2" fill="#f6c445"/><path d="M3 18l6-5 4 3 3-2 5 4v2H3z" fill="#7cc36b"/>`,
    film: `<rect x="3" y="5" width="18" height="14" rx="2" fill="#5f6675"/><path d="M3 9h18M3 15h18" fill="none"/>`,
    robot: `<rect x="5" y="8" width="14" height="11" rx="3" fill="#cbd3dc"/><circle cx="9.5" cy="13" r="1.5" fill="#2b2433"/><circle cx="14.5" cy="13" r="1.5" fill="#2b2433"/><path d="M12 8V4M10 4h4" fill="none"/>`,
    flag: `<path d="M5 21V3" fill="none"/><path d="M5 4h12l-2.5 4L17 12H5z" fill="#ef7c64"/>`,
    sun: `<circle cx="12" cy="12" r="4.5" fill="#f6c445"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M5 19l2-2M17 7l2-2" fill="none"/>`,
    bulb: `<path d="M8 14a6 6 0 1 1 8 0c-1 1-1.5 2-1.5 3h-5c0-1-.5-2-1.5-3z" fill="#fff4cc"/><path d="M9.5 20h5" fill="none"/>`,
    recycle: `<path d="M20 12a8 8 0 0 1-14 5.3M4 12a8 8 0 0 1 14-5.3" fill="none"/><path d="M18 3v4h-4M6 21v-4h4" fill="none"/>`,
    house: `<path d="M3 11 12 4l9 7v9H3z" fill="#f4ead8"/><rect x="10" y="14" width="4" height="6" fill="#d39b5e"/>`,
    chart: `<path d="M4 4v16h16" fill="none"/><path d="M7 16l4-5 3 3 5-7" fill="none"/>`,
    trophy: `<path d="M7 4h10v5a5 5 0 0 1-10 0z" fill="#f6c445"/><path d="M7 6H4a3 3 0 0 0 3 4M17 6h3a3 3 0 0 1-3 4M12 14v4M8 21h8" fill="none"/>`,
  };
  const icon = (name) => `<svg class="i" viewBox="0 0 24 24" aria-hidden="true">${PATHS[name] || PATHS.star}</svg>`;

  function medal(b, earned) {
    const fill = earned ? b.color : "#d9d4de", rib = earned ? "#ef7c64" : "#c4bdc9";
    const face = earned ? `<svg x="20" y="18" width="24" height="24" viewBox="0 0 24 24">${PATHS[b.icon]}</svg>`
      : `<text x="32" y="39" text-anchor="middle" font-family="Fredoka, sans-serif" font-weight="700" font-size="22" fill="#fff" stroke="none">?</text>`;
    return `<svg viewBox="0 0 64 74" aria-hidden="true"><g stroke="${INK}" stroke-width="2.4" stroke-linejoin="round"><path d="M20 42 13 70l9-4 6 7 5-29z" fill="${rib}"/><path d="M44 42l7 28-9-4-6 7-5-29z" fill="${rib}"/><circle cx="32" cy="30" r="24" fill="${fill}"/><circle cx="32" cy="30" r="17.5" fill="none" stroke="#fff" stroke-width="2.2" stroke-dasharray="3 4" opacity=".85"/>${face}</g></svg>`;
  }

  /* ---------- Shop pictures ---------- */
  function thumb(draw, U, CX, CY) {
    return `<svg viewBox="0 0 100 80" aria-hidden="true"><g stroke="${INK}" stroke-width="2.2" stroke-linejoin="round" stroke-linecap="round">${draw(makeIso(U, CX, CY))}</g></svg>`;
  }
  const DARK = { top: "#454d5e", left: "#373e4c", right: "#252a35" };
  const ART = {
    gpu: thumb((I) => I.box(0, 0, 0, 1.5, 0.8, 0.24, "#353b48", { top: "#4c5466" }) + I.circ(0.42, 0.4, 0.24, 0.24, "#1f232c") + I.circ(1.06, 0.4, 0.24, 0.24, "#1f232c") + I.box(1.5, 0, 0, 1.58, 0.8, 0.46, "#c9d0d7"), 28, 41, 27),
    workstation: thumb((I) => I.box(0, 0, 0, 0.9, 0.5, 1.2, "#2f3542", DARK) + I.onY(0.5, 0.1, 1.1, `<rect x="0" y="0" width="0.66" height="0.95" rx="0.04" fill="#8e7cf0"/><circle cx="0.33" cy="0.32" r="0.17" fill="#c4b8ff"/><circle cx="0.33" cy="0.7" r="0.13" fill="#c4b8ff"/>`), 30, 46, 50),
    server: thumb((I) => I.box(0, 0, 0, 1.6, 1.1, 0.34, "#aab3bc", { top: "#c9d0d7" }) + I.onX(1.6, 1.1, 0.34, `<rect x="0.1" y="0.08" width="0.4" height="0.16" fill="#7d8792"/><rect x="0.58" y="0.08" width="0.4" height="0.16" fill="#7d8792"/><circle cx="0.98" cy="0.17" r="0.04" fill="#5cbf63"/>`), 26, 44, 30),
    cluster: thumb((I) => I.box(0, 0, 0, 0.8, 0.9, 1.6, "#2f3542", DARK) + I.onY(0.9, 0, 1.6, [0.2, 0.45, 0.7, 0.95, 1.2].map((w) => `<line x1="0.1" y1="${w}" x2="0.7" y2="${w}" stroke="#7dff8a" stroke-width="2"/>`).join("")), 26, 52, 54),
    datacenter: thumb((I) => I.box(0, 0, 0, 1.9, 1.3, 0.62, "#c9d0d7", { top: "#e3e8ec" }) + I.box(0.3, 0.3, 0.62, 0.8, 0.8, 0.8, "#9aa4ae") + I.box(1.1, 0.3, 0.62, 1.6, 0.8, 0.8, "#9aa4ae") + I.onY(1.3, 0.2, 0.62, `<rect x="0.1" y="0.2" width="0.3" height="0.42" fill="#5b8ef0"/><rect x="0.6" y="0.15" width="1" height="0.2" fill="#dce7ff"/>`), 24, 46, 34),
    campus: thumb((I) => I.box(-0.6, -0.6, -0.1, 2.6, 2.4, 0, "#8bcb72", { top: "#8bcb72" }) + I.box(0, 0, 0, 1, 0.8, 0.5, "#c9d0d7") + I.box(1.4, 0, 0, 2.4, 0.8, 0.5, "#c9d0d7") + I.box(0, 1.2, 0, 1, 2, 0.5, "#c9d0d7") + I.box(1.4, 1.2, 0, 2.4, 2, 0.5, "#c9d0d7"), 18, 50, 28),
    gigafactory: thumb((I) => I.box(0, 0, 0, 2, 1.2, 0.7, "#b9c1c9", { top: "#d6dce2" }) + I.cyl(2.5, 0.4, 0, 1.2, 0.35, "#d8dde2", "#eef1f4") + I.box(0.3, 0.2, 0.7, 1.7, 0.9, 0.85, "#f6c445"), 22, 44, 36),
  };

  /* ---------- Landscape around the building ---------- */
  const cloud = (x, y, k, dx, dur, col) =>
    `<g stroke="none" fill="${col}"><g transform="translate(${x} ${y}) scale(${k})"><circle cx="-26" cy="0" r="17"/><circle cx="-4" cy="-12" r="23"/><circle cx="22" cy="-3" r="18"/><circle cx="40" cy="6" r="11"/><rect x="-42" y="0" width="90" height="17" rx="8.5"/></g><animateTransform attributeName="transform" type="translate" values="0 0;${dx} 0;0 0" dur="${dur}s" repeatCount="indefinite"/></g>`;

  const BIOMES = {
    grass: { ground: "#8fcf74", dry: "#c9b26e", hill1: "#a9d98c", hill2: "#79bb62" },
    desert: { ground: "#ecd49a", dry: "#d9b77a", hill1: "#f1dcaa", hill2: "#ddbd80" },
    snow: { ground: "#eef4f7", dry: "#b9b3a8", hill1: "#f7fafc", hill2: "#d8e6ee" },
  };
  function skyColors(p) {
    return { top: mix("#9fd8f2", "#b8977a", p), bottom: mix("#d8f0fa", "#d9b48a", p) };
  }

  // Tree on the ground at iso point (x, y). Pollution dries and then kills it.
  function tree(I, x, y, s, p, kind) {
    const [tx, ty] = I.P(x, y, 0);
    const k = s * 1.0;
    if (kind === "cactus") {
      return `<g transform="translate(${f1(tx)} ${f1(ty)}) scale(${k})"><path d="M-5 0v-38a5 5 0 0 1 10 0V0z" fill="${mix("#6aa857", "#a39a62", p)}"/><path d="M-5 -20h-6a4 4 0 0 1-4-4v-8a3 3 0 0 1 6 0v6h4zM5 -16h6a4 4 0 0 0 4-4v-6a3 3 0 0 0-6 0v4H5z" fill="${mix("#6aa857", "#a39a62", p)}"/></g>`;
    }
    if (p > 0.7) {
      return `<g transform="translate(${f1(tx)} ${f1(ty)}) scale(${k})"><path d="M-3 0v-30h6V0z" fill="#7a5233"/><path d="M0 -26l-12-12M0 -22l11-10M-6 -32l-2-8M5 -29l6-3" fill="none" stroke-width="3"/></g>`;
    }
    if (kind === "pine") {
      const c = mix("#3f8a5a", "#7d7458", p);
      return `<g transform="translate(${f1(tx)} ${f1(ty)}) scale(${k})"><rect x="-3" y="-10" width="6" height="10" fill="#7a5233"/><path d="M0 -58 16 -26h-32z M0 -44 19 -10h-38z" fill="${c}"/><path d="M-8 -30 0 -36 8 -30" fill="none" stroke="#fff" stroke-width="2.5" opacity="${p < 0.3 ? 0.9 : 0}"/></g>`;
    }
    const c1 = mix("#5fae55", "#9b8a4e", p), c2 = mix("#4f9d4d", "#86744a", p), r = 1 - p * 0.35;
    return `<g transform="translate(${f1(tx)} ${f1(ty)}) scale(${k})"><rect x="-3.5" y="-26" width="7" height="26" fill="#7a5233"/><circle cx="-10" cy="${-32 * r}" r="${13 * r}" fill="${c2}"/><circle cx="9" cy="${-34 * r}" r="${14 * r}" fill="${c2}"/><circle cx="0" cy="${-46 * r}" r="${16 * r}" fill="${c1}"/></g>`;
  }

  /* Sky, rainbow, hills and a big iso ground tile. opts: { biome, rainbow, town, smoke } */
  function landscape(I, p, opts = {}) {
    const B = BIOMES[opts.biome || "grass"];
    const sky = skyColors(p), ground = mix(B.ground, B.dry, p);
    let s = `<rect x="-10" y="-10" width="980" height="710" fill="${sky.top}" stroke="none"/><rect x="-10" y="210" width="980" height="480" fill="${sky.bottom}" stroke="none"/>`;
    s += `<circle cx="830" cy="92" r="34" fill="${p > 0.55 ? "#e8714f" : mix("#ffd451", "#f2b35b", p)}"/>`;
    const rainbowOpacity = opts.rainbow ? Math.max(0, 1 - p * 4) : 0;
    if (rainbowOpacity > 0.02) {
      const cols = ["#ef6f6c", "#f5a35c", "#f6d55c", "#7cc36b", "#6fa8e8", "#9a7de2"];
      s += `<g fill="none" stroke-width="10" opacity="${rainbowOpacity.toFixed(2)}" stroke-linecap="butt">` + cols.map((c, i) => { const r = 470 - i * 10; return `<path d="M${480 - r} 470A${r} ${r} 0 0 1 ${480 + r} 470" stroke="${c}"/>`; }).join("") + `</g>`;
    }
    s += cloud(150, 120, 1.0, 18, 26, mix("#ffffff", "#c9b8a6", p)) + cloud(700, 60, 0.8, -16, 31, mix("#ffffff", "#c9b8a6", p)) + cloud(60, 230, 0.7, 12, 23, mix("#ffffff", "#c9b8a6", p));
    if (p < 0.2) s += `<g fill="none" stroke-width="2.2"><path d="M300 80q6-6 12 0q6-6 12 0"/><path d="M335 64q5-5 10 0q5-5 10 0"/><path d="M640 120q6-6 12 0q6-6 12 0"/></g>`;
    // Ground tile (covers the lower half), then hills that hide its far edges.
    s += `<polygon points="${[[-7, -7], [15, -7], [15, 15], [-7, 15]].map(([x, y]) => I.P(x, y, -0.3).map(f1).join(",")).join(" ")}" fill="${ground}" stroke="none"/>`;
    const h1 = mix(B.hill1, B.dry, p * 0.9), h2 = mix(B.hill2, shade(B.dry, 0.9), p * 0.9);
    s += `<path d="M-10 300 C 60 230 140 250 210 285 C 260 230 330 225 380 270 L380 420 L-10 420Z" fill="${h1}" stroke="none"/>`;
    s += `<path d="M580 270 C 640 220 720 230 780 275 C 840 240 910 245 970 290 L970 420 L580 420Z" fill="${h1}" stroke="none"/>`;
    s += `<path d="M-10 300 C 60 230 140 250 210 285 C 260 230 330 225 380 270M580 270 C 640 220 720 230 780 275 C 840 240 910 245 970 290" fill="none" stroke-opacity=".35"/>`;
    s += `<path d="M-10 350 C 80 300 170 320 260 345 C 300 330 340 330 380 345 L380 440 L-10 440Z" fill="${h2}" stroke="none"/>`;
    s += `<path d="M580 345 C 650 315 730 320 800 345 C 860 320 920 325 970 345 L970 440 L580 440Z" fill="${h2}" stroke="none"/>`;
    s += `<path d="M-10 395 C 100 370 260 375 380 390 L380 470 L-10 470Z M580 390 C 700 372 850 372 970 392 L970 470 L580 470Z" fill="${ground}" stroke="none"/>`;
    if (opts.town) {
      const wall = mix("#f4ead8", "#c9bba5", p), roof = mix("#d06a50", "#8f6a55", p);
      s += [[640, 300], [690, 296], [745, 305], [80, 318], [130, 312]].map(([x, y], i) => `<rect x="${x}" y="${y}" width="${34 - i * 2}" height="${26 + (i % 2) * 8}" fill="${wall}"/><path d="M${x - 3} ${y}l${(34 - i * 2) / 2 + 3} -14 ${(34 - i * 2) / 2 + 3} 14z" fill="${roof}"/>`).join("");
    }
    if (opts.smoke) {
      s += `<rect x="860" y="250" width="14" height="70" fill="#9aa4ae"/><rect x="884" y="262" width="12" height="58" fill="#9aa4ae"/>`;
      for (let i = 0; i < 3; i++) s += `<circle cx="${867 + i * 12}" cy="${235 - i * 18}" r="${10 + i * 5}" fill="#8a8178" stroke="none" opacity=".7"><animate attributeName="cy" values="${235 - i * 18};${205 - i * 18};${235 - i * 18}" dur="${4 + i}s" repeatCount="indefinite"/></circle>`;
    }
    return s;
  }
  // Smog over the whole scene.
  const smog = (p) => (p > 0.15 ? `<rect x="-10" y="-10" width="980" height="710" fill="#8a6a4a" opacity="${(Math.min(0.42, (p - 0.15) * 0.55)).toFixed(2)}" stroke="none" pointer-events="none"/>` : "");

  /* ---------- People (seated, facing the desk at +x) ---------- */
  const SKINS = ["#eab68c", "#c98b5e", "#8d5a3b", "#f2c9a0"];
  function seatedBody(ax, ay, o = {}) {
    const top = o.top || "#ef7c64", skin = o.skin || SKINS[0], hair = o.hair || "#3a2a24";
    const glasses = o.glasses ? `<circle cx="7.5" cy="-62" r="5.2" fill="#fff" fill-opacity=".35"/><circle cx="17.6" cy="-60" r="4.5" fill="#fff" fill-opacity=".35"/><path d="M12.7 -61.6 L13.2 -61.3 M2.3 -63 L-8.5 -62" fill="none" stroke-width="2"/>` : "";
    const hairPath = o.long
      ? `<path d="M-18 -50 C-24 -78 -6 -86 7 -82 C16 -80 21 -72 19 -64 C13 -70 8 -70 4 -73 C2 -68 -3 -66 -7 -69 C-9 -60 -12 -52 -18 -50 Z" fill="${hair}"/>`
      : `<path d="M-17 -59 C-21 -76 -7 -85 6 -82 C15 -80 20 -73 19 -65 C14 -71 8 -71 4 -74 C2 -69 -3 -67 -7 -70 C-9 -65 -13 -62 -17 -59 Z" fill="${hair}"/>`;
    return `<g transform="translate(${f1(ax)} ${f1(ay)})"><path d="M-15 -39 C-17 -50 8 -54 13 -43 Z" fill="${shade(top, 0.85)}"/><path d="M-19 6 C-21 -12 -20 -31 -12 -39 C-4 -45 8 -46 15 -41 C21 -33 23 -12 21 6 Z" fill="${top}"/><rect x="-5" y="-50" width="10" height="10" rx="3" fill="${skin}"/><circle cx="1" cy="-63" r="16.5" fill="${skin}"/><circle cx="-12" cy="-61" r="4.3" fill="${skin}"/>${hairPath}<ellipse cx="12" cy="-58" rx="9" ry="11" fill="#bfe6ff" opacity=".28" stroke="none"/>${glasses}<circle cx="8" cy="-61.6" r="1.7" fill="${INK}" stroke="none"/><circle cx="17.8" cy="-59.7" r="1.5" fill="${INK}" stroke="none"/><path d="M9.5 -51.5q4 2.6 8 -0.6" fill="none" stroke-width="2"/></g>`;
  }
  function seatedArms(ax, ay, hands, o = {}) {
    const top = o.top || "#ef7c64", skin = o.skin || SKINS[0];
    const rel = (p) => [f1(p[0] - ax), f1(p[1] - ay)];
    const [hrx, hry] = rel(hands[1]), [hlx, hly] = rel(hands[0]);
    const arm = (d) => `<path d="${d}" fill="none" stroke-width="13"/><path d="${d}" fill="none" stroke="${top}" stroke-width="8"/>`;
    return `<g transform="translate(${f1(ax)} ${f1(ay)})">${arm(`M13 -38Q34 -18 ${hrx} ${hry}`)}<circle cx="${hrx}" cy="${hry}" r="5.5" fill="${skin}"/>${arm(`M-12 -35Q4 -4 ${hlx} ${hly}`)}<circle cx="${hlx}" cy="${hly}" r="5.5" fill="${skin}"/></g>`;
  }

  /* A desk with a seated person, built back to front. The desk spans
   * x0..x0+depth and yMid±len/2; the person sits at x0-0.75 facing +x. */
  function deskUnit(I, x0, yMid, o = {}) {
    const { P, box, onX, onZ } = I;
    const depth = o.depth || 1.4, len = o.len || 2.2, y0 = yMid - len / 2, y1 = yMid + len / 2, h = 1.4;
    const px = x0 - 0.75, chair = o.chair || "#3d5a80", person = o.person || {};
    let s = I.circ(px, yMid, 0.04, 0.38, "#3a3f4b") + box(px - 0.04, yMid - 0.04, 0.05, px + 0.04, yMid + 0.04, 0.84, "#8d97a1");
    s += box(px - 0.77, yMid - 0.43, 0.95, px - 0.57, yMid + 0.43, 2.3, chair, { top: shade(chair, 1.2) }) + box(px - 0.55, yMid - 0.43, 0.84, px + 0.45, yMid + 0.43, 0.98, chair, { top: shade(chair, 1.2) });
    const [ax, ay] = P(px, yMid, 0.98);
    s += seatedBody(ax, ay, person);
    for (const [lx, ly] of [[x0 + 0.12, y0 + 0.12], [x0 + 0.12, y1 - 0.19], [x0 + depth - 0.19, y0 + 0.12], [x0 + depth - 0.19, y1 - 0.19]]) s += box(lx, ly, 0, lx + 0.07, ly + 0.07, h, "#8d97a1");
    s += box(x0, y0, h, x0 + depth, y1, h + 0.1, o.desk || "#f3eee4", o.deskFaces || { left: "#ddd6c8", right: "#c9c1b2" });
    const top = h + 0.1;
    if (o.extras) s += o.extras(top);
    const kx = x0 + 0.35, hands = [P(kx + 0.25, yMid + 0.27, top + 0.07), P(kx + 0.31, yMid - 0.29, top + 0.07)];
    s += box(kx, yMid - 0.55, top, kx + 0.7, yMid + 0.55, top + 0.05, "#4b5262", { top: "#5d6577" });
    s += seatedArms(ax, ay, hands, person);
    if (o.device === "monitor") {
      s += box(kx + 0.85, yMid - 0.05, top, kx + 0.95, yMid + 0.05, top + 0.35, "#8d97a1");
      s += box(kx + 0.82, yMid - 0.7, top + 0.3, kx + 0.9, yMid + 0.7, top + 1.15, "#3a404d", { right: "#5d6577" });
    } else {
      s += box(kx + 0.7, yMid - 0.55, top + 0.05, kx + 0.76, yMid + 0.55, top + 0.83, "#c9cfd8", { right: "#dde2e8", top: "#e9edf1", left: "#b9c0ca" });
      s += onX(kx + 0.76, yMid + 0.55, top + 0.83, `<path d="M0.36 0.47h0.38a0.1 0.1 0 0 0 0.01-0.2 0.15 0.15 0 0 0-0.28-0.04 0.11 0.11 0 0 0-0.11 0.24z" fill="#fff"/>`);
    }
    return s;
  }

  root.AetherArt = { INK, f1, shade, mix, esc, makeIso, txt, PATHS, icon, medal, ART, landscape, smog, tree, cloud, seatedBody, seatedArms, deskUnit, SKINS };
})(window);
