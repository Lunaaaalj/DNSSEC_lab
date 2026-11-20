/* Persistent world + camera + deck engine, shared by every style prototype.
   The world is a synthetic trust graph of a FICTIONAL company ("Meridian Logistics").
   All people, domains and numbers are invented for the exercise. */
(function () {
  const NS = 'http://www.w3.org/2000/svg';
  const reduced = matchMedia('(prefers-reduced-motion: reduce)').matches;

  const NODES = [
    { id: 'tester', label: 'Pentester', x: 170,   y: 650, kind: 'tester' },
    { id: 's1',  label: 'Public org chart',  x: 470,  y: 350, kind: 'source' },
    { id: 's2',  label: 'Company website',   x: 470,  y: 650, kind: 'source' },
    { id: 's3',  label: 'Conference photo',  x: 470,  y: 950, kind: 'source' },
    { id: 'ceo', label: 'CEO',               x: 1350, y: 260, kind: 'person' },
    { id: 'cfo', label: 'CFO',               x: 1700, y: 400, kind: 'person' },
    { id: 'hr',  label: 'HR Lead',           x: 1000, y: 470, kind: 'person' },
    { id: 'ops', label: 'Ops Manager',       x: 1350, y: 600, kind: 'person' },
    { id: 'rec', label: 'Receptionist',      x: 860,  y: 690, kind: 'person' },
    { id: 'fin2',label: 'Finance Analyst',   x: 1560, y: 740, kind: 'person' },
    { id: 'it',  label: 'IT Help Desk',      x: 1120, y: 900, kind: 'person' },
    { id: 'fin1',label: 'Accounts Payable',  x: 1850, y: 900, kind: 'target' }
  ];
  const EDGES = [
    ['tester','s1','research'], ['tester','s2','research'], ['tester','s3','research'],
    ['s1','hr','leak'], ['s2','rec','leak'], ['s3','it','leak'],
    ['ceo','cfo'], ['ceo','hr'], ['ceo','ops'], ['cfo','fin2'], ['ops','fin2'],
    ['fin2','fin1'], ['hr','it'], ['hr','rec'], ['rec','it'], ['it','ops'], ['it','fin1']
  ];
  const BY = Object.fromEntries(NODES.map(n => [n.id, n]));
  const SHOTS = {
    full:    { x: 0,    y: 0,   w: 2400 },
    recon:   { x: 0,    y: 180, w: 1500 },
    pretext: { x: 700,  y: 560, w: 900 },
    contact: { x: 1000, y: 620, w: 1000 },
    exploit: { x: 1500, y: 650, w: 700 }
  };
  const PHASE_SHOT = ['full', 'recon', 'pretext', 'contact', 'exploit', 'full'];

  const W = { svg: null, opts: {}, cam: null, raf: 0, phase: 0, verify: false, els: { n: {}, e: {} } };

  W.init = function (svg, opts) {
    W.svg = svg; W.opts = Object.assign({ shape: 'circle', curve: 0, cut: false, pad: 0 }, opts || {});
    svg.setAttribute('preserveAspectRatio', 'xMidYMid slice');
    const hull = el('rect', { class: 'hull', x: 760, y: 140, width: 1290, height: 940, rx: W.opts.shape === 'square' ? 0 : 36 });
    const hullLbl = el('text', { class: 'hull-lbl', x: 800, y: 205 }); hullLbl.textContent = 'Meridian Logistics · fictional';
    const ge = el('g', { class: 'edges' }), gn = el('g', { class: 'nodes' });
    svg.append(hull, hullLbl, ge, gn);
    EDGES.forEach(([a, b, t]) => {
      const A = BY[a], B = BY[b], d = pathD(A, B, W.opts.curve);
      const p = el('path', { class: 'edge ' + (t || 'trust') + ' e-' + a + '-' + b, d, 'data-a': a, 'data-b': b });
      ge.append(p); W.els.e[a + '-' + b] = p;
    });
    NODES.forEach(n => {
      const g = el('g', { class: 'node ' + n.kind + ' n-' + n.id, transform: `translate(${n.x} ${n.y})` });
      const r = n.kind === 'source' ? 26 : 34;
      if (W.opts.shape === 'square') g.append(el('rect', { class: 'body', x: -r, y: -r, width: 2 * r, height: 2 * r }));
      else g.append(el('circle', { class: 'body', r }));
      g.append(el('circle', { class: 'hole', r: r * 0.4 }));
      const t = el('text', { class: 'lbl', y: r + 46, 'text-anchor': 'middle' }); t.textContent = n.label; g.append(t);
      gn.append(g); W.els.n[n.id] = g;
    });
    // verification gate on the Help Desk → Accounts Payable edge
    const A = BY.it, B = BY.fin1, c = ctrl(A, B, W.opts.curve);
    const mx = .25 * A.x + .5 * c.x + .25 * B.x, my = .25 * A.y + .5 * c.y + .25 * B.y;
    const gate = el('g', { class: 'gate', transform: `translate(${mx} ${my})` });
    gate.append(el('rect', { class: 'gate-bar', x: -9, y: -52, width: 18, height: 104 }));
    const gl = el('text', { class: 'gate-lbl', y: 96, 'text-anchor': 'middle' }); gl.textContent = 'call-back check'; gate.append(gl);
    svg.append(gate); W.els.gate = gate;
    W.set(0, 'full', W.opts.pad, true);
  };

  function el(tag, attrs) { const e = document.createElementNS(NS, tag); for (const k in attrs) e.setAttribute(k, attrs[k]); return e; }
  function ctrl(A, B, curve) { const mx = (A.x + B.x) / 2, my = (A.y + B.y) / 2, L = Math.hypot(B.x - A.x, B.y - A.y); return { x: mx, y: my + curve * L * .28 }; }
  function pathD(A, B, curve) { if (!curve) return `M${A.x} ${A.y}L${B.x} ${B.y}`; const c = ctrl(A, B, curve); return `M${A.x} ${A.y}Q${c.x} ${c.y} ${B.x} ${B.y}`; }

  function shotView(name, pad) {
    const s = SHOTS[name] || SHOTS.full, h = s.w * 9 / 16;
    const Wd = s.w / (1 - pad), Hd = Wd * 9 / 16;
    return { x: s.x - pad * Wd, y: s.y - (Hd - h) / 2, w: Wd };
  }
  function setVB(v) { W.cam = v; W.svg.setAttribute('viewBox', `${v.x} ${v.y} ${v.w} ${v.w * 9 / 16}`); }

  W.camera = function (name, pad, instant) {
    const to = shotView(name, pad || 0);
    cancelAnimationFrame(W.raf);
    if (instant || reduced || W.opts.cut || !W.cam) { setVB(to); return; }
    const from = Object.assign({}, W.cam), t0 = performance.now(), dur = 1100;
    const ease = u => u < .5 ? 4 * u * u * u : 1 - Math.pow(-2 * u + 2, 3) / 2;
    (function step(now) {
      const u = Math.min(1, (now - t0) / dur), k = ease(u);
      const cx0 = from.x + from.w / 2, cy0 = from.y + from.w * 9 / 32, cx1 = to.x + to.w / 2, cy1 = to.y + to.w * 9 / 32;
      const w = Math.exp(Math.log(from.w) + (Math.log(to.w) - Math.log(from.w)) * k);
      const cx = cx0 + (cx1 - cx0) * k, cy = cy0 + (cy1 - cy0) * k;
      setVB({ x: cx - w / 2, y: cy - w * 9 / 32, w });
      if (u < 1) W.raf = requestAnimationFrame(step);
    })(t0);
  };

  W.paint = function () {
    const p = W.phase, v = W.verify, N = W.els.n, E = W.els.e;
    Object.values(N).forEach(g => g.setAttribute('class', g.getAttribute('class').split(' ').filter(c => !/^(lit|known|imp|pwned|safe)$/.test(c)).join(' ')));
    Object.values(E).forEach(e => e.setAttribute('class', e.getAttribute('class').split(' ').filter(c => !/^(lit|active|blocked)$/.test(c)).join(' ')));
    const on = (n, c) => N[n].classList.add(c), edge = (k, c) => E[k].classList.add(c);
    if (p >= 1) { ['tester', 's1', 's2', 's3'].forEach(n => on(n, 'lit')); ['tester-s1', 'tester-s2', 'tester-s3', 's1-hr', 's2-rec', 's3-it'].forEach(k => edge(k, 'lit')); ['hr', 'rec', 'it'].forEach(n => on(n, 'known')); }
    if (p >= 2) { on('it', 'imp'); edge('hr-it', 'lit'); }
    if (p >= 3) { on('fin1', 'known'); edge('it-fin1', v ? 'blocked' : 'active'); }
    if (p >= 4) { if (v) on('fin1', 'safe'); else { on('fin1', 'pwned'); edge('it-fin1', 'lit'); } }
    W.els.gate.classList.toggle('show', v || p === 5);
    document.body.dataset.verify = v ? 'on' : 'off';
  };

  W.set = function (phase, shot, pad, instant) { W.phase = phase; W.paint(); W.camera(shot, pad, instant); };
  W.setVerify = function (on) { W.verify = !!on; W.paint(); };

  /* ───────── Deck ───────── */
  const D = { slides: [], i: 0, step: 0 };
  D.init = function () {
    D.slides = [...document.querySelectorAll('.slide')];
    const m = location.hash.match(/#(\d+)(?:\.(\d+))?/);
    D.i = m ? Math.min(D.slides.length, Math.max(1, +m[1])) - 1 : 0; D.step = m && m[2] ? +m[2] : 0;
    const prog = document.getElementById('prog');
    if (prog) D.slides.forEach((_, k) => { const b = document.createElement('i'); b.onclick = () => D.go(k); prog.append(b); });
    const vb = document.getElementById('verify');
    if (vb) vb.onclick = () => { const on = vb.getAttribute('aria-pressed') !== 'true'; vb.setAttribute('aria-pressed', on); vb.textContent = on ? vb.dataset.on : vb.dataset.off; W.setVerify(on); };
    document.querySelectorAll('.hot').forEach(h => h.addEventListener('click', () => { D.step = +h.dataset.go; D.apply(); }));
    addEventListener('keydown', e => {
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      const k = e.key;
      if (k === 'ArrowRight' || k === ' ' || k === 'PageDown') { e.preventDefault(); D.next(); }
      else if (k === 'ArrowLeft' || k === 'PageUp') { e.preventDefault(); D.prev(); }
      else if (k === 'n' || k === 'N') document.getElementById('notes')?.classList.toggle('open');
      else if (k === 'f' || k === 'F') document.fullscreenElement ? document.exitFullscreen() : document.documentElement.requestFullscreen?.();
      else if (k === 'Escape') document.getElementById('notes')?.classList.remove('open');
    });
    addEventListener('hashchange', () => { const m2 = location.hash.match(/#(\d+)(?:\.(\d+))?/); if (m2) { D.i = +m2[1] - 1; D.step = m2[2] ? +m2[2] : 0; D.apply(true); } });
    D.apply(true);
  };
  D.go = function (i, step) { D.i = Math.max(0, Math.min(D.slides.length - 1, i)); D.step = step || 0; D.apply(); };
  D.next = function () { const s = D.slides[D.i], n = +s.dataset.steps || 0; if (D.step < n) { D.step++; D.apply(); } else if (D.i < D.slides.length - 1) D.go(D.i + 1, 0); };
  D.prev = function () { if (D.step > 0) { D.step--; D.apply(); } else if (D.i > 0) { const p = D.slides[D.i - 1]; D.go(D.i - 1, +p.dataset.steps || 0); } };
  D.apply = function (instant) {
    const s = D.slides[D.i], st = D.step, phaseMode = s.dataset.stepmode === 'phase';
    D.slides.forEach(x => x.classList.toggle('on', x === s));
    s.querySelectorAll('[data-at]').forEach(x => x.classList.toggle('shown', st >= +x.dataset.at));
    s.querySelectorAll('[data-only]').forEach(x => x.classList.toggle('shown', st === +x.dataset.only));
    s.querySelectorAll('[data-lit]').forEach(x => x.classList.toggle('lit', st >= +x.dataset.lit));
    s.querySelectorAll('[data-is]').forEach(x => x.classList.toggle('on', st === +x.dataset.is));
    const phase = phaseMode ? st : +(s.dataset.phase || 0), shot = phaseMode ? PHASE_SHOT[st] : (s.dataset.cam || 'full');
    W.set(phase, shot, +(s.dataset.pad || 0), instant);
    document.body.dataset.slide = D.i; document.body.dataset.step = st;
    const prog = document.getElementById('prog'); if (prog) [...prog.children].forEach((b, k) => b.classList.toggle('on', k === D.i));
    const nt = document.getElementById('notes'); if (nt) nt.textContent = s.dataset.notes || '';
    history.replaceState(null, '', '#' + (D.i + 1) + (st ? '.' + st : ''));
    document.dispatchEvent(new CustomEvent('deckchange', { detail: { slide: D.i, step: st } }));
  };

  window.World = W; window.Deck = D;
})();
