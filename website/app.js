(() => {
  const main = document.getElementById('app-main');
  const sidebar = document.querySelector('.app-sidebar');
  const modulesGrid = document.querySelector('.modules-grid');
  const themeBtn = document.getElementById('theme-toggle');
  let view = 'overview';

  const SHOTS = {
    overview: 'assets/screenshots/overview.png',
    cleaner: 'assets/screenshots/cleaner.png',
    monitor: 'assets/screenshots/monitor.png',
    device: 'assets/screenshots/device.png',
    island: 'assets/screenshots/island-settings.png',
    diagnostics: 'assets/screenshots/diagnostics.png',
    settings: 'assets/screenshots/settings-general.png',
  };

  const NOOK = [
    { src: 'assets/screenshots/nook-music.png', label: 'Музыка' },
    { src: 'assets/screenshots/nook-pulse.png', label: 'Пульс' },
    { src: 'assets/screenshots/nook-focus.png', label: 'Фокус' },
    { src: 'assets/screenshots/nook-calendar.png', label: 'Календарь' },
  ];

  const modules = [
    { id: 'overview', title: 'Обзор', desc: 'Модель Mac, CPU/RAM/диск и переключатели модулей.', shot: SHOTS.overview },
    { id: 'cleaner', title: 'Умная очистка', desc: 'Allowlist, превью, свои папки — без Documents и Keychain.', shot: SHOTS.cleaner },
    { id: 'monitor', title: 'Мониторинг', desc: 'Графики CPU/RAM, диск и температура (где доступно).', shot: SHOTS.monitor },
    { id: 'device', title: 'Устройства', desc: 'Блокировка клавиатуры и трекпада, ⌘⌘ emergency unlock.', shot: SHOTS.device },
    { id: 'island', title: 'Dynamic Island', desc: 'Nook, жидкое стекло, музыка, фокус, календарь.', shot: SHOTS.island },
    { id: 'diagnostics', title: 'Диагностика', desc: 'Журнал Hub, экспорт и очистка.', shot: SHOTS.diagnostics },
    { id: 'settings', title: 'Настройки', desc: 'Язык, автозапуск, хоткеи, разрешения.', shot: SHOTS.settings },
  ];

  function shotHTML(src, alt) {
    return `<div class="shot-frame shot-enter" data-shot><img src="${src}" alt="${alt}" loading="lazy" decoding="async"/></div>`;
  }

  const views = {
    overview: () => shotHTML(SHOTS.overview, 'Обзор MacOSHub'),
    cleaner: () => shotHTML(SHOTS.cleaner, 'Умная очистка'),
    monitor: () => shotHTML(SHOTS.monitor, 'Мониторинг системы'),
    device: () => shotHTML(SHOTS.device, 'Управление устройствами'),
    island: () => `
      <header class="panel-head island-head">
        <h2>Dynamic Island</h2>
        <span class="pill green">Активен</span>
      </header>
      <div class="panel-scroll island-panel">
        <p class="island-lead">Настройки в приложении и живой Nook под чёлкой — переключай режимы.</p>
        <div class="nook-track" role="tablist" aria-label="Режимы Nook">
          ${NOOK.map(
            (n, i) =>
              `<button type="button" class="nook-thumb${i === 0 ? ' on' : ''}" data-nook="${n.src}" role="tab" aria-selected="${i === 0}">
                <img src="${n.src}" alt="${n.label}" loading="lazy"/>
                <span>${n.label}</span>
              </button>`,
          ).join('')}
        </div>
        <div class="nook-stage shot-enter" id="nook-stage">
          <img src="${NOOK[0].src}" alt="${NOOK[0].label}" id="nook-hero"/>
        </div>
        ${shotHTML(SHOTS.island, 'Настройки Dynamic Island')}
      </div>`,
    diagnostics: () => shotHTML(SHOTS.diagnostics, 'Диагностика'),
    settings: () => `
      <div class="panel-scroll settings-stack">
        ${shotHTML(SHOTS.settings, 'Настройки приложения')}
        ${shotHTML('assets/screenshots/settings-hotkeys.png', 'Горячие клавиши и разрешения')}
      </div>`,
  };

  function bindNook() {
    const hero = document.getElementById('nook-hero');
    const stage = document.getElementById('nook-stage');
    if (!hero || !stage) return;
    document.querySelectorAll('[data-nook]').forEach((btn) => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('[data-nook]').forEach((b) => {
          b.classList.remove('on');
          b.setAttribute('aria-selected', 'false');
        });
        btn.classList.add('on');
        btn.setAttribute('aria-selected', 'true');
        stage.classList.remove('shot-enter');
        void stage.offsetWidth;
        stage.classList.add('shot-enter');
        hero.src = btn.dataset.nook;
        hero.alt = btn.querySelector('span')?.textContent || '';
      });
    });
  }

  function renderView() {
    main.innerHTML = views[view]();
    main.dataset.view = view;
    sidebar.querySelectorAll('.nav-item').forEach((el) => {
      el.classList.toggle('on', el.dataset.view === view);
    });
    if (view === 'island') bindNook();
    bindShotZoom();
  }

  function bindShotZoom() {
    main.querySelectorAll('[data-shot] img').forEach((img) => {
      img.addEventListener('click', () => openLightbox(img.src, img.alt));
    });
  }

  function openLightbox(src, alt) {
    const lb = document.createElement('div');
    lb.className = 'lightbox';
    lb.innerHTML = `<button type="button" class="lightbox-x" aria-label="Закрыть">×</button><img src="${src}" alt="${alt || ''}"/>`;
    const close = () => {
      lb.classList.add('out');
      setTimeout(() => lb.remove(), 220);
    };
    lb.addEventListener('click', (e) => {
      if (e.target === lb || e.target.closest('.lightbox-x')) close();
    });
    document.addEventListener('keydown', function esc(ev) {
      if (ev.key === 'Escape') {
        close();
        document.removeEventListener('keydown', esc);
      }
    });
    document.body.appendChild(lb);
    requestAnimationFrame(() => lb.classList.add('in'));
  }

  sidebar.addEventListener('click', (e) => {
    const btn = e.target.closest('.nav-item[data-view]');
    if (!btn) return;
    view = btn.dataset.view;
    renderView();
  });

  modulesGrid.innerHTML =
    '<h2 class="section-title-anim">Все модули MacOSHub</h2><div class="feat-grid">' +
    modules
      .map(
        (m) =>
          `<article class="feat feat-reveal" data-jump="${m.id}">
            <div class="feat-shot"><img src="${m.shot}" alt="" loading="lazy"/></div>
            <h3>${m.title}</h3>
            <p>${m.desc}</p>
            <button type="button" class="linkish">Открыть в витрине →</button>
          </article>`,
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

  const showcaseHub = document.getElementById('showcase-hub');
  const showcaseIsland = document.getElementById('showcase-island');
  if (showcaseHub && showcaseIsland) {
    const hubShots = modules.map((m) => ({ src: m.shot, label: m.title }));
    const islandShots = [
      ...NOOK,
      { src: SHOTS.island, label: 'Настройки' },
      { src: 'assets/screenshots/island-behavior.png', label: 'Поведение' },
      { src: 'assets/screenshots/menubar-panel.png', label: 'Меню-бар' },
    ];
    const paint = (el, items) => {
      el.innerHTML = items
        .map(
          (item) =>
            `<figure class="showcase-card feat-reveal"><button type="button" class="showcase-open" data-full="${item.src}">
              <img src="${item.src}" alt="${item.label}" loading="lazy"/>
            </button><figcaption>${item.label}</figcaption></figure>`,
        )
        .join('');
    };
    paint(showcaseHub, hubShots);
    paint(showcaseIsland, islandShots);
    document.querySelectorAll('.showcase-tabs button').forEach((tab) => {
      tab.addEventListener('click', () => {
        const target = tab.dataset.tab;
        document.querySelectorAll('.showcase-tabs button').forEach((t) => t.classList.toggle('on', t === tab));
        showcaseHub.hidden = target !== 'hub';
        showcaseIsland.hidden = target !== 'island';
      });
    });
    document.body.addEventListener('click', (e) => {
      const btn = e.target.closest('.showcase-open');
      if (!btn) return;
      const img = btn.querySelector('img');
      openLightbox(btn.dataset.full, img?.alt);
    });
  }

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

  const io = new IntersectionObserver(
    (entries) => {
      entries.forEach((en) => {
        if (en.isIntersecting) en.target.classList.add('visible');
      });
    },
    { threshold: 0.12, rootMargin: '0px 0px -40px 0px' },
  );
  document.querySelectorAll('.feat-reveal, .section-title-anim').forEach((el) => io.observe(el));

  renderView();
})();
