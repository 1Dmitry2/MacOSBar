(() => {
  const island = document.getElementById('island');
  const dock = document.getElementById('nook-dock');
  const macShell = document.getElementById('mac-shell');
  const modeButtons = document.querySelectorAll('.mode');
  const themeBtn = document.getElementById('theme-toggle');

  let mode = 'idle';
  let section = 'music';
  let pinned = false;

  const sampleTrack = {
    title: 'Эксперимент · неделя на ресурсах одного дня',
    artist: 'PollmixaN',
  };

  function waveHTML() {
    return '<span class="wave" aria-hidden="true"><i></i><i></i><i></i><i></i></span>';
  }

  function renderIdle() {
    return `<div class="island-inner idle-row">
      <span class="art"></span>
      ${waveHTML()}
    </div>`;
  }

  function renderHover() {
    return `<div class="island-inner hover-row">
      <span class="art"></span>
      <div class="music-meta"><strong>${sampleTrack.title}</strong><small>${sampleTrack.artist}</small></div>
      <div class="hover-metrics"><span class="pill-stat">CPU 15%</span><span class="pill-stat">RAM 64%</span></div>
    </div>`;
  }

  function renderMusic() {
    return `<div class="island-inner">
      <div class="panel-row">
        <span class="art lg"></span>
        <div class="music-meta"><strong>${sampleTrack.title}</strong><small>${sampleTrack.artist}</small></div>
      </div>
      <div class="controls">
        <button type="button" aria-label="Назад">⏮</button>
        <button type="button" class="play" aria-label="Пауза">⏸</button>
        <button type="button" aria-label="Вперёд">⏭</button>
      </div>
      <p style="margin:0;font-size:12px;color:rgba(255,255,255,.65)">Вывод · MacBook Air · ✓ Наушники</p>
    </div>`;
  }

  function renderFocus() {
    return `<div class="island-inner">
      <div style="display:flex;gap:8px;align-items:center"><span class="badge">Концентрация</span><span class="focus-time">25:00</span></div>
      <div class="controls"><button type="button" class="play" style="width:auto;padding:0 16px;border-radius:999px">Запустить таймер</button></div>
    </div>`;
  }

  function renderMonitor() {
    return `<div class="island-inner">
      <div class="monitor-grid">
        <div class="metric">CPU <b>15%</b></div>
        <div class="metric">RAM <b>64%</b></div>
        <div class="metric">Диск <b>61%</b></div>
        <div class="metric">Сеть <b>1.2 MB/s</b></div>
      </div>
    </div>`;
  }

  function renderMic() {
    return `<div class="island-inner panel-row"><span class="badge">Микрофон</span><strong>Используется</strong><span class="pill-stat">Core Audio</span></div>`;
  }

  function renderHeadphones() {
    return `<div class="island-inner panel-row"><span class="badge">Наушники</span><strong>Внешние наушники</strong></div>`;
  }

  function renderExpanded() {
    if (section === 'focus') return renderFocus();
    if (section === 'monitor') return renderMonitor();
    if (section === 'calendar') {
      return `<div class="island-inner"><p style="margin:0">События из Calendar · ближайшие 7 дней</p></div>`;
    }
    return renderMusic();
  }

  function apply() {
    const expanded = mode === 'expanded' || mode === 'music' || mode === 'mic' || mode === 'headphones';
    island.dataset.state = mode === 'expanded' ? 'expanded' : mode;
    dock.classList.toggle('hidden', !expanded);
    dock.setAttribute('aria-hidden', String(!expanded));

    if (mode === 'idle') island.innerHTML = renderIdle();
    else if (mode === 'hover') island.innerHTML = renderHover();
    else if (mode === 'music') island.innerHTML = renderMusic();
    else if (mode === 'mic') island.innerHTML = renderMic();
    else if (mode === 'headphones') island.innerHTML = renderHeadphones();
    else island.innerHTML = renderExpanded();

    modeButtons.forEach((btn) => btn.classList.toggle('on', btn.dataset.mode === mode));
    dock.querySelectorAll('button').forEach((btn) => {
      btn.classList.toggle('on', btn.dataset.section === section);
    });
  }

  modeButtons.forEach((btn) => {
    btn.addEventListener('click', () => {
      mode = btn.dataset.mode;
      pinned = mode !== 'idle' && mode !== 'hover';
      apply();
    });
  });

  dock.addEventListener('click', (e) => {
    const btn = e.target.closest('button[data-section]');
    if (!btn) return;
    section = btn.dataset.section;
    mode = 'expanded';
    pinned = true;
    apply();
  });

  island.addEventListener('click', () => {
    if (pinned) {
      mode = 'idle';
      pinned = false;
    } else {
      mode = mode === 'idle' ? 'expanded' : 'idle';
      pinned = mode === 'expanded';
    }
    apply();
  });

  macShell.addEventListener('mouseenter', () => {
    if (!pinned && mode === 'idle') {
      mode = 'hover';
      apply();
    }
  });
  macShell.addEventListener('mouseleave', () => {
    if (!pinned && mode === 'hover') {
      mode = 'idle';
      apply();
    }
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

  apply();
})();
