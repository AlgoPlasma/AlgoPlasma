/* Preserve bookmarks made before the introductory lessons were combined. */
(() => {
  const link = document.getElementById('lesson-link');
  const target = new URL(link.href);
  target.search = location.search;
  const offset = Number(link.dataset.offset);
  const match = /^#slide-(\d+)-step-(\d+)$/.exec(location.hash);
  if (offset && match) {
    target.hash = 'slide-' + (Number(match[1]) + offset) + '-step-' + match[2];
  } else if (!offset || !target.hash) {
    target.hash = location.hash;
  }
  location.replace(target.href);
})();
