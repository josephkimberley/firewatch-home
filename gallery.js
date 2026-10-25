// Artwork only: no analytics, service connections, or automatic animation.
for (const scene of document.querySelectorAll('.scene')) {
  const stage = scene.querySelector('.stage');
  const full = scene.querySelector('.full-view');
  const selection = scene.querySelector('.selection');
  const label = scene.querySelector('.time-label');
  const reset = scene.querySelector('.reset');
  const open = scene.querySelector('.open-art');
  const slices = [...scene.querySelectorAll('.slice')];
  let pinned = null;
  let generation = 0;
  function show(slice) {
    const token = ++generation;
    const {full: path, thumb, period} = slice.dataset;
    full.src = thumb;
    full.alt = `${scene.dataset.title} — ${period}`;
    full.hidden = false;
    stage.classList.add('previewing');
    selection.textContent = period;
    label.textContent = period;
    open.href = path;
    open.textContent = `Open ${period} artwork ↗`;
    reset.hidden = false;
    for (const item of slices) item.setAttribute('aria-current', String(item === pinned));
    const image = new Image();
    image.onload = () => { if (generation === token) full.src = path; };
    image.src = path;
  }
  function overview() {
    ++generation;
    full.hidden = true;
    full.removeAttribute('src');
    stage.classList.remove('previewing');
    selection.textContent = 'Dawn → Night';
    label.textContent = '';
    reset.hidden = true;
    for (const item of slices) item.removeAttribute('aria-current');
  }
  for (const slice of slices) {
    slice.addEventListener('pointerenter', e => { if (e.pointerType !== 'touch') show(slice); });
    slice.addEventListener('focus', () => show(slice));
    slice.addEventListener('click', e => {
      if (e.ctrlKey || e.metaKey || e.shiftKey || e.altKey) return;
      e.preventDefault(); pinned = slice; show(slice);
    });
  }
  stage.addEventListener('pointerleave', () => { if (pinned) show(pinned); else overview(); });
  scene.addEventListener('keydown', e => {
    if (e.key === 'Escape') { pinned = null; overview(); }
    const index = slices.indexOf(document.activeElement);
    if (index !== -1 && ['ArrowRight','ArrowLeft'].includes(e.key)) {
      e.preventDefault(); slices[(index + (e.key === 'ArrowRight' ? 1 : 6)) % 7].focus();
    }
  });
  reset.addEventListener('click', () => { pinned = null; overview(); });
}
