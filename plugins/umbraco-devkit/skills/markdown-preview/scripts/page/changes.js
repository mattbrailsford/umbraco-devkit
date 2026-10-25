// What's changed since the reader last looked, like GitHub's rich diff: new blocks are
// tinted green, and removed ones come back tinted red and struck through, so an edited line
// shows as its old wording above its new. The doc's header counts the changes and steps
// through them; the eye hides the marks for a clean read without losing them, and "Mark as
// seen" clears them.
import { $, content, fetchText, page, post, replay } from './state.js';
import { blockElements, blockText, pinSources } from './doc.js';

let marks = [];  // the first element of each change, in doc order, for stepping through
let step = -1;
let hidden = (() => { try { return localStorage.getItem('hideChanges') === '1'; } catch { return false; } })();

const EYE = '<svg viewBox="0 0 16 16" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M1 8s2.5-4.5 7-4.5S15 8 15 8s-2.5 4.5-7 4.5S1 8 1 8Z"/><circle cx="8" cy="8" r="2"/></svg>';
const EYE_OFF = '<svg viewBox="0 0 16 16" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M1 8s2.5-4.5 7-4.5S15 8 15 8s-2.5 4.5-7 4.5S1 8 1 8Z"/><circle cx="8" cy="8" r="2"/><path d="M2 14 14 2"/></svg>';

function setHidden(value) {
  hidden = value;
  try { localStorage.setItem('hideChanges', hidden ? '1' : '0'); } catch {}
  content.classList.toggle('hide-changes', hidden);
  const eye = $('changes').querySelector('.ch-eye');
  if (!eye) return;
  eye.innerHTML = hidden ? EYE_OFF : EYE;
  eye.title = hidden ? 'Show the changes' : 'Hide the changes, to read the doc as it is';
  eye.setAttribute('aria-pressed', String(hidden));
}

// Longest common run of block texts between old and new: what's left over was removed or
// added. On a tie the remove comes first, so an edited line reads old, then new.
function diff(a, b) {
  const n = a.length, m = b.length;
  const lcs = Array.from({ length: n + 1 }, () => new Uint16Array(m + 1));
  for (let i = n - 1; i >= 0; i--)
    for (let j = m - 1; j >= 0; j--)
      lcs[i][j] = a[i] === b[j] ? lcs[i + 1][j + 1] + 1 : Math.max(lcs[i + 1][j], lcs[i][j + 1]);
  const ops = [];
  let i = 0, j = 0;
  while (i < n || j < m) {
    if (i < n && j < m && a[i] === b[j]) { ops.push(['same', i++, j++]); continue; }
    if (j < m && (i === n || lcs[i][j + 1] > lcs[i + 1][j])) ops.push(['add', null, j++]);
    else ops.push(['remove', i++, null]);
  }
  return ops;
}

// A removed block, shown struck through. A list item or table row keeps a list or table around it.
function ghost(old, anchor) {
  const g = old.cloneNode(true);
  g.querySelectorAll('[id]').forEach(el => el.removeAttribute('id'));
  g.removeAttribute('id');
  if (g.matches('li')) g.querySelectorAll(':scope > ul, :scope > ol').forEach(x => x.remove());
  g.classList.add('diff-removed');
  const fits = (g.matches('li') === !!anchor?.matches('li')) && (g.matches('tr') === !!anchor?.matches('tr'));
  if (fits) return g;
  const wrap = document.createElement(g.matches('tr') ? 'table' : g.matches('li') ? 'ul' : 'div');
  wrap.className = 'diff-removed-wrap';
  wrap.append(g);
  return wrap;
}

function clear() {
  content.querySelectorAll('.diff-removed, .diff-removed-wrap').forEach(el => el.remove());
  content.querySelectorAll('.diff-added').forEach(el => el.classList.remove('diff-added'));
  marks = [];
  $('changes').replaceChildren();
}

export async function showChanges() {
  clear();
  let before;
  try {
    before = JSON.parse(await fetchText('/__seen?path=' + encodeURIComponent(page.docPath))).html;
  } catch { return; }  // no copy to compare with (GitHub unreachable, say): show the doc as it is
  if (!before) return;
  const old = document.createElement('div');
  old.innerHTML = before;
  pinSources(old);
  const oldBlocks = blockElements(old), newBlocks = blockElements(content);
  const oldTexts = oldBlocks.map(blockText), newTexts = newBlocks.map(blockText);

  // Removed blocks go just before the next block still there; a run of removes and adds is
  // one change.
  let pending = [], last = null, inRun = false;
  const startRun = el => { if (!inRun) marks.push(el); inRun = true; };
  for (const [kind, i, j] of diff(oldTexts, newTexts)) {
    if (kind === 'remove') { pending.push(oldBlocks[i]); continue; }
    const el = newBlocks[j];
    for (const p of pending) { const g = ghost(p, el); el.before(g); startRun(g); }
    pending = [];
    if (kind === 'add') { el.classList.add('diff-added'); startRun(el); }
    else inRun = false;
    last = el;
  }
  for (const p of pending.reverse()) {
    const g = ghost(p, last);
    last ? last.after(g) : content.append(g);
    startRun(g);
  }
  if (!marks.length) return;
  step = -1;

  const note = $('changes');
  note.innerHTML = `<button class="ch-count" title="Go to the next change">${marks.length} change${marks.length > 1 ? 's' : ''} since you last looked</button>`
    + '<button class="ch-eye"></button><button class="ch-seen">Mark as seen</button>';
  setHidden(hidden);
  note.querySelector('.ch-eye').onclick = () => setHidden(!hidden);
  note.querySelector('.ch-count').onclick = () => {
    if (hidden) setHidden(false);  // going to a change means wanting to see it
    step = (step + 1) % marks.length;
    marks[step].scrollIntoView({ block: 'center', behavior: 'smooth' });
    replay(marks[step], 'flash');
  };
  note.querySelector('.ch-seen').onclick = async () => {
    await post('/__seen', { path: page.docPath });
    clear();
    document.dispatchEvent(new Event('seen'));
  };
}
