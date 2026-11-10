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

  const NOOK_SRC = {
    music: 'assets/screenshots/nook-music.png',
    pulse: 'assets/screenshots/nook-pulse.png',
    focus: 'assets/screenshots/nook-focus.png',
    calendar: 'assets/screenshots/nook-calendar.png',
  };

  const NOOK = [
    { mode: 'music', src: NOOK_SRC.music, label: 'Музыка' },
    { mode: 'pulse', src: NOOK_SRC.pulse, label: 'Пульс' },
    { mode: 'focus', src: NOOK_SRC.focus, label: 'Фокус' },
    { mode: 'calendar', src: NOOK_SRC.calendar, label: 'Календарь' },
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

  /* ——— UI sounds (Web Audio, Alcove-style micro-feedback) ——— */
  let audioCtx = null;
  let soundOn = true;

  function ensureAudio() {
    if (!audioCtx) audioCtx = new (window.AudioContext || window.webkitAudioContext)();
    if (audioCtx.state === 'suspended') audioCtx.resume();
    return audioCtx;
  }

  function tone(freq, duration, type = 'sine', gain = 0.08) {
    if (!soundOn) return;
    const ctx = ensureAudio();
    const o = ctx.createOscillator();
    const g = ctx.createGain();
    o.type = type;
    o.frequency.value = freq;
    g.gain.setValueAtTime(gain, ctx.currentTime);
    g.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + duration);
    o.connect(g);
    g.connect(ctx.destination);
    o.start();
    o.stop(ctx.currentTime + duration);
  }

  const sfx = {
    click: () => tone(520, 0.06, 'sine', 0.06),
    tab: () => tone(380, 0.05, 'triangle', 0.05),
    expand: () => {
      tone(220, 0.12, 'sine', 0.07);
      setTimeout(() => tone(440, 0.14, 'sine', 0.05), 40);
    },
    collapse: () => tone(320, 0.1, 'sine', 0.05),
    tray: () => tone(660, 0.07, 'sine', 0.06),
    minimize: () => tone(180, 0.15, 'triangle', 0.06),
    restore: () => tone(500, 0.1, 'sine', 0.07),
  };

  function wireSoundToggle() {
    const btn = document.getElementById('sound-toggle');
    if (!btn) return;
    btn.addEventListener('click', () => {
      soundOn = !soundOn;
      btn.classList.toggle('on', soundOn);
      btn.setAttribute('aria-pressed', String(soundOn));
      btn.textContent = soundOn ? 'Звук вкл' : 'Звук выкл';
      if (soundOn) sfx.click();
    });
  }

  function shotHTML(src, alt) {
    return `<div class="shot-frame shot-enter" data-shot><img src="${src}" alt="${alt}" loading="lazy" decoding="async"/></div>`;
  }

  const views = {
    overview: () => shotHTML(SHOTS.overview, 'Обзор MacOSHub'),
    cleaner: () => shotHTML(SHOTS.cleaner, 'Умная очистка'),
    monitor: () => shotHTML(SHOTS.monitor, 'Мониторинг системы'),
    device: () => shotHTML(SHOTS.device, 'Управление устройствами'),
    island: () => `
      <div class="panel-scroll island-panel">
        <p class="island-lead">Настройки острова в приложении — режимы Nook переключаются под чёлкой в демо выше.</p>
        ${shotHTML(SHOTS.island, 'Настройки Dynamic Island')}
        ${shotHTML('assets/screenshots/island-behavior.png', 'Поведение острова')}
      </div>`,
    diagnostics: () => shotHTML(SHOTS.diagnostics, 'Диагностика'),
    settings: () => `
      <div class="panel-scroll settings-stack">
        ${shotHTML(SHOTS.settings, 'Настройки приложения')}
        ${shotHTML('assets/screenshots/settings-hotkeys.png', 'Горячие клавиши')}
      </div>`,
  };

  function renderView() {
    main.innerHTML = views[view]();
    main.dataset.view = view;
    sidebar.querySelectorAll('.nav-item').forEach((el) => {
      el.classList.toggle('on', el.dataset.view === view);
    });
    bindShotZoom();
  }

  function bindShotZoom() {
    main.querySelectorAll('[data-shot] img').forEach((img) => {
      img.addEventListener('click', () => openLightbox(img.src, img.alt));
    });
  }

  function openLightbox(src, alt) {
    sfx.click();
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
    sfx.tab();
  });

  function initMacDemo() {
    const chassis = document.getElementById('mac-chassis');
    const island = document.getElementById('island');
    const islandExpanded = document.getElementById('island-expanded');
    const islandCompact = document.getElementById('island-compact');
    const islandShot = document.getElementById('island-shot');
    const trayBtn = document.getElementById('tray-btn');
    const trayPanel = document.getElementById('tray-panel');
    const hubWindow = document.getElementById('app-window');
    const hubMin = document.getElementById('hub-minimize');
    const hubDock = document.getElementById('hub-dock');
    const mbClock = document.getElementById('mb-clock');
    const mbCpu = document.getElementById('mb-cpu');
    let nookMode = 'music';
    let islandOpen = false;

    const setNookMode = (mode) => {
      nookMode = mode;
      if (islandShot && NOOK_SRC[mode]) islandShot.src = NOOK_SRC[mode];
      document.querySelectorAll('.nook-mode').forEach((b) => {
        const on = b.dataset.mode === mode;
        b.classList.toggle('on', on);
        b.setAttribute('aria-selected', on ? 'true' : 'false');
      });
    };

    document.querySelectorAll('.nook-mode').forEach((btn) => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        setNookMode(btn.dataset.mode);
        if (!islandOpen) openIsland();
        else sfx.tab();
      });
    });

    const openIsland = () => {
      islandOpen = true;
      island.classList.add('open');
      island.setAttribute('aria-expanded', 'true');
      islandCompact.hidden = true;
      islandExpanded.hidden = false;
      sfx.expand();
    };

    const closeIsland = () => {
      islandOpen = false;
      island.classList.remove('open');
      island.setAttribute('aria-expanded', 'false');
      islandCompact.hidden = false;
      islandExpanded.hidden = true;
      sfx.collapse();
    };

    island?.addEventListener('click', (e) => {
      e.stopPropagation();
      ensureAudio();
      if (islandOpen) closeIsland();
      else openIsland();
    });

    trayBtn?.addEventListener('click', (e) => {
      e.stopPropagation();
      ensureAudio();
      const open = trayPanel?.hidden;
      if (trayPanel) trayPanel.hidden = !open;
      trayBtn.setAttribute('aria-expanded', open ? 'true' : 'false');
      trayBtn.classList.toggle('active', open);
      if (open) sfx.tray();
    });

    document.addEventListener('click', () => {
      if (trayPanel && !trayPanel.hidden) {
        trayPanel.hidden = true;
        trayBtn?.setAttribute('aria-expanded', 'false');
        trayBtn?.classList.remove('active');
      }
    });
    trayPanel?.addEventListener('click', (e) => e.stopPropagation());

    hubMin?.addEventListener('click', (e) => {
      e.stopPropagation();
      hubWindow?.classList.add('minimized');
      hubDock?.removeAttribute('hidden');
      sfx.minimize();
    });
    hubDock?.addEventListener('click', () => {
      hubWindow?.classList.remove('minimized');
      hubDock?.setAttribute('hidden', '');
      sfx.restore();
    });

    chassis?.addEventListener('click', () => ensureAudio(), { once: true });

    const tickClock = () => {
      if (!mbClock) return;
      const d = new Date();
      mbClock.textContent = d.toLocaleTimeString('ru-RU', { hour: '2-digit', minute: '2-digit' });
    };
    tickClock();
    setInterval(tickClock, 15_000);

    const jitterCpu = () => {
      if (!mbCpu) return;
      const v = (8 + Math.random() * 18).toFixed(1);
      mbCpu.textContent = `CPU ${v}%`;
    };
    jitterCpu();
    setInterval(jitterCpu, 2200);
  }

  modulesGrid.innerHTML =
    '<h2 class="section-title-anim">Все модули MacOSHub</h2><div class="feat-grid">' +
    modules
      .map(
        (m) =>
          `<article class="feat feat-reveal" data-jump="${m.id}">
            <div class="feat-shot"><img src="${m.shot}" alt="" loading="lazy"/></div>
            <h3>${m.title}</h3>
            <p>${m.desc}</p>
            <button type="button" class="linkish">Открыть в демо →</button>
          </article>`,
      )
      .join('') +
    '</div>';

  modulesGrid.addEventListener('click', (e) => {
    const card = e.target.closest('[data-jump]');
    if (!card) return;
    view = card.dataset.jump;
    renderView();
    document.getElementById('demo')?.scrollIntoView({ behavior: 'smooth' });
    sfx.tab();
  });

  const showcaseHub = document.getElementById('showcase-hub');
  const showcaseIsland = document.getElementById('showcase-island');
  if (showcaseHub && showcaseIsland) {
    const hubShots = modules.map((m) => ({ src: m.shot, label: m.title }));
    const islandShots = [
      ...NOOK.map((n) => ({ src: n.src, label: n.label })),
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
        sfx.tab();
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
    sfx.click();
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
  initMacDemo();
  wireSoundToggle();
})();
