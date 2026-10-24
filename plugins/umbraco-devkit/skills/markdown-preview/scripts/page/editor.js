// Comment boxes: growing as you type, light Markdown colouring, formatting shortcuts and
// Enter to submit.
import { content, esc } from './state.js';

// ---------- colouring: a coloured copy of the text sits behind a see-through box ----------
// Matched to the box in font, padding and wrapping. Only colour changes, never weight or
// width, so the two always line up.

function hlInline(t) {
  const re = /(`[^`]+`)|(\*\*[^*]+\*\*)|(\[[^\]]+\]\([^)\s]*\))|(\b_[^_\s][^_]*_\b)/g;
  let out = '', i = 0, m;
  const mark = x => '<span class="hm">' + esc(x) + '</span>';
  while ((m = re.exec(t))) {
    const s = m[0];
    out += esc(t.slice(i, m.index));
    if (m[1]) out += mark('`') + '<span class="hc">' + esc(s.slice(1, -1)) + '</span>' + mark('`');
    else if (m[2]) out += mark('**') + '<span class="hb">' + esc(s.slice(2, -2)) + '</span>' + mark('**');
    else if (m[3]) {
      const k = s.indexOf('](');
      out += mark('[') + '<span class="hl">' + esc(s.slice(1, k)) + '</span>' + mark('](' + s.slice(k + 2, -1) + ')');
    } else out += mark('_') + '<span class="hb">' + esc(s.slice(1, -1)) + '</span>' + mark('_');
    i = m.index + s.length;
  }
  return out + esc(t.slice(i));
}

export function highlightMarkdown(text) {
  let fence = null;
  return text.split('\n').map(line => {
    if (/^```/.test(line)) {
      fence = fence === null ? line.slice(3).trim() : null;
      return '<span class="hf">' + esc(line) + '</span>';
    }
    if (fence === 'suggestion') return '<span class="hs">' + (esc(line) || ' ') + '</span>';
    if (fence !== null) return '<span class="hc">' + esc(line) + '</span>';
    const heading = line.match(/^(#{1,6})(\s.*)$/);
    if (heading) return '<span class="hm">' + heading[1] + '</span><span class="hh">' + hlInline(heading[2]) + '</span>';
    const list = line.match(/^(\s*)([-*+]|\d+\.)(\s.*)$/);
    return list ? esc(list[1]) + '<span class="hm">' + esc(list[2]) + '</span>' + hlInline(list[3]) : hlInline(line);
  }).join('\n') + '\n ';  // a trailing space keeps a final empty line its height
}

export function attachHighlight(box) {
  if (box.parentElement.classList.contains('md-input')) return;
  const wrap = document.createElement('div');
  wrap.className = 'md-input';
  const layer = document.createElement('div');
  layer.className = 'md-layer';
  layer.setAttribute('aria-hidden', 'true');
  box.before(wrap);
  wrap.append(layer, box);
  const cs = getComputedStyle(box);
  for (const k of ['padding', 'borderWidth', 'fontFamily', 'fontSize', 'lineHeight', 'letterSpacing'])
    layer.style[k] = cs[k];
  const paint = () => { layer.innerHTML = highlightMarkdown(box.value); layer.scrollTop = box.scrollTop; };
  box.addEventListener('input', paint);
  box.addEventListener('scroll', () => { layer.scrollTop = box.scrollTop; });
  new MutationObserver(paint).observe(box, { attributes: true, attributeFilter: ['style'] });
  box.paint = paint;
  paint();
}

// ---------- size: grow with the text, up to half the window, then scroll ----------

export function autoGrow(box) {
  box.style.height = 'auto';
  box.style.height = Math.min(box.scrollHeight + 2, innerHeight / 2) + 'px';
  box.style.overflowY = box.scrollHeight + 2 > innerHeight / 2 ? 'auto' : 'hidden';
  box.paint?.();
}
content.addEventListener('input', e => e.target.matches('.thread textarea') && autoGrow(e.target));

// ---------- shortcuts ----------

// Put text in place the way typing would, so undo and the box's growth both keep up.
function typeInto(box, text, selectFrom, selectTo) {
  const start = box.selectionStart;
  box.focus();
  if (!document.execCommand('insertText', false, text)) box.setRangeText(text, box.selectionStart, box.selectionEnd, 'end');
  if (selectFrom !== undefined) box.setSelectionRange(start + selectFrom, start + selectTo);
  autoGrow(box);
}

// Wrap the selection in a Markdown mark, or take it off again if it's already there.
function toggleMark(box, mark, placeholder) {
  const { selectionStart: a, selectionEnd: b, value } = box;
  const sel = value.slice(a, b);
  if (value.slice(a - mark.length, a) === mark && value.slice(b, b + mark.length) === mark) {
    box.setSelectionRange(a - mark.length, b + mark.length);
    return typeInto(box, sel, 0, sel.length);
  }
  const text = sel || placeholder;
  typeInto(box, mark + text + mark, mark.length, mark.length + text.length);
}

const SHORTCUT_MARKS = { b: ['**', 'bold'], i: ['_', 'italic'], e: ['`', 'code'] };
content.addEventListener('keydown', e => {
  const box = e.target;
  if (!box.matches('.thread textarea') || !(e.metaKey || e.ctrlKey) || e.altKey || e.shiftKey) return;
  const key = e.key.toLowerCase();
  if (SHORTCUT_MARKS[key]) {
    e.preventDefault();
    toggleMark(box, ...SHORTCUT_MARKS[key]);
  } else if (key === 'k') {
    e.preventDefault();
    const text = box.value.slice(box.selectionStart, box.selectionEnd) || 'link text';
    typeInto(box, `[${text}](url)`, text.length + 3, text.length + 6);  // "url" selected, ready to paste
  }
});

// Pasting a web address over selected text makes it a link.
content.addEventListener('paste', e => {
  const box = e.target;
  if (!box.matches('.thread textarea') || box.selectionStart === box.selectionEnd) return;
  const url = (e.clipboardData?.getData('text/plain') || '').trim();
  if (!/^https?:\/\/\S+$/.test(url)) return;
  e.preventDefault();
  typeInto(box, `[${box.value.slice(box.selectionStart, box.selectionEnd)}](${url})`);
});

export function submitOnEnter(box, submit, cancel) {
  box.addEventListener('keydown', e => {
    if (e.key === 'Enter' && !e.shiftKey && !e.isComposing) { e.preventDefault(); submit(); }
    if (e.key === 'Escape') { e.preventDefault(); cancel(); }
  });
}

// A comment box set up the usual way: coloured, sized, and focused.
export function prepareBox(box, value) {
  attachHighlight(box);
  if (value !== undefined) box.value = value;
  autoGrow(box);
  box.focus();
}
