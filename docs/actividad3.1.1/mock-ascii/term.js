/* ASCII scene renderer + deck engine shared by every terminal prototype.
   Scenes are signed-distance drawings sampled per character cell, so the same
   animation renders as phosphor, ANSI blocks or typewriter ink depending on
   the style's ramp and colour function. All story content is synthetic. */
(function () {
  const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const TAU = Math.PI * 2, cl = (v, a = 0, b = 1) => v < a ? a : v > b ? b : v, fr = x => x - Math.floor(x);
  const hash = (x, y) => fr(Math.sin(x * 127.1 + y * 311.7) * 43758.5453);
  const sdC = (x, y, cx, cy, r) => Math.hypot(x - cx, y - cy) - r;
  const sdB = (x, y, cx, cy, bx, by, r = 0) => { const qx = Math.abs(x - cx) - bx + r, qy = Math.abs(y - cy) - by + r; return Math.hypot(Math.max(qx, 0), Math.max(qy, 0)) + Math.min(Math.max(qx, qy), 0) - r; };
  const sdS = (x, y, ax, ay, bx, by) => { const px = x - ax, py = y - ay, dx = bx - ax, dy = by - ay, h = cl((px * dx + py * dy) / (dx * dx + dy * dy)); return Math.hypot(px - dx * h, py - dy * h); };
  const smin = (a, b, k) => { const h = cl(.5 + .5 * (b - a) / k); return b * (1 - h) + a * h - k * h * (1 - h); };
  const ease = u => 1 - Math.pow(1 - cl(u), 3);
  // outline strong, interior textured
  const ink = (d, x, y, t, fill = .3, e = .035) => d > e ? 0 : d > -e ? 1 - Math.abs(d) / e * .35 : fill * (.55 + .45 * Math.sin(x * 23 + y * 17 + t * 2.2));
  const GLY = '#$%&*+=?@ABCDEFGHJKLMNPQRSTUVWXYZ0123456789';
  const decode = (s, t, t0) => s.split('').map((c, k) => (c === ' ' || t > t0 + k * .035) ? c : GLY[Math.floor(hash(k, Math.floor(t * 20)) * GLY.length)]).join('');

  function bust(x, y, cx, cy, s) {
    const head = sdC(x, y, cx, cy - .38 * s, .26 * s), body = sdB(x, y, cx, cy + .62 * s, .62 * s, .36 * s, .3 * s);
    return smin(head, body, .12 * s);
  }
  function lock(x, y, cx, cy, o) { // o: 0 closed → 1 open
    const body = sdB(x, y, cx, cy + .16, .27, .21, .04), lift = o * .2, top = cy - .07 - lift;
    const ring = Math.abs(sdC(x, y, cx, top, .17)) - .035, arc = y < top ? ring : 1;
    const legL = sdS(x, y, cx - .17, top, cx - .17, cy - .04) - .035;
    const legR = sdS(x, y, cx + .17, top, cx + .17, cy - .04 - lift) - .035;
    const kh = Math.min(sdC(x, y, cx, cy + .12, .045), sdB(x, y, cx, cy + .21, .018, .06));
    return { d: Math.max(Math.min(body, arc, legL, legR), -kh), kh };
  }

  const SCENES = {
    idle(x, y, t, i, j) { return hash(i, j + Math.floor(t * 3)) > .992 ? .5 : 0; },

    cover(x, y, t, i, j) {
      const kh = Math.min(sdC(x, y, 0, .42, .075), sdB(x, y, 0, .58, .035, .12));
      let d = Math.max(bust(x, y, 0, 0, 1), -kh), v = ink(d, x, y, t, .32);
      if (Math.abs(kh) < .03) v = -1;
      if (!v || hash(i, j) > t / 1.6) return 0;
      const by = ((t * .45) % 2.6) - 1.3, band = Math.exp(-((y - by) ** 2) / .003);
      return v < 0 ? v : Math.min(1, v + band * .6);
    },

    recon(x, y, t) {
      const r = Math.hypot(x, y); if (r > .95) return 0;
      const sweep = (t * 1.3) % TAU, ang = Math.atan2(y, x), dA = ((sweep - ang) % TAU + TAU) % TAU;
      let v = cl(1 - dA / 1.4) * .7 * (r < .93);
      if (Math.min(Math.abs(r - .3), Math.abs(r - .6), Math.abs(r - .92)) < .012) v = Math.max(v, .45);
      if (Math.abs(x) < .006 || Math.abs(y) < .012) v = Math.max(v, .28);
      for (const [px, py] of RECON) if (Math.hypot(x - px, y - py) < .045) {
        const pa = Math.atan2(py, px), since = ((sweep - pa) % TAU + TAU) % TAU; return -(.35 + .65 * cl(1 - since / 3));
      }
      return v;
    },
    reconStamps(t) { const sweep = (t * 1.3) % TAU; return RECON.map(([px, py, s]) => { const since = ((sweep - Math.atan2(py, px)) % TAU + TAU) % TAU; return { s, x: px, y: py + .11, acc: since < 2.4 }; }); },

    pretext(x, y, t) {
      const sx = reduced ? 1 : Math.max(.04, ease(t * 1.1)), X = x / sx;
      let d = Math.max(sdB(X, y, 0, .05, .48, .82, .06), -sdB(X, y, 0, -.66, .11, .025, .02));
      let v = ink(d, X, y, t, .12);
      const frame = Math.abs(sdB(X, y, 0, -.22, .26, .26)) - .012, b = bust(X, y, 0, -.18, .32);
      if (sdB(X, y, 0, -.22, .26, .26) < 0) v = Math.max(v, ink(b, X, y, t, .55));
      if (frame < 0) v = .6;
      return v;
    },
    pretextStamps(t) { return [{ s: decode('IT HELP DESK', t, .9), x: 0, y: .2, acc: 1 }, { s: decode('J. MARCOS', t, 1.2), x: 0, y: .36 }, { s: decode('ACCESS: ALL AREAS', t, 1.5), x: 0, y: .52 }]; },

    contact(x, y, t, i, j) {
      const P = 3.4, u = (t % P) / P, ex = -1.0 + u * 1.75, ey = -.1 - Math.sin(u * Math.PI) * .32;
      let v = 0;
      const env = sdB(x, y, ex, ey, .19, .12, .015);
      if (Math.abs(env) < .025) v = 1; else if (env < 0) v = .15;
      if (sdS(x, y, ex - .19, ey - .12, ex, ey + .03) < .018 || sdS(x, y, ex + .19, ey - .12, ex, ey + .03) < .018) v = 1;
      const s = (x + 1.0) / 1.75;
      if (s < u && s > u - .4 && env > .03) { const py = -.1 - Math.sin(s * Math.PI) * .32; if (Math.abs(y - py) < .02 && hash(i, 3) > .35) v = Math.max(v, .45 * (1 - (u - s) / .4)); }
      const tgt = ink(bust(x, y, .92, .18, .34), x, y, t, .25);
      if (tgt) v = Math.max(v, u > .93 ? -tgt : tgt);
      return v;
    },
    contactStamps(t) { const u = (t % 3.4) / 3.4; return [{ s: '@', x: -1.0 + u * 1.75, y: -.1 - Math.sin(u * Math.PI) * .32 - .01, acc: 1 }, { s: 'accounts payable', x: .92, y: .55, acc: u > .93 }]; },

    exploit(x, y, t) {
      const o = ease((t - 1.7) / .5), L = lock(x, y, .52, 0, o);
      let v = ink(L.d, x, y, t, .3);
      if (Math.abs(L.kh) < .02) v = -1;
      const kx = -.95 + ease(t / 1.6) * .85, ky = .12;
      const key = Math.min(Math.abs(sdC(x, y, kx, ky, .12)) - .03, sdB(x, y, kx + .3, ky, .18, .022), sdB(x, y, kx + .41, ky + .055, .022, .035), sdB(x, y, kx + .32, ky + .05, .018, .03));
      if (key < .012) v = -1;
      return v;
    },
    exploitStamps(t) { return t > 2.1 ? [{ s: decode('credentials accepted', t, 2.1), x: .52, y: .68, acc: 1 }] : []; },

    report(x, y, t) { const o = 1 - ease(t / .8), L = lock(x, y, -.55, 0, o); return ink(L.d, x, y, t, .45); },
    reportStamps(t) {
      const L = ['[x] call-back verification', '[x] MFA on every login', '[x] one-click report button', '[x] training without blame'];
      return L.filter((_, k) => t > .9 + k * .55).map((s, k) => ({ s: decode(s, t, .9 + k * .55), x: .38, y: -.3 + k * .2, acc: 1, left: 1 }));
    },

    stream(x, y, t, i, j) {
      const r = hash(j, 7); if (r < .5) return 0;
      const sp = .25 + .6 * hash(j, 3), p = fr(i * .021 - t * sp + r * 9);
      return p < .22 ? .12 + .55 * (p / .22) ** 2 : 0;
    },

    defense(x, y, t, i, j, S) {
      const P = 2.6, u = (t % P) / P, ex = -1.05 + u * 1.85, ey = -.02, wallX = .02;
      const tw = S.verify ? ease((performance.now() / 1000 - S.verifyAt) / .6) : 0;
      let v = 0;
      if (tw > 0 && Math.abs(x - wallX) < .05 && y > .85 - tw * 1.75) v = (hash(Math.floor(y * 9), Math.floor(x * 30)) > .15) ? .9 : .5;
      const blocked = S.verify && ex > wallX - .24;
      if (!blocked) {
        const env = sdB(x, y, ex, ey, .17, .11, .015);
        if (Math.abs(env) < .024 || sdS(x, y, ex - .17, ey - .11, ex, ey + .02) < .017 || sdS(x, y, ex + .17, ey - .11, ex, ey + .02) < .017) v = 1;
      } else {
        const since = (ex - (wallX - .24)) / 1.85 * P, rr = since * .9, dd = Math.hypot(x - (wallX - .1), y - ey);
        if (Math.abs(dd - rr) < .07 && hash(i, j) > .72 && x < wallX) v = Math.max(v, .9 * cl(1 - since / .8));
      }
      const open = !S.verify && u > .8 ? ease((u - .8) / .08) : 0, L = lock(x, y, .72, -.02, open);
      const lv = ink(L.d, x, y, t, .3);
      if (lv) v = Math.max(Math.abs(v), lv) * (open > .5 ? -1 : 1);
      return v;
    },
    defenseStamps(t, S) {
      const u = (t % 2.6) / 2.6;
      return S.verify ? [{ s: 'call-back: request denied', x: .1, y: -.7, acc: 1, left: 1 }] : (u > .82 ? [{ s: 'access granted', x: .72, y: .55, acc: 1 }] : []);
    }
  };
  const RECON = [[-.48, -.42, 'org chart'], [.55, -.18, 'website'], [-.2, .55, 'conference photo']];

  /* ───────── renderer ───────── */
  const A = { S: { verify: false, verifyAt: 0 }, stats: { glyphs: 0, fps: 0, cols: 0, rows: 0, scene: 'idle' } };
  let cv, ctx, cfg, W, H, cw, chh, cols, rows, raf, last = 0, tt = 0, prev = null;
  let cur = { name: 'idle', cx: .68, clip: 0, t0: performance.now() };
  const DUR = 950; // scene-to-scene dissolve, ms
  A.init = function (canvas, config) {
    cv = canvas; ctx = cv.getContext('2d');
    cfg = Object.assign({ font: 'monospace', cell: 1.25, ramp: ' .:-=+*#%@', fps: 24, bg: null, unit: .92, color: (a, acc) => acc ? '#fff' : `rgba(255,255,255,${a})`, print: 0, inset: [0, 0, 0] }, config);
    const go = () => { resize(); if (!reduced) loop(); else draw(cur.t0 + 4000); };
    addEventListener('resize', () => { resize(); if (reduced) draw(cur.t0 + 4000); });
    (document.fonts ? document.fonts.ready : Promise.resolve()).then(go);
  };
  function resize() {
    const r = cv.getBoundingClientRect(), dpr = devicePixelRatio || 1;
    W = r.width; H = r.height; cv.width = W * dpr; cv.height = H * dpr; ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    chh = W * cfg.cell / 100; ctx.font = `${chh}px ${cfg.font}`; ctx.textBaseline = 'top';
    cw = ctx.measureText('M').width; cols = Math.ceil(W / cw); rows = Math.ceil(H / chh);
    A.stats.cols = cols; A.stats.rows = rows;
  }
  function loop() { raf = requestAnimationFrame(now => { loop(); if (now - last < 1000 / cfg.fps) return; A.stats.fps = Math.round(1000 / (now - last)); last = now; draw(now); }); }
  function draw(now) {
    ctx.clearRect(0, 0, W, H); if (cfg.bg) { ctx.fillStyle = cfg.bg; ctx.fillRect(0, 0, W, H); }
    let k = prev ? (now - tt) / DUR : 1; if (k >= 1) { prev = null; k = 1; }
    const t = (now - cur.t0) / 1000, tp = prev ? (now - prev.t0) / 1000 : 0;
    const fN = SCENES[cur.name] || SCENES.idle, fP = prev ? (SCENES[prev.name] || SCENES.idle) : null;
    const u = H / 2 * cfg.unit, oy = H / 2, oxN = W * cur.cx, oxP = prev ? W * prev.cx : 0, ramp = cfg.ramp, n = ramp.length;
    const iN = Math.floor(cur.clip * W / cw), iP = prev ? Math.floor(prev.clip * W / cw) : cols, i0 = Math.min(iN, iP);
    const printed = cfg.print ? t * cfg.print : 1e9, tick = Math.floor(now / 55);
    let lastFill = '', glyphs = 0;
    const j0 = Math.ceil(cfg.inset[0] * rows), j1 = Math.floor((1 - cfg.inset[1]) * rows), i1 = Math.floor((1 - cfg.inset[2]) * cols);
    for (let j = j0; j < j1; j++) {
      const y = ((j + .5) * chh - oy) / u;
      for (let i = i0; i < i1; i++) {
        let v, useNew = true;
        if (prev) {
          const e = k * 1.2 - hash(i * 1.31, j * .77);          // dissolve front, per cell
          if (e <= 0) useNew = false;
          else if (e < .16) {                                   // scramble band: only where either scene has ink
            const x = (i + .5) * cw, vn = i >= iN ? fN((x - oxN) / u, y, t, i, j, A.S) : 0, vp = i >= iP ? fP((x - oxP) / u, y, tp, i, j, A.S) : 0;
            if ((vn || vp) && hash(i, j + tick) < .7) { const f = cfg.color(.6, false, t, i, j); if (f !== lastFill) { ctx.fillStyle = f; lastFill = f; } ctx.fillText(GLY[Math.floor(hash(j, i + tick) * GLY.length)], i * cw, j * chh); glyphs++; }
            continue;
          }
        }
        if (useNew) { if (i < iN || j > printed) continue; v = fN(((i + .5) * cw - oxN) / u, y, t, i, j, A.S); }
        else { if (i < iP) continue; v = fP(((i + .5) * cw - oxP) / u, y, tp, i, j, A.S); }
        if (!v) continue;
        const a = Math.abs(v); if (a < .05) continue;
        const c = ramp[Math.min(n - 1, Math.max(1, Math.floor(a * n)))];
        const f = cfg.color(a, v < 0, t, i, j); if (f !== lastFill) { ctx.fillStyle = f; lastFill = f; }
        ctx.fillText(c, i * cw, j * chh); glyphs++;
      }
    }
    A.stats.glyphs = glyphs;
    if (cfg.print && printed < rows) { ctx.fillStyle = cfg.color(1, true, t, 0, 0); ctx.fillRect(((t * 97) % cols) * cw, Math.floor(printed) * chh, cw, chh); }
    const st = SCENES[cur.name + 'Stamps']; if (!st || k < .75 || printed < rows * .8) return;
    for (const s of st(t, A.S)) {
      const col = Math.round((oxN + s.x * u) / cw - (s.left ? 0 : s.s.length / 2)), row = Math.round((oy + s.y * u) / chh);
      if (cfg.stampBg) { ctx.fillStyle = cfg.stampBg; ctx.fillRect(col * cw - cw * .5, row * chh, (s.s.length + 1) * cw, chh); }
      ctx.fillStyle = cfg.color(1, !!s.acc, t, col, row); ctx.fillText(s.s, col * cw, row * chh);
    }
  }
  A.scene = function (name, center, cut) {
    const cx = center ?? .68; if (name === cur.name && cx === cur.cx) return;
    const now = performance.now();
    if (!reduced) { prev = cur; tt = now; }
    cur = { name, cx, clip: cut || 0, t0: now }; A.stats.scene = name;
    if (reduced) draw(now + 4000);
  };
  A.verify = function (on) { A.S.verify = on; A.S.verifyAt = performance.now() / 1000; if (reduced) draw(performance.now() + 4000); };

  /* ───────── deck ───────── */
  const D = { slides: [], i: 0, step: 0 };
  D.init = function () {
    D.slides = [...document.querySelectorAll('.slide')];
    D.slides.forEach(s => s.querySelectorAll('[data-type]').forEach(e => e.dataset.full = e.textContent));
    const m = location.hash.match(/#(\d+)(?:\.(\d+))?/);
    D.i = m ? Math.min(D.slides.length, Math.max(1, +m[1])) - 1 : 0; D.step = m && m[2] ? +m[2] : 0;
    const vb = document.getElementById('verify');
    if (vb) vb.onclick = () => { const on = vb.getAttribute('aria-pressed') !== 'true'; vb.setAttribute('aria-pressed', on); vb.textContent = on ? vb.dataset.on : vb.dataset.off; document.body.dataset.verify = on ? 'on' : 'off'; A.verify(on); };
    addEventListener('keydown', e => {
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      const k = e.key;
      if (k === 'ArrowRight' || k === ' ' || k === 'PageDown') { e.preventDefault(); D.next(); }
      else if (k === 'ArrowLeft' || k === 'PageUp') { e.preventDefault(); D.prev(); }
      else if (k === 'n' || k === 'N') document.getElementById('notes')?.classList.toggle('open');
      else if (k === 'f' || k === 'F') document.fullscreenElement ? document.exitFullscreen() : document.documentElement.requestFullscreen?.();
      else if (k === 'Escape') document.getElementById('notes')?.classList.remove('open');
    });
    D.apply(true);
  };
  D.go = (i, step) => { const changed = i !== D.i; D.i = Math.max(0, Math.min(D.slides.length - 1, i)); D.step = step || 0; D.apply(changed); };
  D.next = () => { const n = +D.slides[D.i].dataset.steps || 0; if (D.step < n) { D.step++; D.apply(); } else if (D.i < D.slides.length - 1) D.go(D.i + 1, 0); };
  D.prev = () => { if (D.step > 0) { D.step--; D.apply(); } else if (D.i > 0) D.go(D.i - 1, +D.slides[D.i - 1].dataset.steps || 0); };
  let typer;
  D.apply = function (entered) {
    const s = D.slides[D.i], st = D.step;
    D.slides.forEach(x => x.classList.toggle('on', x === s));
    s.querySelectorAll('[data-at]').forEach(x => x.classList.toggle('shown', st >= +x.dataset.at));
    s.querySelectorAll('[data-only]').forEach(x => x.classList.toggle('shown', st === +x.dataset.only));
    s.querySelectorAll('[data-lit]').forEach(x => x.classList.toggle('lit', st >= +x.dataset.lit));
    s.querySelectorAll('[data-is]').forEach(x => x.classList.toggle('on', st === +x.dataset.is));
    const name = s.dataset.scenes ? s.dataset.scenes.split(',')[st] : s.dataset.scene;
    A.scene(name, s.dataset.cx ? +s.dataset.cx : undefined, +(s.dataset.clip || 0));
    if (entered) { // type out [data-type] lines once per entry
      clearInterval(typer); const els = [...s.querySelectorAll('[data-type]')];
      if (reduced) els.forEach(e => e.textContent = e.dataset.full);
      else { els.forEach(e => e.textContent = ''); let k = 0, c = 0; typer = setInterval(() => { const e = els[k]; if (!e) return clearInterval(typer); c += 2; e.textContent = e.dataset.full.slice(0, c); if (c >= e.dataset.full.length) { k++; c = 0; } }, 28); }
    }
    document.body.dataset.slide = D.i; document.body.dataset.step = st;
    document.querySelectorAll('[data-tab]').forEach(b => b.classList.toggle('on', +b.dataset.tab === D.i));
    const nt = document.getElementById('notes'); if (nt) nt.textContent = s.dataset.notes || '';
    history.replaceState(null, '', '#' + (D.i + 1) + (st ? '.' + st : ''));
    document.dispatchEvent(new CustomEvent('deckchange', { detail: { slide: D.i, step: st } }));
  };
  window.Ascii = A; window.Deck = D;
})();
