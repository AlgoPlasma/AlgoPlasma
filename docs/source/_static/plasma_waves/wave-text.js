/* Match canvas annotations to the large, semibold presentation text. */
(() => {
  'use strict';
  function label(ctx, value, x, y, color, size, align = 'center') {
    size = Math.max(size, matchMedia('(max-width: 700px)').matches ? 20 : 26);
    ctx.font = `600 ${size}px "Segoe UI","Microsoft YaHei","PingFang SC",sans-serif`;
    ctx.fillStyle = color; ctx.textAlign = align; ctx.textBaseline = 'middle';
    const scale = ctx.getTransform().a || 1;
    const width = ctx.canvas.width / scale, height = ctx.canvas.height / scale;
    const lines = [], words = String(value).split(/(?<=\s)|(?=[\u3400-\u9fff])/u);
    let line = '';
    for (const word of words) {
      if (line && ctx.measureText(line + word).width > width - 12) { lines.push(line.trim()); line = word; }
      else line += word;
    }
    lines.push(line.trim());
    const lineHeight = size * 1.25, blockHeight = lines.length * lineHeight;
    const top = Math.max(2, Math.min(height - blockHeight - 2, y - blockHeight / 2));
    lines.forEach((text, i) => {
      const textWidth = ctx.measureText(text).width;
      const before = align === 'right' ? textWidth : align === 'center' ? textWidth / 2 : 0;
      const after = textWidth - before;
      const anchor = Math.max(6 + before, Math.min(width - 6 - after, x));
      ctx.fillText(text, anchor, top + (i + .5) * lineHeight);
    });
  }
  window.PlasmaText = { label };
})();
