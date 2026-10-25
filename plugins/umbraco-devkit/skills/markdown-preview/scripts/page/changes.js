// What's changed since the reader last sent comments (or first opened the doc), like
// GitHub's rich diff: new blocks are tinted green, and removed ones come back tinted red and
// struck through. An edited block that only gained words, or only lost them, shows once with
// the change marked in place; one that did both shows both versions, old above new, each
// tinted, with just the changed words picked out. Sending comments
// starts afresh, so what's marked is Claude's answer to them. The doc's header shows a
// diffstat that steps through the changes, and an eye that hides the marks for a clean read.
import { $, content, fetchText, page, replay } from './state.js';
import { blockElements, blockText, insertText, ownText, pinSources, wrapText } from './doc.js';
import { diff, wordChanges } from './diff.js';

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

// Whether an added block is a reworded removed one: the same kind of block, sharing a fair
// share of its words. Diagrams, maths and code are shown whole instead.
function edited(oldEl, newEl, oldText, newText) {
  if (oldEl.tagName !== newEl.tagName || newEl.matches('pre') || newEl.dataset.source || newEl.dataset.tex) return false;
  const a = new Set(oldText.toLowerCase().match(/\w+/g)), b = new Set(newText.toLowerCase().match(/\w+/g));
  return [...a].filter(w => b.has(w)).length / Math.max(a.size, b.size, 1) >= 0.3;
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

// Show an edit. Returns the old version if it's shown too, and counts what it adds and removes.
function showEdit(oldEl, newEl, count) {
  const changes = wordChanges(ownText(oldEl), ownText(newEl));
  const gained = changes.some(c => c.new), lost = changes.some(c => c.old);
  if (gained && lost) {
    const g = ghost(oldEl, newEl, true);
    newEl.before(g);
    newEl.classList.add('diff-added', 'edited');
    wrapText(g, changes.filter(c => c.old).map(c => c.old), 'ch-old');
    wrapText(newEl, changes.filter(c => c.new).map(c => c.new), 'ch-new');
    count.added++; count.removed++;
    return g;
  }
  // One-way: the block once, words added marked green, words taken out put back struck through.
  newEl.classList.add('diff-inline');
  if (gained) { wrapText(newEl, changes.map(c => c.new), 'ch-new'); count.added++; return null; }
  const text = ownText(oldEl);
  for (const c of [...changes].reverse()) {  // last first, so earlier offsets stay right
    const put = text.slice(...c.put), lead = put.match(/^\s*/)[0], trail = put.match(/\s*$/)[0];
    const del = document.createElement('del');
    del.className = 'ch-del';
    del.textContent = put.trim();
    insertText(newEl, c.at, [lead, del, trail].filter(Boolean));
  }
  count.removed++;
  return null;
}

function clear() {
  content.querySelectorAll('.diff-removed, .diff-removed-wrap, del.ch-del').forEach(el => el.remove());
  content.querySelectorAll('.diff-inline').forEach(el => el.classList.remove('diff-inline'));
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
  const count = { added: 0, removed: 0 };
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
      if (pairs.has(j)) {
        const g = showEdit(oldBlocks[pairs.get(j)], el, count);
        editOf.set(pairs.get(j), g || el);
        if (g) shown.push(g);
      } else {
        el.classList.add('diff-added');
        count.added++;
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
      count.removed++;
      shown.push(g);
    }
    if (added.length) last = newBlocks[added.at(-1)];
    marks.push(shown.sort((x, y) => x.compareDocumentPosition(y) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1)[0]);
  }
  if (!marks.length) return;
  step = -1;

  const { added, removed } = count;
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
