/* Stage 4: the AI campus seen from above. Stage 5: the whole planet. */
(function (root) {
  const A = root.AetherArt, S = root.AetherScenes;
  const { INK, f1, mix, esc, makeIso, landscape, smog, tree } = A;

  S.campus = (v) => {
    const I = makeIso(30, 480, 250);
    const { P, box, onZ, cyl, circ, poly } = I;
    const p = v.pollution, biome = v.biome || "grass", kind = biome === "desert" ? "cactus" : biome === "snow" ? "pine" : "tree";
    let s = landscape(I, p, { biome, town: true, smoke: v.ci > 0.6, horizon: 175 });

    // Lake (shrinks with pollution and water use) and a road.
    const lake = Math.max(0.25, 1 - p * 0.75);
    s += onZ(-0.28, `<ellipse cx="11.6" cy="8.6" rx="${(2.4 * lake).toFixed(2)}" ry="${(1.7 * lake).toFixed(2)}" fill="${mix("#6fbfe8", "#8c8a72", p)}"/><path d="M-1.2 -1 L-1.2 12 M-1.2 9 L13 9" fill="none" stroke="#9aa0a6" stroke-width="9"/><path d="M-1.2 -1 L-1.2 12 M-1.2 9 L13 9" fill="none" stroke="#fff" stroke-width="1.5" stroke-dasharray="6 7"/>`);

    // Power: solar + wind, gas plant, or the grid.
    if (v.ci < 0.2) {
      for (let r = 0; r < 4; r++) s += box(-6, 1 + r * 1.3, 0, -2.6, 1.8 + r * 1.3, 0.25, "#3d5a80", { top: "#5b8ef0" });
      for (const [x, y] of [[-6.5, -2.5], [-3.6, -3.4]]) {
        const [bx, by] = P(x, y, 0), [hx, hy] = P(x, y, 3.6);
        s += `<path d="M${f1(bx - 3)} ${f1(by)}L${f1(hx - 1.5)} ${f1(hy)}L${f1(hx + 1.5)} ${f1(hy)}L${f1(bx + 3)} ${f1(by)}Z" fill="#eef1f3"/>`;
        s += `<g>${[0, 120, 240].map((a) => `<path d="M${f1(hx)} ${f1(hy)}l-3 -34l3 -4l3 4z" fill="#fff" transform="rotate(${a} ${f1(hx)} ${f1(hy)})"/>`).join("")}<animateTransform attributeName="transform" type="rotate" from="0 ${f1(hx)} ${f1(hy)}" to="360 ${f1(hx)} ${f1(hy)}" dur="4s" repeatCount="indefinite"/></g><circle cx="${f1(hx)}" cy="${f1(hy)}" r="3.5" fill="#cbd3dc"/>`;
      }
    } else if (v.ci > 0.6) {
      s += box(-6, 1.5, 0, -3, 4.5, 1.4, "#b9c1c9", { top: "#d6dce2" });
      for (const [x, y] of [[-3.6, 0.6], [-5.2, 0.6]]) {
        s += cyl(x, y, 0, 4.2, 0.38, "#c9cfd5", "#8d97a1");
        const [sx, sy] = P(x, y, 4.3);
        for (let i = 0; i < 3; i++) s += `<circle cx="${f1(sx + i * 9)}" cy="${f1(sy - 12 - i * 16)}" r="${9 + i * 5}" fill="#7d756c" opacity=".75" stroke="none"><animate attributeName="cy" values="${f1(sy - 12 - i * 16)};${f1(sy - 34 - i * 16)};${f1(sy - 12 - i * 16)}" dur="${3 + i}s" repeatCount="indefinite"/></circle>`;
      }
    } else {
      for (const [x, y] of [[-4.5, 1.5], [-4.5, 6]]) {
        const [bx, by] = P(x, y, 0), [tx, ty] = P(x, y, 3.4);
        s += `<path d="M${f1(bx - 12)} ${f1(by)}L${f1(tx)} ${f1(ty)}L${f1(bx + 12)} ${f1(by)}M${f1(bx - 8)} ${f1(by - 25)}L${f1(bx + 8)} ${f1(by - 25)}M${f1(tx - 16)} ${f1(ty + 12)}L${f1(tx + 16)} ${f1(ty + 12)}" fill="none" stroke="#7d8792" stroke-width="3"/>`;
      }
    }

    // Campus buildings: one more per hyperscale campus you own.
    const spots = [[0, 0], [3.2, 0], [6.4, 0], [0, 2.8], [3.2, 2.8], [6.4, 2.8], [0, 5.6], [3.2, 5.6], [6.4, 5.6]];
    const nB = Math.min(9, 1 + v.owned.campus);
    for (let i = 0; i < nB; i++) {
      const [x, y] = spots[i];
      s += box(x, y, 0, x + 2.6, y + 2.1, 1.0, "#d5dbe0", { top: "#eef1f3" });
      for (let k = 0; k < 3; k++) s += circ(x + 0.5 + k * 0.8, y + 1.05, 1.0, 0.24, "#5f6675");
      s += I.onY(y + 2.1, x, 1.0, `<rect x="0.2" y="0.35" width="2.2" height="0.18" fill="#a6dcf3"/><rect x="1.1" y="0.6" width="0.4" height="0.4" fill="#5b8ef0"/>`);
    }
    // The start-up's name on the headquarters roof.
    s += onZ(1.0, `<text transform="translate(1.3 1.25) rotate(0) scale(0.01)" font-size="${Math.min(60, 380 / Math.max(5, v.name.length))}" text-anchor="middle" font-family="Fredoka, sans-serif" font-weight="700" fill="${INK}" stroke="none" opacity=".8">${esc(v.name.toUpperCase())}</text>`);

    // Town and forest. Fewer trees as pollution rises; fires when it gets bad.
    for (const [x, y] of [[0.5, 10.4], [2, 11.2], [3.6, 10.6], [5.2, 11.4]]) {
      s += box(x, y, 0, x + 1, y + 0.8, 0.6, "#f4ead8") + poly([[x, y, 0.6], [x + 1, y, 0.6], [x + 1, y + 0.4, 1.05], [x, y + 0.4, 1.05]], mix("#d06a50", "#8f6a55", p)) + poly([[x, y + 0.4, 1.05], [x + 1, y + 0.4, 1.05], [x + 1, y + 0.8, 0.6], [x, y + 0.8, 0.6]], mix("#b85a43", "#7a5a48", p));
    }
    const trees = [[10, 0.5], [11.5, 2], [13, 0.5], [12.5, 4], [10.5, 3.5], [14, 3], [8, 11], [9.5, 12.5], [7, 13], [-2.5, 10], [-3.5, 12], [12, 12]];
    const alive = Math.round(trees.length * (1 - p * 0.7));
    trees.forEach(([x, y], i) => {
      if (i >= alive) { const [sx, sy] = P(x, y, 0); s += `<rect x="${f1(sx - 3)}" y="${f1(sy - 8)}" width="6" height="8" fill="#7a5233"/>`; return; }
      s += tree(I, x, y, 0.85, p, kind);
      if (p > 0.75 && i % 3 === 0) { const [sx, sy] = P(x, y, 0); s += `<path d="M${f1(sx)} ${f1(sy - 60)}c8 10 10 18 0 26c-10-8-8-16 0-26z" fill="#ef7c64"><animate attributeName="opacity" values="1;.5;1" dur=".8s" repeatCount="indefinite"/></path>`; }
    });
    s += smog(p);
    return { svg: `<g stroke="${INK}" stroke-width="2.2" stroke-linejoin="round" stroke-linecap="round">${s}</g>`, bubble: P(1.3, 1.05, 2.6), zoom: P(1.3, 1.05, 1) };
  };

  // Stylised continents on a strip that scrolls behind a round mask = a spinning planet.
  const LAND = [
    "M150 180C200 150 260 170 250 230C245 280 200 290 210 330C230 380 260 420 240 480C225 520 200 560 185 540C170 500 175 450 160 410C140 360 110 330 120 280C125 240 120 200 150 180Z",
    "M470 170C520 150 570 170 560 210C555 240 520 240 530 270C560 300 590 330 580 390C570 450 540 500 510 520C490 500 485 450 470 410C455 370 430 340 445 300C455 270 440 240 450 210C455 190 460 180 470 170Z",
    "M600 160C680 130 800 140 860 180C900 210 880 260 840 270C800 280 780 300 750 320C720 340 690 320 670 300C640 270 610 260 600 230C590 200 580 175 600 160Z",
    "M820 420C860 400 910 410 920 445C925 480 880 495 850 485C815 475 795 445 820 420Z",
  ];
  const LIGHTS = [[200, 250], [230, 420], [500, 260], [520, 400], [700, 220], [780, 250], [860, 440], [180, 320], [540, 330], [650, 280], [480, 220], [215, 470], [760, 200], [880, 460], [560, 460]];

  S.world = (v) => {
    const p = v.pollution, R = 250, cx = 480, cy = 360, W = 1100;
    let s = `<rect x="-700" y="-600" width="2400" height="1800" fill="#13203a" stroke="none"/>`;
    for (let i = 0; i < 160; i++) s += `<circle cx="${((i * 137) % 1900) - 500}" cy="${((i * 89) % 1100) - 250}" r="${i % 5 === 0 ? 1.8 : 1}" fill="#fff" opacity=".7" stroke="none"/>`;
    const land = mix("#7cc36b", "#b59a63", p), dry = mix("#c9b26e", "#8f6a45", p), ocean = mix("#4d9de0", "#4a6272", p);
    const lights = Math.min(LIGHTS.length, 3 + v.owned.gigafactory * 2);
    const strip = (dx) => `<g transform="translate(${dx} 0)">` + LAND.map((d) => `<path d="${d}" fill="${land}"/>`).join("") +
      (p > 0.25 ? LAND.map((d) => `<path d="${d}" fill="${dry}" stroke="none" opacity="${Math.min(0.85, (p - 0.25) * 1.4).toFixed(2)}" transform="translate(${cx} ${cy}) scale(.7) translate(${-cx} ${-cy})"/>`).join("") : "") +
      LIGHTS.slice(0, lights).map(([x, y]) => `<circle cx="${x}" cy="${y}" r="5" fill="#ffe27a" stroke="#2b2433" stroke-width="1.5"/>`).join("") +
      (p > 0.75 ? LIGHTS.slice(0, Math.round(((p - 0.75) / 0.25) * 12) + 3).map(([x, y]) => A.flame(x + 14, y + 6, 0.7)).join("") : "") + `</g>`;
    s += `<clipPath id="planetClip"><circle cx="${cx}" cy="${cy}" r="${R}"/></clipPath><circle cx="${cx}" cy="${cy}" r="${R + 12}" fill="none" stroke="${mix("#bfe8ff", "#c79a6a", p)}" stroke-width="10" opacity=".6"/>`;
    s += `<circle cx="${cx}" cy="${cy}" r="${R}" fill="${ocean}"/><g clip-path="url(#planetClip)"><g>${strip(0)}${strip(W)}<animateTransform attributeName="transform" type="translate" from="0 0" to="${-W} 0" dur="90s" repeatCount="indefinite"/></g>`;
    const ice = Math.max(0.15, 1 - p * 0.85);
    s += `<ellipse cx="${cx}" cy="${cy - R + 18}" rx="${(190 * ice).toFixed(0)}" ry="48" fill="#f4fbff"/><ellipse cx="${cx}" cy="${cy + R - 14}" rx="${(210 * ice).toFixed(0)}" ry="44" fill="#f4fbff"/>`;
    s += `<g opacity=".75" stroke="none"><g>${[0, W].map((dx) => [[260, 230, 50], [430, 470, 60], [700, 330, 45], [900, 210, 55], [1020, 500, 50]].map(([x, y, r]) => `<ellipse cx="${x + dx}" cy="${y}" rx="${r}" ry="${r * 0.35}" fill="${mix("#ffffff", "#bba48c", p)}"/>`).join("")).join("")}<animateTransform attributeName="transform" type="translate" from="0 0" to="${-W} 0" dur="55s" repeatCount="indefinite"/></g></g>`;
    if (p > 0.35) s += `<circle cx="${cx}" cy="${cy}" r="${R}" fill="#7a5a3a" opacity="${Math.min(0.45, (p - 0.35) * 0.8).toFixed(2)}" stroke="none"/>`;
    s += `</g><circle cx="${cx}" cy="${cy}" r="${R}" fill="none" stroke-width="3"/><path d="M${cx - 170} ${cy - 150}A${R - 30} ${R - 30} 0 0 1 ${cx - 40} ${cy - 218}" fill="none" stroke="#fff" stroke-width="6" opacity=".35"/>`;
    return { svg: `<g stroke="${INK}" stroke-width="2.4" stroke-linejoin="round" stroke-linecap="round">${s}</g>`, bubble: [300, 120], zoom: [cx, cy] };
  };

  S.forStage = (stage, v) => [S.garage, S.office, S.datacenter, S.campus, S.world][stage - 1](v);
})(window);
