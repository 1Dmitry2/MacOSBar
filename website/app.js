const scene = document.getElementById('scene');
const unlock = document.getElementById('unlock');
const islandWrap = document.getElementById('island-wrap');
const islandPill = document.getElementById('island-pill');
const islandPanel = document.getElementById('island-panel');
const nookSwitch = document.getElementById('nook-switch');
const hubWin = document.getElementById('hub-win');
const hubSide = document.getElementById('hub-side');
const hubMain = document.getElementById('hub-main');
const hubClose = document.getElementById('hub-close');
const dockIcon = document.getElementById('dock-icon');
const trayBtn = document.getElementById('mb-tray');
const trayPop = document.getElementById('tray-pop');
const trayOpenHub = document.getElementById('tray-open-hub');
const scenePsst = document.getElementById('scene-psst');
const mbTime = document.getElementById('mb-time');
const mbCpu = document.getElementById('mb-cpu');
const chipTemp = document.getElementById('chip-temp');
const featGrid = document.getElementById('feat-grid');

let audioCtx = null;
let islandOpen = false;
let hubView = 'overview';
let nookMode = 'music';

function ensureAudio() {
  if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
  if (audioCtx.state === 'suspended') audioCtx.resume();
  return audioCtx;
}

function play(freq, dur = 0.08, type = 'sine', gain = 0.07) {
  const ctx = ensureAudio();
  const o = ctx.createOscillator();
  const g = ctx.createGain();
  o.type = type;
  o.frequency.value = freq;
  g.gain.setValueAtTime(gain, ctx.currentTime);
  g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + dur);
  o.connect(g);
  g.connect(ctx.destination);
  o.start();
  o.stop(ctx.currentTime + dur);
}

const sfx = {
  unlock: () => {
    play(220, 0.1);
    setTimeout(() => play(523, 0.12), 60);
    setTimeout(() => play(784, 0.15, 'sine', 0.05), 120);
  },
  tap: () => play(520, 0.05, 'sine', 0.05),
  expand: () => {
    play(330, 0.08);
    setTimeout(() => play(440, 0.12), 40);
  },
  collapse: () => play(280, 0.1),
  tab: () => play(400, 0.05, 'triangle', 0.04),
};

const nookPanels = {
  music: () => `
    <div class="row">
      <div class="art-lg"></div>
      <div><strong>Сейчас играет</strong><div style="opacity:.7;font-size:.85rem">Dancin (demo)</div></div>
    </div>
    <div class="eq"><i></i><i></i><i></i><i></i><i></i><i></i></div>
    <p style="opacity:.6;font-size:.75rem;margin:.75rem 0 0">MediaRemote · play / pause в приложении</p>`,
  pulse: () => `
    <motion div style="display:flex;gap:1rem;flex-wrap:wrap">
      <motion div><small style="opacity:.6">CPU</small><div style="font-size:1.5rem;font-weight:800">12%</div></motion>
      <motion div><small style="opacity:.6">RAM</small><div style="font-size:1.5rem;font-weight:800">56%</div></motion>
      <motion div><small style="opacity:.6">Батарея</small><div style="font-size:1.5rem;font-weight:800">72%</div></motion>
    </div>`,
  focus: () => `
    <div style="text-align:center">
      <span style="font-size:.8rem;opacity:.7">Концентрация</span>
      <div style="font-size:2.5rem;font-weight:800;color:#ffb366">25:00</div>
      <button type="button" style="margin-top:.5rem;border:none;background:rgba(255,143,76,.25);color:#fff;padding:.4rem 1rem;border-radius:999px;font-weight:600">Запустить</button>
    </div>`,
  calendar: () => `
    <div style="display:flex;justify-content:space-between;gap:1rem">
      <div><strong>Нет событий</strong><p style="opacity:.65;font-size:.8rem">Следующие 7 дней</p></div>
      <motion div style="font-size:.75rem;opacity:.8"><div style="color:#c4b5fd;font-weight:800">НОЯ</div>11 · 12 · 13</motion>
    </div>`,
};

// fix motion div typos in templates
nookPanels.pulse = () => `
  <div style="display:flex;gap:1rem;flex-wrap:wrap">
    <div><small style="opacity:.6">CPU</small><div style="font-size:1.5rem;font-weight:800">12%</div></div>
    <div><small style="opacity:.6">RAM</small><div style="font-size:1.5rem;font-weight:800">56%</div></div>
    <div><small style="opacity:.6">Батарея</small><div style="font-size:1.5rem;font-weight:800">72%</div></div>
  </div>`;
nookPanels.calendar = () => `
  <div style="display:flex;justify-content:space-between;gap:1rem">
    <div><strong>Нет событий</strong><p style="opacity:.65;font-size:.8rem">Следующие 7 дней</p></div>
    <div style="font-size:.75rem;opacity:.8"><div style="color:#c4b5fd;font-weight:800">НОЯ</div>11 · 12 · 13</div>
  </div>`;

const hubNav = [
  { id: 'overview', label: 'Обзор' },
  { id: 'cleaner', label: 'Очистка' },
  { id: 'monitor', label: 'Мониторинг' },
  { id: 'device', label: 'Устройства' },
  { id: 'island', label: 'Island' },
  { id: 'settings', label: 'Настройки' },
];

const hubViews = {
  overview: () => `
    <h3>Обзор</h3>
    <p style="opacity:.65;margin-bottom:.75rem">MacBook Air · Apple M3 · 16 GB</p>
    <div class="metric-row">
      <article class="metric-card"><span style="opacity:.6">CPU</span><strong>14%</strong></article>
      <article class="metric-card"><span style="opacity:.6">RAM</span><strong>8.2 GB</strong></article>
      <article class="metric-card"><span style="opacity:.6">Диск</span><strong>61%</strong></article>
      <article class="metric-card"><span style="opacity:.6">Island</span><strong style="color:#6ee78d">Вкл</strong></article>
    </div>`,
  cleaner: () => `
    <h3>Умная очистка</h3>
    <p style="opacity:.65">Безопасные кэши · 0 KB готово</p>
    <button type="button" style="margin-top:1rem;border:none;background:#7c5cff;color:#fff;padding:.5rem 1rem;border-radius:.5rem;font-weight:600">Начать сканирование</button>`,
  monitor: () => `<h3>Мониторинг</h3><p>CPU 14% · RAM 56% · графики в реальном приложении</p>`,
  device: () => `<h3>Устройства</h3><p>Блокировка клавиатуры / трекпада · ⌘⌘ emergency unlock</p>`,
  island: () => `<h3>Dynamic Island</h3><p>Живой Nook над обоями — переключай режимы внизу сцены.</p>`,
  settings: () => `<h3>Настройки</h3><p>Язык · автозапуск · хоткеи ⌘⌃D</p>`,
};

function renderHub() {
  hubSide.innerHTML = hubNav
    .map((n) => `<button type="button" data-v="${n.id}" class="${n.id === hubView ? 'on' : ''}">${n.label}</button>`)
    .join('');
  hubMain.innerHTML = hubViews[hubView]?.() || '';
  hubSide.querySelectorAll('button').forEach((b) => {
    b.addEventListener('click', () => {
      hubView = b.dataset.v;
      renderHub();
      sfx.tab();
    });
  });
}

function setNook(mode) {
  nookMode = mode;
  nookSwitch.querySelectorAll('button').forEach((b) => b.classList.toggle('on', b.dataset.mode === mode));
  if (islandOpen) islandPanel.innerHTML = nookPanels[mode]();
}

function openIsland() {
  islandOpen = true;
  islandPill.setAttribute('aria-expanded', 'true');
  islandPanel.hidden = false;
  islandPanel.innerHTML = nookPanels[nookMode]();
  sfx.expand();
}

function closeIsland() {
  islandOpen = false;
  islandPill.setAttribute('aria-expanded', 'false');
  islandPanel.hidden = true;
  sfx.collapse();
}

function unlockScene() {
  scene.dataset.locked = 'false';
  islandWrap.hidden = false;
  nookSwitch.hidden = false;
  hubWin.hidden = false;
  scenePsst.hidden = false;
  trayBtn.disabled = false;
  renderHub();
  sfx.unlock();
  openIsland();
}

unlock.addEventListener('click', () => {
  ensureAudio();
  unlockScene();
});

islandPill.addEventListener('click', (e) => {
  e.stopPropagation();
  ensureAudio();
  if (islandOpen) closeIsland();
  else openIsland();
});

nookSwitch.querySelectorAll('button').forEach((btn) => {
  btn.addEventListener('click', (e) => {
    e.stopPropagation();
    ensureAudio();
    setNook(btn.dataset.mode);
    if (!islandOpen) openIsland();
    else sfx.tab();
  });
});

trayBtn.addEventListener('click', (e) => {
  e.stopPropagation();
  ensureAudio();
  const show = trayPop.hidden;
  trayPop.hidden = !show;
  trayBtn.classList.toggle('active', show);
  if (show) sfx.tap();
});

document.addEventListener('click', () => {
  if (!trayPop.hidden) {
    trayPop.hidden = true;
    trayBtn.classList.remove('active');
  }
});
trayPop.addEventListener('click', (e) => e.stopPropagation());

trayOpenHub.addEventListener('click', () => {
  hubWin.classList.remove('minimized');
  dockIcon.hidden = true;
  sfx.tap();
});
trayPop.querySelectorAll('[data-hub]').forEach((b) => {
  b.addEventListener('click', () => {
    hubView = b.dataset.hub;
    renderHub();
    hubWin.classList.remove('minimized');
    dockIcon.hidden = true;
    sfx.tab();
  });
});

hubClose.addEventListener('click', () => {
  hubWin.classList.add('minimized');
  dockIcon.hidden = false;
  play(200, 0.12, 'triangle', 0.05);
});
dockIcon.addEventListener('click', () => {
  hubWin.classList.remove('minimized');
  dockIcon.hidden = true;
  play(500, 0.1);
});

featGrid.innerHTML = [
  ['🫧', 'Плавные<br/>переходы'],
  ['🔔', 'Уведомления<br/>и HUD'],
  ['〰', 'Live<br/>Activities'],
  ['👆', 'Жесты и<br/>клик'],
  ['🧹', 'Умная<br/>очистка'],
  ['📊', 'Мониторинг<br/>и трей'],
  ['⚡', 'Swift 6<br/>native'],
  ['◉', 'Nook и<br/>календарь'],
]
  .map(([ico, t]) => `<article><div class="ico">${ico}</div><h2>${t}</h2></article>`)
  .join('');

const tick = () => {
  const d = new Date();
  mbTime.textContent = d.toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' });
  chipTemp.textContent = `${12 + Math.floor(Math.random() * 8)}°`;
  mbCpu.textContent = `CPU ${(10 + Math.random() * 20).toFixed(0)}%`;
  document.querySelectorAll('.tray-metric .bar i')[0]?.style.setProperty('width', `${10 + Math.random() * 25}%`);
};
tick();
setInterval(tick, 2500);
