(() => {
  const main = document.getElementById('app-main');
  const sidebar = document.querySelector('.app-sidebar');
  const modulesGrid = document.querySelector('.modules-grid');
  const themeBtn = document.getElementById('theme-toggle');
  let view = 'overview';

  const modules = [
    { id: 'overview', title: 'Обзор', desc: 'Модель Mac, CPU/RAM/диск/температура и быстрые переключатели модулей.' },
    { id: 'cleaner', title: 'Умная очистка', desc: 'Allowlist, превью перед удалением, свои папки, безопасные пути.' },
    { id: 'monitor', title: 'Мониторинг', desc: 'Дашборд, процессы, графики, боковая панель метрик в меню-баре.' },
    { id: 'device', title: 'Устройства', desc: 'Блокировка клавиатуры и трекпада, экстренная разблокировка.' },
    { id: 'island', title: 'Dynamic Island', desc: 'Nook, жидкое стекло, музыка, фокус, календарь под чёлкой.' },
    { id: 'diagnostics', title: 'Диагностика', desc: 'Лог Hub, экспорт и очистка для отладки.' },
    { id: 'settings', title: 'Настройки', desc: 'Язык, автозапуск, остров, хоткеи, боковой монитор.' },
  ];

  function spark(vals) {
    const w = 120;
    const h = 36;
    const pts = vals.map((v, i) => `${(i / (vals.length - 1)) * w},${h - v * h}`).join(' ');
    return `<svg viewBox="0 0 ${w} ${h}" class="spark"><polyline points="${pts}" fill="none" stroke="currentColor" stroke-width="2"/></svg>`;
  }

  const views = {
    overview: () => `
      <header class="panel-head"><h2>Обзор</h2></header>
      <div class="panel-scroll">
        <div class="mac-head"><strong>MacBook Air (M3)</strong><span>macOS 15 · Apple M3 · 16 GB</span></div>
        <div class="metric-grid">
          <article class="card"><h3>CPU</h3><p class="big">15.2%</p><span>8 ядер</span>${spark([.3,.45,.35,.5,.42,.38,.55,.48,.4])}</article>
          <article class="card"><h3>Память</h3><p class="big">14.4 GB</p><span>из 16 GB · normal</span><div class="bar"><i style="width:64%"></i></div></article>
          <article class="card"><h3>Диск</h3><p class="big">61%</p><span>Macintosh HD</span><div class="bar"><i style="width:61%"></i></div></article>
          <article class="card"><h3>Температура</h3><p class="big muted">—</p><span>Apple Silicon · n/a</span></article>
        </div>
        <section class="card modules-toggle">
          <h3>Модули</h3>
          <ul class="toggle-list">
            <li><span>Dynamic Island</span><i class="on"></i></li>
            <li><span>Мониторинг</span><i class="on"></i></li>
            <li><span>Умная очистка</span><i class="on"></i></li>
            <li><span>Device Control</span><i></i></li>
          </ul>
        </section>
      </div>`,

    cleaner: () => `
      <header class="panel-head"><h2>Умная очистка</h2><button type="button" class="btn-sm accent">Сканировать</button></header>
      <div class="panel-scroll">
        <div class="stats-row"><span>Найдено: <b>2.4 GB</b></span><span>Категорий: 6</span></div>
        <ul class="clean-list">
          <li><span>Кэши пользователя</span><b>890 MB</b><label class="chk on"></label></li>
          <li><span>Логи</span><b>120 MB</b><label class="chk on"></label></li>
          <li><span>Xcode DerivedData</span><b>1.1 GB</b><label class="chk"></label></li>
          <li><span>Корзина</span><b>310 MB</b><label class="chk on"></label></li>
        </ul>
        <button type="button" class="btn-sm ghost">Добавить папку…</button>
        <p class="note">Documents / Photos / Accounts не сканируются по умолчанию.</p>
      </div>`,

    monitor: () => `
      <header class="panel-head"><h2>Мониторинг системы</h2></header>
      <div class="panel-scroll">
        <div class="chart-row">${spark([.2,.35,.5,.4,.65,.55,.48,.7,.6])}<div class="chart-label">CPU 15% · сеть 1.2 MB/s</div></div>
        <table class="proc-table"><thead><tr><th>Процесс</th><th>CPU</th><th>RAM</th></tr></thead>
          <tbody>
            <tr><td>MacOSHub</td><td>4.1%</td><td>128 MB</td></tr>
            <tr><td>WindowServer</td><td>3.8%</td><td>210 MB</td></tr>
            <tr><td>Cursor</td><td>12%</td><td>890 MB</td></tr>
          </tbody>
        </table>
        <p class="note">Меню-бар: CPU · RAM · SSD · опционально температура.</p>
      </div>`,

    device: () => `
      <header class="panel-head"><h2>Управление устройствами</h2></header>
      <div class="panel-scroll">
        <div class="card lock-card">
          <h3>Блокировка ввода</h3>
          <p>Event tap: фильтрация клавиатуры и указателя при чистке клавиатуры.</p>
          <div class="lock-row"><span>Клавиатура</span><button type="button" class="toggle-pill">OFF</button></div>
          <div class="lock-row"><span>Трекпад</span><button type="button" class="toggle-pill">OFF</button></div>
          <button type="button" class="btn-sm danger">Экстренная разблокировка</button>
        </div>
      </div>`,

    island: () => `
      <header class="panel-head"><h2>Dynamic Island</h2><span class="pill green">Активен</span></header>
      <div class="panel-scroll island-panel">
        <div class="mac-mini">
          <div class="mac-bar-mini"><span>Hub</span><div class="notch-mini"></div><span>72%</span></div>
          <div class="wall-mini"></div>
          <div class="island-mini expanded" id="island-mini">
            <div class="row"><span class="art"></span><div><b>Сейчас играет</b><small>PollmixaN</small></div></div>
            <div class="dock-mini"><span class="on">Музыка</span><span>Пульс</span><span>Фокус</span></div>
          </div>
        </div>
        <div class="island-modes">
          <button type="button" class="chip on" data-imode="music">Музыка</button>
          <button type="button" class="chip" data-imode="compact">Покой</button>
          <button type="button" class="chip" data-imode="focus">Фокус</button>
          <button type="button" class="chip" data-imode="metrics">Пульс</button>
        </div>
        <ul class="check-list">
          <li>Жидкое стекло и тинт</li>
          <li>Клик / ховер</li>
          <li>MediaRemote и вывод</li>
          <li>Фокус и календарь в Nook</li>
        </ul>
      </div>`,

    diagnostics: () => `
      <header class="panel-head"><h2>Диагностика</h2></header>
      <div class="panel-scroll">
        <pre class="log">[hub.island] Island phase idle → expanded
[hub.cleaner] Scan finished · 6 categories
[hub.metrics] Dashboard refresh 1.5s
[permissions] Accessibility: granted</pre>
        <div class="row-btns"><button type="button" class="btn-sm accent">Экспорт лога</button><button type="button" class="btn-sm ghost">Очистить</button></div>
      </div>`,

    settings: () => `
      <header class="panel-head"><h2>Настройки</h2></header>
      <div class="panel-scroll settings">
        <label class="row-set"><span>Язык</span><select><option>Русский</option><option>English</option></select></label>
        <label class="row-set"><span>Dynamic Island при старте</span><input type="checkbox" checked></label>
        <label class="row-set"><span>Live Apply настроек</span><input type="checkbox" checked></label>
        <label class="row-set"><span>Боковой монитор</span><input type="checkbox"></label>
        <label class="row-set"><span>Глобальные хоткеи</span><input type="checkbox" checked></label>
      </div>`,
  };

  function renderView() {
    main.innerHTML = views[view]();
    main.dataset.view = view;
    sidebar.querySelectorAll('.nav-item').forEach((el) => {
      el.classList.toggle('on', el.dataset.view === view);
    });
    if (view === 'island') bindIslandMini();
    if (view === 'device') bindDeviceToggles();
  }

  const islandTemplates = {
    compact: '<span class="art"></span><span class="wave-mini"></span>',
    music: '<div class="row"><span class="art"></span><div><b>Сейчас играет</b><small>PollmixaN</small></div></div><div class="dock-mini"><span class="on">Музыка</span><span>Пульс</span><span>Фокус</span></div>',
    focus: '<span class="badge">Концентрация</span><div class="focus-big">25:00</div>',
    metrics: '<ul class="metrics-mini"><li>CPU <b>15%</b></li><li>RAM <b>64%</b></li><li>Сеть <b>1.2M/s</b></li></ul>',
  };

  function bindIslandMini() {
    const island = document.getElementById('island-mini');
    if (!island) return;
    document.querySelectorAll('[data-imode]').forEach((chip) => {
      chip.addEventListener('click', () => {
        document.querySelectorAll('[data-imode]').forEach((c) => c.classList.remove('on'));
        chip.classList.add('on');
        const mode = chip.dataset.imode;
        island.className = 'island-mini ' + (mode === 'compact' ? 'compact' : 'expanded');
        island.innerHTML = islandTemplates[mode] || islandTemplates.music;
      });
    });
    island.addEventListener('click', () => {
      island.classList.toggle('compact');
      island.classList.toggle('expanded');
    });
  }

  function bindDeviceToggles() {
    document.querySelectorAll('.toggle-pill').forEach((btn) => {
      btn.addEventListener('click', () => {
        const on = btn.textContent === 'ON';
        btn.textContent = on ? 'OFF' : 'ON';
        btn.classList.toggle('on', !on);
      });
    });
  }

  sidebar.addEventListener('click', (e) => {
    const btn = e.target.closest('.nav-item[data-view]');
    if (!btn) return;
    view = btn.dataset.view;
    renderView();
  });

  modulesGrid.innerHTML =
    '<h2>Все модули MacOSHub</h2><div class="feat-grid">' +
    modules
      .map(
        (m) =>
          `<article class="feat" data-jump="${m.id}"><h3>${m.title}</h3><p>${m.desc}</p><button type="button" class="linkish">Открыть в витрине →</button></article>`,
      )
      .join('') +
    '</div>';

  modulesGrid.addEventListener('click', (e) => {
    const card = e.target.closest('[data-jump]');
    if (!card) return;
    view = card.dataset.jump;
    renderView();
    document.getElementById('playground')?.scrollIntoView({ behavior: 'smooth' });
  });

  const root = document.documentElement;
  const stored = localStorage.getItem('mactools-theme');
  if (stored) root.dataset.theme = stored;
  themeBtn.textContent = root.dataset.theme === 'dark' ? '☾' : '☀';
  themeBtn.addEventListener('click', () => {
    const next = root.dataset.theme === 'dark' ? 'light' : 'dark';
    root.dataset.theme = next;
    localStorage.setItem('mactools-theme', next);
    themeBtn.textContent = next === 'dark' ? '☾' : '☀';
  });

  renderView();
})();
