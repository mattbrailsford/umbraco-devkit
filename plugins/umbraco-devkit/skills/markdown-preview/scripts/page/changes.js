// What's changed since the reader last sent comments (or first opened the doc), like
// GitHub's rich diff: new blocks are tinted green, and removed ones come back tinted red and
// struck through. An edited block shows both versions, old above new, each tinted, with just
// the changed words picked out, so neither is struck through and the change is easy to find. Sending comments
// starts afresh, so what's marked is Claude's answer to them. The doc's header shows a
// diffstat that steps through the changes, and an eye that hides the marks for a clean read.
import { $, content, fetchText, page, replay } from './state.js';
import { blockElements, blockText, ownText, pinSources, wrapText } from './doc.js';

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
  eye.title = hidden ? 'Show the changes (d)' : 'Hide the changes, to read the doc as it is (d)';
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

// Whether an added block is a reworded removed one: the same kind of block, sharing a fair
// share of its words. Diagrams, maths and code are shown whole instead.
function edited(oldEl, newEl, oldText, newText) {
  if (oldEl.tagName !== newEl.tagName || newEl.matches('pre') || newEl.dataset.source || newEl.dataset.tex) return false;
  const a = new Set(oldText.toLowerCase().match(/\w+/g)), b = new Set(newText.toLowerCase().match(/\w+/g));
  return [...a].filter(w => b.has(w)).length / Math.max(a.size, b.size, 1) >= 0.3;
}

// Pick out the words that differ between an edit's two versions: runs of changed words in each.
function markWords(oldEl, newEl) {
  const words = el => [...ownText(el).matchAll(/\S+/g)].map(m => [m[0], m.index, m.index + m[0].length]);
  const a = words(oldEl), b = words(newEl);
  const spans = (list, changed) => {
    const out = [];
    for (const k of changed) {
      const last = out.at(-1);
      if (last && last.k === k - 1) { last[1] = list[k][2]; last.k = k; } else out.push(Object.assign([list[k][1], list[k][2]], { k }));
    }
    return out;
  };
  const ops = diff(a.map(w => w[0]), b.map(w => w[0]));
  wrapText(oldEl, spans(a, ops.filter(o => o[0] === 'remove').map(o => o[1])), 'ch-old');
  wrapText(newEl, spans(b, ops.filter(o => o[0] === 'add').map(o => o[2])), 'ch-new');
}

// A removed block, shown struck through (or, as an edit's old version, just tinted). A list
// item or table row keeps a list or table around it.
function ghost(old, anchor, edit = false) {
  const g = old.cloneNode(true);
  g.querySelectorAll('[id]').forEach(el => el.removeAttribute('id'));
  g.removeAttribute('id');
  if (g.matches('li')) g.querySelectorAll(':scope > ul, :scope > ol').forEach(x => x.remove());
  g.classList.add('diff-removed');
  if (edit) g.classList.add('edited');
  const fits = (g.matches('li') === !!anchor?.matches('li')) && (g.matches('tr') === !!anchor?.matches('tr'));
  if (fits) return g;
  const wrap = document.createElement(g.matches('tr') ? 'table' : g.matches('li') ? 'ul' : 'div');
  wrap.className = 'diff-removed-wrap';
  wrap.append(g);
  return wrap;
}

function clear() {
  content.querySelectorAll('.diff-removed, .diff-removed-wrap').forEach(el => el.remove());
  content.querySelectorAll('.diff-added').forEach(el => el.classList.remove('diff-added', 'edited'));
  content.querySelectorAll('mark.ch-new').forEach(m => m.replaceWith(...m.childNodes));
  content.normalize();
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

  // A run of removed and added blocks between unchanged ones is one change. Within it, an added
  // block that rewords a removed one is shown as an edit, old above new. Other removed blocks
  // go back where they stood: before the next edit after them, else before the next unchanged
  // block, else at the end.
  const ops = diff(oldTexts, newTexts);
  let last = null;
  for (let k = 0; k < ops.length;) {
    if (ops[k][0] === 'same') { last = newBlocks[ops[k][2]]; k++; continue; }
    const removed = [], added = [];
    for (; k < ops.length && ops[k][0] !== 'same'; k++) (ops[k][0] === 'add' ? added : removed).push(ops[k][0] === 'add' ? ops[k][2] : ops[k][1]);
    const pairs = new Map(), editOf = new Map();  // new index -> old index; old index -> its shown old version
    for (const j of added) {
      const at = removed.findIndex(i => !editOf.has(i) && edited(oldBlocks[i], newBlocks[j], oldTexts[i], newTexts[j]));
      if (at >= 0) { pairs.set(j, removed[at]); editOf.set(removed[at], null); }
    }
    const shown = [];
    for (const j of added) {
      const el = newBlocks[j];
      el.classList.add('diff-added');
      if (pairs.has(j)) {
        const g = ghost(oldBlocks[pairs.get(j)], el, true);
        el.before(g);
        el.classList.add('edited');
        markWords(g, el);
        editOf.set(pairs.get(j), g);
        shown.push(g);
      }
      shown.push(el);
    }
    const nextSame = ops[k] ? newBlocks[ops[k][2]] : null;
    let tail = added.length ? newBlocks[added.at(-1)] : last;
    for (const i of removed.filter(i => !editOf.has(i))) {
      const after = [...editOf.keys()].filter(o => o > i).sort((x, y) => x - y)[0];
      const before = after !== undefined ? editOf.get(after) : nextSame;
      const g = ghost(oldBlocks[i], before || tail);
      if (before) before.before(g); else if (tail) { tail.after(g); tail = g; } else content.append(g);
      shown.push(g);
    }
    if (added.length) last = newBlocks[added.at(-1)];
    marks.push(shown.sort((x, y) => x.compareDocumentPosition(y) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1)[0]);
  }
  if (!marks.length) return;
  step = -1;

  const added = content.querySelectorAll('.diff-added').length;
  const removed = content.querySelectorAll('.diff-removed').length;
  // Five squares split green and red, as in GitHub's diffstat.
  const green = Math.round(5 * added / (added + removed));
  const squares = Array.from({ length: 5 }, (_, k) => `<i class="${k < green ? 'add' : 'del'}"></i>`).join('');
  const note = $('changes');
  note.innerHTML = `<button class="ch-step" title="Changed since you sent comments: ${marks.length} place${marks.length > 1 ? 's' : ''}. Click, or press ], to step through.">`
    + (added ? `<span class="add">+${added}</span>` : '') + (removed ? `<span class="del">\u2212${removed}</span>` : '')
    + `<span class="squares">${squares}</span></button><button class="ch-eye"></button>`;
  setHidden(hidden);
  note.querySelector('.ch-eye').onclick = () => toggleChanges();
  note.querySelector('.ch-step').onclick = () => stepChange(1);
}

// Go to the next (or previous) change, showing the marks if they're hidden.
export function stepChange(dir) {
  if (!marks.length) return;
  if (hidden) setHidden(false);  // going to a change means wanting to see it
  step = (step + dir + marks.length) % marks.length;
  marks[step].scrollIntoView({ block: 'center', behavior: 'smooth' });
  replay(marks[step], 'flash');
}

export function toggleChanges() {
  if (marks.length) setHidden(!hidden);
}
