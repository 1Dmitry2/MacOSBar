(() => {
  const compact = document.getElementById('island');
  const expanded = document.getElementById('island-expanded');
  if (!compact || !expanded) return;

  let open = false;
  const toggle = () => {
    open = !open;
    compact.classList.toggle('hidden', open);
    expanded.classList.toggle('hidden', !open);
    compact.setAttribute('aria-expanded', String(open));
    expanded.setAttribute('aria-hidden', String(!open));
  };

  compact.addEventListener('click', toggle);
  compact.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      toggle();
    }
  });
  document.getElementById('island-expanded')?.addEventListener('click', toggle);
})();
