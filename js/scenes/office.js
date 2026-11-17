/* Stage 2: the start-up office, next to a park. */
(function (root) {
  const A = root.AetherArt, S = root.AetherScenes;
  const { INK, f1, shade, mix, esc, makeIso, landscape, smog, tree } = A;

  // Server rack seen from the front-left (LED rows on its visible face).
  S.rack = (I, x0, y0, h, leds) => {
    const x1 = x0 + 0.78, y1 = y0 + 0.9;
    let r = I.box(x0, y0, 0, x1, y1, h, "#2f3542", { top: "#454d5e", left: "#373e4c", right: "#252a35" });
    let face = "";
    for (let k = 0; k < Math.floor(h / 0.32); k++) face += `<rect x="0.08" y="${(0.12 + k * 0.32).toFixed(2)}" width="0.62" height="0.18" rx="0.02" fill="#454d5e"/><circle cx="0.62" cy="${(0.21 + k * 0.32).toFixed(2)}" r="0.035" fill="${leds[k % leds.length]}" stroke="none"/>`;
    return r + I.onY(y1, x0, h, face);
  };

  S.office = (v) => {
    const I = makeIso(42, 480, 288);
    const { P, box, onY, cyl } = I;
    const p = v.pollution, WOOD = "#c98f55";

    let s = landscape(I, p, { rainbow: true, town: true });

    // Right wall: the start-up's name, wall of fame, whiteboard.
    let rw = S.blocks().replace('stroke-opacity=".09"', 'stroke-opacity=".04"');
    const nm = v.name.toUpperCase(), size = Math.min(0.62, 3.0 / Math.max(5, nm.length) * 1.6);
    rw += `<rect x="0.45" y="0.45" width="3.5" height="1.1" rx="0.12" fill="${INK}"/><text transform="translate(2.2 1.24) scale(0.01)" font-size="${size * 100}" text-anchor="middle" font-family="Fredoka, sans-serif" font-weight="700" fill="#f6c445" stroke="none">${esc(nm)}</text>`;
    v.badgeColors.slice(0, 4).forEach((c, i) => { rw += S.frame(0.6 + i * 0.85, 1.75, c, WOOD); });
    rw += `<rect x="4.4" y="0.6" width="3.1" height="1.7" rx="0.05" fill="#fdfdfb"/><path d="M4.7 1.9l0.5-0.5 0.4 0.25 0.6-0.7 0.5 0.3" fill="none" stroke="#5b8ef0" stroke-width="2.5"/><path d="M6.3 1.0h0.9M6.3 1.25h0.7M6.3 1.5h0.85" fill="none" stroke="#ef7c64" stroke-width="2"/><rect x="5.2" y="2.3" width="1.4" height="0.08" fill="#9aa4ae"/>`;

    // Left wall: a big window onto the park and a hiring poster.
    let lw = S.blocks().replace('stroke-opacity=".09"', 'stroke-opacity=".04"') + S.window("oWin", 4.6, 1.0, 2.9, 2.3, p, WOOD);
    lw += `<g transform="rotate(2 2.1 1.5)"><rect x="1.2" y="0.8" width="1.8" height="1.4" fill="#f6c445"/><text transform="translate(2.1 1.45) scale(0.01)" font-size="30" text-anchor="middle" font-family="Fredoka, sans-serif" font-weight="700" fill="${INK}" stroke="none">WE'RE</text><text transform="translate(2.1 1.85) scale(0.01)" font-size="30" text-anchor="middle" font-family="Fredoka, sans-serif" font-weight="700" fill="${INK}" stroke="none">HIRING!</text></g>`;

    // Wooden floor with planks.
    let fl = `<g stroke-opacity=".1" stroke-width="1.3">`;
    for (let x = 0.5; x < 8; x += 0.5) fl += `<line x1="${x}" y1="0" x2="${x}" y2="8"/>`;
    fl += `</g><rect x="2.0" y="2.6" width="3.4" height="3.4" rx="0.1" fill="#e8d3b0" stroke-opacity=".3"/>`;
    s += S.room(I, { wall: "#e8eef2", wallTop: "#f7f9fb", floor: "#dcc3a0", rightDecor: rw, leftDecor: lw, floorDecor: fl });

    // Server racks along the back wall (one per two AI servers).
    const racks = Math.min(8, Math.ceil(v.owned.server / 2));
    for (let i = 0; i < racks; i++) s += S.rack(I, 0.45 + i * 0.92, 0.12, 2.5, ["#7dff8a", "#5b8ef0", "#7dff8a"]);
    // GPU cluster cabinets along the left wall.
    for (let i = 0; i < Math.min(3, v.owned.cluster); i++) {
      const y0 = 4.4 + i * 1.12;
      s += box(0.15, y0, 0, 1.3, y0 + 1.0, 3.0, "#262b36", { top: "#3b4252", left: "#30364a", right: "#1e222b" });
      s += onY(y0 + 1.0, 0.15, 3.0, [0.3, 0.7, 1.1, 1.5, 1.9, 2.3, 2.7].map((w) => `<line x1="0.12" y1="${w}" x2="1.03" y2="${w}" stroke="${i % 2 ? "#8e7cf0" : "#7dff8a"}" stroke-width="2.4"/>`).join(""));
    }
    // Coffee corner: a water cooler.
    s += cyl(7.4, 0.6, 0, 1.1, 0.25, "#e4ebef", "#f4f7f9") + cyl(7.4, 0.6, 1.1, 1.6, 0.2, "#a6dcf3", "#c9ecfa");

    // Founder and coworkers.
    const extras = (top) => { const pp = P(3.6, 5.2, top + 0.2), leaf = mix("#6cbf5b", "#a7844c", p); return I.cyl(3.6, 5.2, top, top + 0.2, 0.14, "#c96a4d", "#7a5233") + `<g transform="translate(${f1(pp[0])} ${f1(pp[1])})">` + [-35, -10, 15, 40].map((a, i) => `<ellipse cx="0" cy="-11" rx="4.5" ry="11" fill="${i % 2 ? leaf : shade(leaf, 0.85)}" transform="rotate(${a})"/>`).join("") + `</g>`; };
    s += A.deskUnit(I, 3.2, 4.3, { depth: 1.4, len: 2.4, person: { top: "#ef7c64", glasses: true }, extras, desk: "#e2b47e", deskFaces: { left: "#cf9f69", right: "#b78852" } });
    const workers = 1 + (v.owned.server >= 6 ? 1 : 0);
    s += A.deskUnit(I, 6.0, 2.3, { depth: 1.3, len: 1.9, device: "monitor", person: { top: "#5b8ef0", hair: "#6b3f2a", skin: A.SKINS[1], long: true }, desk: "#e2b47e", deskFaces: { left: "#cf9f69", right: "#b78852" }, chair: "#3a3f4b" });
    if (workers > 1) s += A.deskUnit(I, 6.0, 6.1, { depth: 1.3, len: 1.9, device: "monitor", person: { top: "#7cc36b", hair: "#1f1a1c", skin: A.SKINS[2] }, desk: "#e2b47e", deskFaces: { left: "#cf9f69", right: "#b78852" }, chair: "#3a3f4b" });

    // Big plant in the front corner, park trees outside.
    const [px, py] = P(7.4, 7.4, 0.55), leaf = mix("#5fae55", "#a7844c", p);
    s += cyl(7.4, 7.4, 0, 0.55, 0.32, "#d7dde2", "#b9c1c9") + `<g transform="translate(${f1(px)} ${f1(py)})">` + [-50, -25, 0, 25, 50].map((a, i) => `<ellipse cx="0" cy="-24" rx="8" ry="24" fill="${i % 2 ? leaf : shade(leaf, 0.85)}" transform="rotate(${a})"/>`).join("") + `</g>`;
    s += tree(I, 9.6, 0.3, 1.3, p) + tree(I, 10.8, 2.8, 1.1, p) + tree(I, -1.2, 9.6, 1.25, p) + tree(I, -0.2, 11.2, 0.95, p) + tree(I, 11.5, 6.5, 1.0, p);
    s += smog(p);
    return { svg: `<g stroke="${INK}" stroke-width="2.4" stroke-linejoin="round" stroke-linecap="round">${s}</g>`, bubble: P(2.9, 3.9, 3.75), zoom: P(4, 4.3, 2) };
  };
})(window);
