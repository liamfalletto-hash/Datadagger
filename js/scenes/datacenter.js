/* Stage 3: the data centre hall. Its surroundings depend on the cooling choice. */
(function (root) {
  const A = root.AetherArt, S = root.AetherScenes;
  const { INK, f1, mix, esc, makeIso, landscape, smog, tree } = A;

  S.datacenter = (v) => {
    const I = makeIso(42, 480, 288);
    const { P, box, onY, onZ, cyl } = I;
    const p = v.pollution, biome = v.biome || "grass", kind = biome === "desert" ? "cactus" : biome === "snow" ? "pine" : "tree";
    let s = landscape(I, p, { biome, town: true, smoke: v.ci > 0.6 });

    // Walls: the name painted big, warning stripes; raised-floor tiles.
    const nm = v.name.toUpperCase(), size = Math.min(0.9, 6.5 / Math.max(6, nm.length) * 1.5);
    let rw = `<text transform="translate(4 1.35) scale(0.01)" font-size="${size * 100}" text-anchor="middle" font-family="Fredoka, sans-serif" font-weight="700" fill="#5b8ef0" stroke="none" opacity=".85">${esc(nm)}</text><rect x="0" y="5.6" width="8" height="0.4" fill="#f6c445" stroke-opacity=".3"/>`;
    let lw = `<rect x="0" y="5.6" width="8" height="0.4" fill="#f6c445" stroke-opacity=".3"/><rect x="1.2" y="1.2" width="1.6" height="0.9" rx="0.05" fill="#fdfdfb"/><text transform="translate(2 1.6) scale(0.01)" font-size="22" text-anchor="middle" font-family="Nunito, sans-serif" font-weight="800" fill="${INK}" stroke="none">COLD AISLE</text><text transform="translate(2 1.9) scale(0.01)" font-size="18" text-anchor="middle" font-family="Nunito, sans-serif" font-weight="800" fill="#ef7c64" stroke="none">HOT AISLE →</text>`;
    let fl = `<g stroke-opacity=".14" stroke-width="1.2">`;
    for (let k = 0.6; k < 8; k += 0.6) fl += `<line x1="${k.toFixed(1)}" y1="0" x2="${k.toFixed(1)}" y2="8"/><line x1="0" y1="${k.toFixed(1)}" x2="8" y2="${k.toFixed(1)}"/>`;
    fl += `</g><rect x="0.4" y="2.35" width="5" height="0.85" fill="#a6dcf3" opacity=".45" stroke="none"/><rect x="0.4" y="4.85" width="5" height="0.85" fill="#a6dcf3" opacity=".45" stroke="none"/>`;
    s += S.room(I, { wall: "#dfe4e8", wallTop: "#f1f4f6", floor: "#c3cad1", rightDecor: rw, leftDecor: lw, floorDecor: fl });

    // Rows of racks: more halls bought = more racks.
    const n = Math.min(15, 3 + 3 * v.owned.datacenter), rows = [1.4, 3.3, 5.75];
    for (let i = 0; i < n; i++) {
      const row = Math.floor(i / 5), col = i % 5;
      s += S.rack(I, 0.45 + col * 0.82, rows[row] - 0.9, 2.2, row === 1 ? ["#5b8ef0", "#7dff8a"] : ["#7dff8a", "#f6c445"]);
    }

    // Glass control room with the founder.
    s += `<g opacity=".35">` + box(5.0, 5.3, 0, 7.95, 5.36, 2.5, "#bfe6ff") + box(5.0, 5.3, 0, 5.06, 7.95, 2.5, "#bfe6ff") + `</g>`;
    s += A.deskUnit(I, 6.55, 6.6, { depth: 1.3, len: 1.9, device: "monitor", person: { top: "#ef7c64", glasses: true }, chair: "#3a3f4b", desk: "#f3eee4" });
    s += `<g opacity=".28">` + box(5.0, 7.9, 0, 7.95, 7.96, 2.5, "#bfe6ff") + box(7.9, 5.3, 0, 7.96, 7.96, 2.5, "#bfe6ff") + `</g>`;

    // Cooling outside, depending on the choice.
    if (biome === "desert") {
      for (const [x, y] of [[9.2, 1.6], [9.6, 3.6]]) {
        s += cyl(x, y, 0, 1.7, 0.6, "#d9dde1", "#eef1f3");
        const [sx, sy] = P(x, y, 1.75);
        s += `<circle cx="${f1(sx)}" cy="${f1(sy - 14)}" r="16" fill="#fff" opacity=".8" stroke="none"><animate attributeName="cy" values="${f1(sy - 14)};${f1(sy - 40)};${f1(sy - 14)}" dur="3s" repeatCount="indefinite"/><animate attributeName="opacity" values=".8;0;.8" dur="3s" repeatCount="indefinite"/></circle>`;
      }
    } else if (biome === "snow") {
      s += onZ(-0.29, `<path d="M8 2 L10.5 2 L10.5 5.5" fill="none" stroke-width="7"/><path d="M8 2 L10.5 2 L10.5 5.5" fill="none" stroke="#ef7c64" stroke-width="3.5"/>`);
      for (const [x, y] of [[10, 5.6], [11.3, 4.4]]) s += box(x, y, -0.3, x + 0.9, y + 0.8, 0.5, "#f4ead8") + I.poly([[x, y, 0.5], [x + 0.9, y, 0.5], [x + 0.9, y + 0.4, 0.95], [x, y + 0.4, 0.95]], "#d06a50") + I.poly([[x, y + 0.4, 0.95], [x + 0.9, y + 0.4, 0.95], [x + 0.9, y + 0.8, 0.5], [x, y + 0.8, 0.5]], "#b85a43");
    } else {
      for (const [x, y] of [[8.9, 1.0], [8.9, 2.5], [8.9, 4.0]]) {
        s += box(x, y, -0.3, x + 1.1, y + 1.2, 0.55, "#c9d0d7", { top: "#e3e8ec" }) + I.circ(x + 0.55, y + 0.6, 0.55, 0.38, "#5f6675");
      }
    }
    for (const [x, y, k] of [[-1.2, 9.6, 1.2], [-0.2, 11.2, 0.9], [10.8, 7.2, 1.1], [12, 2.2, 1.0]]) s += tree(I, x, y, k, p, kind);
    s += smog(p);
    return { svg: `<g stroke="${INK}" stroke-width="2.4" stroke-linejoin="round" stroke-linecap="round">${s}</g>`, bubble: P(6.0, 6.4, 4.2), zoom: P(6.8, 6.6, 2) };
  };
})(window);
