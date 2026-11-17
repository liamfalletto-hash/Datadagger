/* Stage 1: the garage, on a sunny lawn. */
(function (root) {
  const A = root.AetherArt, S = (root.AetherScenes = root.AetherScenes || {});
  const { INK, f1, shade, mix, txt, makeIso, landscape, smog, tree } = A;

  // Cinder-block joints for a wall face (local units, 8 wide × 6 tall).
  const blocks = () => {
    let b = `<g stroke-opacity=".09" stroke-width="1.4">`;
    for (let r = 1; r < 10; r++) b += `<line x1="0" y1="${(r * 0.6).toFixed(2)}" x2="8" y2="${(r * 0.6).toFixed(2)}"/>`;
    for (let r = 0; r < 10; r++) for (let u = r % 2 ? 0.6 : 1.2; u < 8; u += 1.2) b += `<line x1="${u.toFixed(2)}" y1="${(r * 0.6).toFixed(2)}" x2="${u.toFixed(2)}" y2="${(r * 0.6 + 0.6).toFixed(2)}"/>`;
    return b + `</g>`;
  };
  S.blocks = blocks;

  // An 8×8 cut-away room: back-right wall (y=0), back-left wall (x=0), floor.
  S.room = (I, o) => {
    const H = 6;
    let s = I.box(-0.4, -0.4, -0.5, 8, 0, H, o.wall, { left: o.wall, right: shade(o.wall, 0.74), top: o.wallTop });
    s += I.onY(0, 0, H, o.rightDecor || "");
    s += I.box(-0.4, 0, -0.5, 0, 8, H, o.wall, { right: shade(o.wall, 0.92), left: shade(o.wall, 0.74), top: o.wallTop });
    s += I.onX(0, 8, H, o.leftDecor || "");
    s += I.box(0, 0, -0.5, 8, 8, 0, o.floor, { left: shade(o.floor, 0.82), right: shade(o.floor, 0.68) });
    s += I.onZ(0, o.floorDecor || "");
    return s;
  };
  // Framed badges (local units on a wall).
  S.frame = (u, w, col, wood) => `<rect x="${u}" y="${w}" width="0.78" height="0.9" rx="0.04" fill="${wood}"/><rect x="${(u + 0.1).toFixed(2)}" y="${(w + 0.1).toFixed(2)}" width="0.58" height="0.7" fill="#fffaf0"/>` +
    `<path d="M${(u + 0.27).toFixed(2)} ${(w + 0.5).toFixed(2)}l-0.07 0.26 0.09-0.04 0.06 0.07 0.05-0.27zM${(u + 0.51).toFixed(2)} ${(w + 0.5).toFixed(2)}l0.07 0.26-0.09-0.04-0.06 0.07-0.05-0.27z" fill="#ef7c64"/><circle cx="${(u + 0.39).toFixed(2)}" cy="${(w + 0.4).toFixed(2)}" r="0.17" fill="${col}"/>`;
  // Window looking outside (local units on a wall).
  S.window = (id, u, w, wd, ht, p, wood) => {
    const sky = mix("#a6dcf3", "#cfa77c", p), hill = mix("#8bcb72", "#b3a373", p), treeC = mix("#4f9d4d", "#7e6a46", p);
    return `<rect x="${u - 0.18}" y="${w - 0.18}" width="${wd + 0.36}" height="${ht + 0.4}" rx="0.06" fill="${wood}"/><clipPath id="${id}"><rect x="${u}" y="${w}" width="${wd}" height="${ht}"/></clipPath><rect x="${u}" y="${w}" width="${wd}" height="${ht}" fill="${sky}"/>` +
      `<g clip-path="url(#${id})" stroke="none"><circle cx="${u + wd * 0.78}" cy="${w + 0.5}" r="0.26" fill="${p > 0.55 ? "#e8714f" : "#ffd451"}"/><ellipse cx="${u + wd * 0.5}" cy="${w + ht + 0.35}" rx="${wd * 0.75}" ry="0.75" fill="${hill}"/>` +
      `<rect x="${u + wd * 0.27}" y="${w + ht - 0.85}" width="0.1" height="0.55" fill="#7a5233"/><circle cx="${u + wd * 0.29}" cy="${w + ht - 1.0}" r="${0.34 * (1 - p * 0.4)}" fill="${treeC}"/></g>` +
      `<rect x="${u}" y="${w}" width="${wd}" height="${ht}" fill="none"/><rect x="${u + wd / 2 - 0.04}" y="${w}" width="0.08" height="${ht}" fill="${wood}"/><rect x="${u}" y="${w + ht / 2 - 0.04}" width="${wd}" height="0.08" fill="${wood}"/>` +
      `<line x1="${u + 0.15}" y1="${w + ht * 0.4}" x2="${u + 0.55}" y2="${w + 0.2}" stroke="#fff" stroke-opacity=".75" stroke-width="3"/>`;
  };

  S.garage = (st) => {
    const I = makeIso(42, 480, 288);
    const { P, box, onY, onZ, circ, cyl, U } = I;
    const p = st.pollution, WOOD = "#d39b5e", METAL = "#a3acb5", HOODIE = "#ef7c64";
    let s = landscape(I, p, { rainbow: true });

    // Right wall: garage door, wall of fame, electricity meter, pegboard.
    let rw = blocks();
    rw += `<rect x="3.3" y="1.32" width="4.5" height="4.68" fill="#b9c4cc"/><rect x="3.48" y="1.5" width="4.14" height="4.5" fill="#e4ebef"/>`;
    for (let k = 1; k < 8; k++) { const w = (1.5 + k * 0.5625).toFixed(3); rw += `<line x1="3.48" y1="${w}" x2="7.62" y2="${w}" stroke-opacity=".4"/>`; }
    const sky = mix("#a6dcf3", "#cfa77c", p);
    for (let i = 0; i < 4; i++) { const x = 3.7 + i * 0.99; rw += `<rect x="${x.toFixed(2)}" y="2.15" width="0.72" height="0.38" rx="0.04" fill="${sky}"/>`; }
    rw += `<rect x="5.25" y="5.45" width="0.6" height="0.1" rx="0.05" fill="${METAL}"/>`;
    st.badgeColors.slice(0, 4).forEach((c, i) => { rw += S.frame(3.75 + i * 0.95, 0.28, c, WOOD); });
    rw += `<line x1="1.13" y1="0" x2="1.13" y2="2.6" stroke-width="9"/><line x1="1.13" y1="0" x2="1.13" y2="2.6" stroke="${METAL}" stroke-width="4.5"/>`;
    rw += `<rect x="0.68" y="2.55" width="0.9" height="1.12" rx="0.12" fill="#cdd4da"/><circle cx="1.13" cy="2.98" r="0.3" fill="#f1f8fb"/>`;
    rw += `<g><line x1="0.88" y1="2.98" x2="1.38" y2="2.98" stroke-width="2.5"/><animateTransform attributeName="transform" type="rotate" from="0 1.13 2.98" to="360 1.13 2.98" dur="${(8 / (1 + st.powerKw)).toFixed(2)}s" repeatCount="indefinite"/></g>`;
    rw += txt(1.13, 3.52, 0.17, "kWh", `font-family="Fredoka, sans-serif" font-weight="600"`);
    rw += `<rect x="1.9" y="1.75" width="1.3" height="1.65" rx="0.05" fill="#c99a68"/><rect x="2.2" y="2.05" width="0.09" height="0.85" fill="${WOOD}"/><rect x="2.06" y="1.98" width="0.38" height="0.15" rx="0.03" fill="${METAL}"/><rect x="2.62" y="2.15" width="0.08" height="0.75" fill="${METAL}"/><circle cx="2.66" cy="2.08" r="0.12" fill="${METAL}"/>`;
    rw += `<circle cx="2.93" cy="3.02" r="0.17" fill="none" stroke-width="9"/><circle cx="2.93" cy="3.02" r="0.17" fill="none" stroke="#f4c430" stroke-width="4.5"/>`;

    // Left wall: window, cardboard sign with the start-up's name, socket.
    let lw = blocks() + S.window("gWin", 4.9, 1.38, 2.2, 2.24, p, WOOD) + `<rect x="4.58" y="3.74" width="2.84" height="0.14" rx="0.03" fill="${WOOD}"/>`;
    const nm = st.name.toUpperCase(), size = Math.min(0.55, 2.2 / Math.max(4, nm.length) * 1.55);
    lw += `<g transform="rotate(-3 1.9 1.5)"><rect x="0.65" y="0.9" width="2.5" height="1.2" fill="#dcb57f"/>` + txt(1.9, 1.58, size, nm, `font-family="Fredoka, sans-serif" font-weight="700"`) +
      txt(1.9, 1.92, 0.19, "ANSWERS ANYTHING", `font-family="Nunito, sans-serif" font-weight="800" opacity=".7"`) +
      `<rect x="0.52" y="0.82" width="0.42" height="0.14" fill="#f6f1e2" opacity=".9" stroke="none" transform="rotate(-28 0.73 0.89)"/><rect x="2.86" y="0.82" width="0.42" height="0.14" fill="#f6f1e2" opacity=".9" stroke="none" transform="rotate(28 3.07 0.89)"/></g>`;
    lw += `<rect x="3.95" y="5.28" width="0.3" height="0.38" rx="0.05" fill="#fff"/>`;

    // Floor: concrete, rug, oil stains, yellow extension cords.
    const cord = (d) => `<path d="${d}" fill="none" stroke-width="7.5"/><path d="${d}" fill="none" stroke="#f4c430" stroke-width="3.8"/>`;
    let fl = `<g stroke-opacity=".12" stroke-width="1.4"><line x1="4" y1="0" x2="4" y2="8"/><line x1="0" y1="4" x2="8" y2="4"/></g><ellipse cx="6.3" cy="5.9" rx="0.55" ry="0.35" fill="${INK}" opacity=".07" stroke="none"/>`;
    fl += `<rect x="1.15" y="2.15" width="3.95" height="4.1" rx="0.1" fill="#4a8796"/><rect x="1.4" y="2.4" width="3.45" height="3.6" rx="0.06" fill="none" stroke="#f3e6c9" stroke-width="2.2" stroke-dasharray="7 6"/>`;
    fl += cord("M0.06 3.9 C 0.9 3.9 0.7 6.42 2.45 6.44") + cord("M3.15 6.44 C 3.45 6.42 3.3 6.0 3.16 5.84");
    if (st.owned.gpu + st.owned.workstation > 0) fl += cord("M2.45 6.52 C 1.9 6.62 1.45 6.32 1.06 6.25");
    s += S.room(I, { wall: "#efe5d2", wallTop: "#fbf6eb", floor: "#cfcac1", rightDecor: rw, leftDecor: lw, floorDecor: fl });
    s += box(2.45, 6.3, 0, 3.15, 6.58, 0.1, "#f2f0ea");

    // Tyres, then cardboard boxes in front of the door.
    const hole = (x, y, z) => { const [hx, hy] = P(x, y, z); return `<ellipse cx="${f1(hx)}" cy="${f1(hy)}" rx="${f1(0.2 * U * 1.2247)}" ry="${f1(0.2 * U * 0.7071)}" fill="#26222d"/>`; };
    s += cyl(7.05, 0.9, 0, 0.3, 0.48, "#3a3a44", "#4c4c58") + hole(7.05, 0.9, 0.3) + cyl(7.05, 0.9, 0.3, 0.6, 0.48, "#3a3a44", "#4c4c58") + hole(7.05, 0.9, 0.6);
    const labels = ["OLD PCs", "XMAS"], nb = 2 + Math.min(7, Math.ceil(Math.max(0, st.owned.gpu - 16) / 2));
    const slots = [[5.2, 0], [6.05, 0], [6.9, 0], [5.2, 1], [6.05, 1], [6.9, 1], [5.2, 2], [6.05, 2], [6.9, 2]];
    for (let i = 0; i < nb; i++) {
      const [x0, lv] = slots[i], z0 = lv * 0.54;
      s += box(x0, 2.05, z0, x0 + 0.78, 2.77, z0 + 0.52, "#d8aa69") + onZ(z0 + 0.52, `<rect x="${x0}" y="2.36" width="0.78" height="0.1" fill="#ecd3a2" stroke="none"/>`);
      s += onY(2.77, x0, z0 + 0.52, txt(0.39, 0.32, 0.15, labels[i] || "GPU", `font-family="Nunito, sans-serif" font-weight="800" opacity=".75"`));
    }

    // Metal rack: workstations below, GPUs on the two shelves above.
    const fans = (w, h) => [0.27, 0.73].map((f) => { const cx = (w * f).toFixed(3), cy = (h / 2).toFixed(3); return `<circle cx="${cx}" cy="${cy}" r="0.13" fill="#1f232c"/><g><path d="M${cx} ${cy}l0-0.11M${cx} ${cy}l0.095 0.055M${cx} ${cy}l-0.095 0.055" stroke="#8a93a5" stroke-width="2"/><animateTransform attributeName="transform" type="rotate" from="0 ${cx} ${cy}" to="360 ${cx} ${cy}" dur="0.8s" repeatCount="indefinite"/></g>`; }).join("");
    const gpu = (x0, y0, z0) => { const x1 = x0 + 0.62, y1 = y0 + 0.16, z1 = z0 + 0.48; return box(x0, y0, z0, x1, y1, z1, "#353b48", { top: "#4c5466", left: "#3c4352", right: "#272c37" }) + onY(y1, x0, z1, fans(0.62, 0.48)) + onZ(z1, `<line x1="${(x0 + 0.06).toFixed(2)}" y1="${(y0 + 0.08).toFixed(2)}" x2="${(x1 - 0.06).toFixed(2)}" y2="${(y0 + 0.08).toFixed(2)}" stroke="#7dff8a" stroke-width="2"/>`); };
    const tower = (x0, y0, z0) => { const x1 = x0 + 0.78, y1 = y0 + 0.48, z1 = z0 + 1.0; return box(x0, y0, z0, x1, y1, z1, "#2f3542", { top: "#454d5e", left: "#373e4c", right: "#252a35" }) + onY(y1, x0 + 0.08, z1 - 0.08, `<rect x="0" y="0" width="0.6" height="0.82" rx="0.04" fill="#8e7cf0"/><circle cx="0.3" cy="0.3" r="0.15" fill="#c4b8ff"/><circle cx="0.3" cy="0.62" r="0.11" fill="#c4b8ff"/>`); };
    const R0 = 0.12, R1 = 1.04, Y0 = 4.55, Y1 = 7.75, post = (x, y) => box(x, y, 0, x + 0.07, y + 0.07, 3.35, METAL, { top: "#c6cdd4" });
    s += post(R0, Y0) + post(R0, Y1 - 0.07);
    [0.12, 1.32, 2.52].forEach((L, li) => {
      s += box(R0, Y0, L, R1, Y1, L + 0.06, "#bcc4cc", { top: "#d6dce2" });
      if (li === 0) for (let i = 0; i < Math.min(4, st.owned.workstation); i++) s += tower(0.2, Y0 + 0.18 + i * 0.78, L + 0.06);
      else for (let i = 0; i < Math.min(8, st.owned.gpu - (li - 1) * 8); i++) s += gpu(0.28, Y0 + 0.2 + i * 0.37, L + 0.06);
    });
    s += post(R1 - 0.07, Y0) + post(R1 - 0.07, Y1 - 0.07);

    // Founder at the folding desk, with lamp, mug, plant and laptop.
    const extras = (top) => {
      const lb = P(3.22, 5.55, top), lj = P(3.18, 5.5, top + 0.8), lh = P(3.42, 5.12, top + 0.92), spot = P(3.85, 4.4, top);
      const arm = `M${f1(lb[0])} ${f1(lb[1])}L${f1(lj[0])} ${f1(lj[1])}L${f1(lh[0])} ${f1(lh[1])}`;
      let e = `<path d="M${f1(lh[0])} ${f1(lh[1] + 6)}L${f1(spot[0] - 36)} ${f1(spot[1] + 4)}L${f1(spot[0] + 26)} ${f1(spot[1] + 12)}Z" fill="#fff3b0" opacity=".4" stroke="none"/><ellipse cx="${f1(lb[0])}" cy="${f1(lb[1])}" rx="10" ry="4.5" fill="#3d5a80"/><path d="${arm}" fill="none" stroke-width="6"/><path d="${arm}" fill="none" stroke="#3d5a80" stroke-width="2.6"/><path d="M${f1(lh[0] - 9)} ${f1(lh[1] - 4)}L${f1(lh[0] + 9)} ${f1(lh[1] - 6)}L${f1(lh[0] + 6)} ${f1(lh[1] + 7)}L${f1(lh[0] - 7)} ${f1(lh[1] + 8)}Z" fill="#3d5a80"/>`;
      e += onZ(top, `<rect x="4.12" y="2.92" width="0.32" height="0.32" fill="#fff17a" transform="rotate(10 4.28 3.08)"/><rect x="4.2" y="5.0" width="0.3" height="0.3" fill="#ffb7cb" transform="rotate(-8 4.35 5.15)"/>`);
      e += cyl(3.32, 2.72, top, top + 0.2, 0.075, "#5b8ef0", "#d9e0ec");
      const mt = P(4.3, 2.62, top + 0.23);
      e += cyl(4.3, 2.62, top, top + 0.23, 0.12, HOODIE, "#f3a08d") + `<ellipse cx="${f1(mt[0])}" cy="${f1(mt[1])}" rx="4.4" ry="2.6" fill="#6b4630" stroke="none"/><path d="M${f1(mt[0] + 6)} ${f1(mt[1] + 4)}q8 1 6 7q-2 4-6 3" fill="none" stroke-width="2.6"/>`;
      e += `<path d="M${f1(mt[0] - 2)} ${f1(mt[1] - 6)}q-4-6 0-11q4-5 0-10" fill="none" stroke="#fff" stroke-width="2.5"><animate attributeName="opacity" values=".9;.15;.9" dur="2.4s" repeatCount="indefinite"/></path>`;
      const pp = P(4.32, 5.48, top + 0.2), leaf = mix("#6cbf5b", "#a7844c", p);
      e += cyl(4.32, 5.48, top, top + 0.2, 0.14, "#c96a4d", "#7a5233") + `<g transform="translate(${f1(pp[0])} ${f1(pp[1])})">` + [-38, -12, 14, 40].map((a, i) => `<ellipse cx="0" cy="-11" rx="4.5" ry="11" fill="${i % 2 ? leaf : shade(leaf, 0.85)}" transform="rotate(${a})"/>`).join("") + `</g>`;
      return e;
    };
    s += A.deskUnit(I, 3.0, 4.1, { depth: 1.6, len: 3.6, person: { top: HOODIE, glasses: true }, extras });

    // Floor fan, then the garden in front of the garage.
    const [fx, fy] = P(6.05, 6.75, 0);
    const blades = [0, 120, 240].map((a) => `<ellipse cx="0" cy="-55" rx="5.5" ry="9.5" fill="#a6dcf3" transform="rotate(${a} 0 -45)"/>`).join("");
    s += `<g transform="translate(${f1(fx)} ${f1(fy)})"><ellipse cx="0" cy="0" rx="15" ry="6" fill="#5f6675"/><rect x="-2.5" y="-32" width="5" height="32" fill="${METAL}"/><circle cx="0" cy="-45" r="19" fill="#eef3f6"/><g>${blades}<animateTransform attributeName="transform" type="rotate" from="0 0 -45" to="360 0 -45" dur="0.5s" repeatCount="indefinite"/></g><circle cx="0" cy="-45" r="19" fill="none"/><circle cx="0" cy="-45" r="4" fill="#5f6675"/></g>`;
    s += tree(I, 9.6, 0.3, 1.3, p) + tree(I, 10.8, 2.8, 1.1, p) + tree(I, -1.2, 9.6, 1.25, p) + tree(I, -0.2, 11.2, 0.95, p);
    const flowers = [[1.2, 9.6], [2.2, 10.1], [9.5, 6.4], [10.2, 5.2], [3.4, 10.4]];
    if (p < 0.5) s += flowers.map(([x, y], i) => { const [fx2, fy2] = P(x, y, 0); return `<g transform="translate(${f1(fx2)} ${f1(fy2)})"><ellipse cx="0" cy="0" rx="14" ry="6" fill="${mix("#6cbf5b", "#a7844c", p)}"/><circle cx="-5" cy="-4" r="3.2" fill="${["#ef7c64", "#f6c445", "#9a7de2"][i % 3]}"/><circle cx="4" cy="-6" r="3" fill="#fff"/></g>`; }).join("");
    s += smog(p);
    return { svg: `<g stroke="${INK}" stroke-width="2.4" stroke-linejoin="round" stroke-linecap="round">${s}</g>`, bubble: P(2.6, 3.55, 3.75), zoom: P(3.9, 4.1, 2.0) };
  };
})(window);
