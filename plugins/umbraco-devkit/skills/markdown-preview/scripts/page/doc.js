// The drawn doc: finishing GitHub's HTML, the lines ("blocks") comments attach to, how a
// comment finds its line again, and the line under the pointer or keyboard ("hot").
import { $, content, norm } from './state.js';
import { openForm } from './threads.js';

const dark = matchMedia('(prefers-color-scheme: dark)').matches;
mermaid.initialize({ startOnLoad: false, theme: dark ? 'dark' : 'default' });
let renderCount = 0;

// GitHub finishes several things in the browser; repeat them after each render.
export function enhance() {
  const seen = {};
  content.querySelectorAll('h1,h2,h3,h4,h5,h6').forEach(h => {
    let slug = h.textContent.trim().toLowerCase().replace(/[^\p{L}\p{N}\s_-]/gu, '').replace(/\s/g, '-');
    const n = seen[slug] = (seen[slug] ?? -1) + 1;
    if (n) slug += '-' + n;
    h.id = slug;
  });
  content.querySelectorAll('[id^="user-content-"]').forEach(el => el.id = el.id.slice(13));
  content.querySelectorAll('a[href^="#user-content-"]').forEach(a => a.setAttribute('href', '#' + a.getAttribute('href').slice(14)));

  pinSources(content);
  const run = ++renderCount;
  content.querySelectorAll('div.highlight-source-mermaid > pre').forEach(async (pre, i) => {
    try { pre.innerHTML = (await mermaid.render(`mermaid-${run}-${i}`, pre.textContent)).svg; } catch (e) { console.error(e); }
  });
  if (window.MathJax?.typesetPromise) {
    MathJax.typesetClear([content]);
    MathJax.typesetPromise([content]).catch(console.error);
  }
}

// Diagrams and math are pinned by their source, kept before they're drawn over.
export function pinSources(root) {
  root.querySelectorAll('div.highlight-source-mermaid > pre').forEach(pre => { pre.dataset.source = 'Diagram: ' + norm(pre.textContent); });
  root.querySelectorAll('math-renderer').forEach(m => { m.dataset.tex = norm(m.textContent); });
}

// ---------- blocks: the things a comment can be on ----------

// What a line "says", for pinning: source for diagrams and math, a label for images, a list
// item's own text without its nested list, and a table row by its column names.
export function blockText(el) {
  if (el.matches('tr')) return rowText(el);
  if (el.dataset.source) return el.dataset.source;
  if (el.dataset.tex) return el.dataset.tex;
  const copy = el.cloneNode(true);
  copy.querySelectorAll('.add-btn, .thread, .resolved-pin').forEach(x => x.remove());
  if (el.matches('li')) copy.querySelectorAll(':scope > ul, :scope > ol').forEach(x => x.remove());
  copy.querySelectorAll('[data-tex]').forEach(m => m.replaceWith(m.dataset.tex));
  copy.querySelectorAll('img').forEach(img =>
    img.replaceWith(` [image: ${img.alt || decodeURIComponent((img.getAttribute('src') || '').split('/').pop())}] `));
  return norm(copy.textContent);
}

// Pinned as "Column: value · Column: value", so a short row reads clearly to Claude and two
// look-alike rows don't get mixed up. The header row stands for the whole table.
function rowText(tr) {
  const cells = [...tr.cells].map(c => norm(c.textContent));
  if (tr.closest('thead')) return 'Table: ' + cells.join(' | ');
  const heads = [...(tr.closest('table').tHead?.rows[0]?.cells || [])].map(c => norm(c.textContent));
  return cells.map((c, i) => heads[i] ? `${heads[i]}: ${c}` : c).join(' · ');
}

// The element a table's gutter items (the row "+", resolved ticks) are measured against.
export function tableBox(row) {
  return row.closest('markdown-accessiblity-table') || row.closest('table');
}

// The heading of the section a block sits in (or the block itself, if it's a heading).
export function sectionOf(block) {
  let el = block;
  while (el.parentElement && el.parentElement !== content) el = el.parentElement;
  for (; el; el = el.previousElementSibling)
    if (el.matches('h1, h2, h3, h4, h5, h6')) return blockText(el);
  return '';
}

// The blocks in a drawn doc, in order. Also used on an older copy, to compare the two.
export function blockElements(root) {
  const kinds = 'p, li, h1, h2, h3, h4, h5, h6, pre, tr, math-renderer.js-display-math';
  const picked = [], holders = [];
  root.querySelectorAll(kinds).forEach(el => {
    if (el.matches('li') && el.querySelector(':scope > p')) return;
    // Skip hidden headings, and anything inside a block already taken (a table's cells, say).
    if (el.matches('.sr-only') || holders.some(b => b.contains(el))) return;
    if (el.matches('math-renderer') && el.closest('p')) return;
    picked.push(el);
    if (!el.matches('li')) holders.push(el);
  });
  return picked;
}

export function markBlocks() {
  blockElements(content).forEach(el => {
    el.dataset.block = '';
    if (el.matches('tr')) return;  // rows share one floating "+" (see setHot)
    const btn = document.createElement('button');
    btn.className = 'add-btn';
    btn.textContent = '+';
    btn.title = 'Comment on this';
    btn.onclick = e => { e.stopPropagation(); openForm(el, blockText(el), '', ''); };
    el.prepend(btn);
  });
}

// The block a comment is on: by its text with the words around it, then by its text, then,
// if the text was edited, the block sharing most of its words (when most are shared).
export function findBlock(c) {
  if (!c.quote) return null;
  const blocks = [...content.querySelectorAll('[data-block]')].map(el => [el, blockText(el)]);
  const exact = blocks.find(([, t]) => t.includes(c.prefix + c.quote + c.suffix));
  const loose = blocks.find(([, t]) => t.includes(c.quote));
  if (exact || loose) return (exact || loose)[0];
  const words = new Set(c.quote.toLowerCase().split(' '));
  let best = null, bestScore = 0.5;
  for (const [el, t] of blocks) {
    const shared = t.toLowerCase().split(' ').filter(w => words.has(w)).length / words.size;
    if (shared > bestScore) [best, bestScore] = [el, shared];
  }
  return best;
}

export function findHeading(text) {
  return [...content.querySelectorAll('h1[data-block], h2[data-block], h3[data-block], h4[data-block], h5[data-block], h6[data-block]')]
    .find(h => blockText(h) === text) || null;
}

// Highlight a few selected words in the doc, so the thread needn't repeat them.
// The text nodes a block shows as its own: not a thread, a button, or a list item's nested list.
function ownTextNodes(block) {
  const nested = block.matches('li') ? [...block.querySelectorAll(':scope > ul, :scope > ol')] : [];
  const walker = document.createTreeWalker(block, NodeFilter.SHOW_TEXT, {
    acceptNode: n => n.parentElement.closest('.thread, .add-btn, .resolved-pin') || nested.some(l => l.contains(n))
      ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT,
  });
  const nodes = [];
  for (let n; (n = walker.nextNode());) nodes.push(n);
  return nodes;
}

export const ownText = block => ownTextNodes(block).map(n => n.nodeValue).join('');

// Wrap stretches of a block's own text ([start, end) in ownText) in marks, even where a
// stretch runs across bold, a link or code.
export function wrapText(block, ranges, className) {
  const cuts = [];
  let offset = 0;
  for (const n of ownTextNodes(block)) {
    const len = n.nodeValue.length;
    for (const [a, b] of ranges) {
      const from = Math.max(a, offset), to = Math.min(b, offset + len);
      if (from < to) cuts.push([n, from - offset, to - offset]);
    }
    offset += len;
  }
  // Last first, so splitting a text node leaves the earlier offsets in it as they were.
  for (const [n, from, to] of cuts.reverse()) {
    const range = document.createRange();
    range.setStart(n, from);
    range.setEnd(n, to);
    const mark = document.createElement('mark');
    mark.className = className;
    range.surroundContents(mark);
  }
  return cuts.length > 0;
}

export function markQuote(block, quote) {
  const words = quote.trim().split(/\s+/).map(w => w.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'));
  const found = words[0] && ownText(block).match(new RegExp(words.join('\\s+')));
  return !!found && wrapText(block, [[found.index, found.index + found[0].length]], 'cmark');
}
export function clearQuoteMarks() {
  content.querySelectorAll('mark.cmark').forEach(m => m.replaceWith(...m.childNodes));
  content.normalize();
}

// ---------- the hot line: under the pointer, or picked with j/k ----------

export let hot = null;
const rowAdd = $('row-add');
rowAdd.onclick = () => hot && openForm(hot, blockText(hot), '', '');

export function setHot(block) {
  hot?.classList.remove('hot');
  hot = block;
  hot?.classList.add('hot');
  // A table row can't hold a "+" of its own (a table clips anything outside it when it
  // scrolls sideways), so rows share one floating "+" that follows the current row.
  if (hot?.matches('tr')) {
    const r = hot.getBoundingClientRect();
    const left = tableBox(hot).getBoundingClientRect().left;
    rowAdd.style.left = (left + scrollX - 26) + 'px';
    rowAdd.style.top = (r.top + scrollY + Math.min(r.height, 28) / 2 - 10) + 'px';
    rowAdd.style.display = 'block';
  } else {
    rowAdd.style.display = 'none';
  }
}

content.addEventListener('mouseover', e => {
  const block = e.target.closest('[data-block]');
  // Crossing the gap between the text and its "+" passes over no block; keep the last one
  // lit so the button stays put long enough to click.
  if (!block || block === hot) return;
  setHot(block);
});
content.addEventListener('mouseleave', e => { if (e.relatedTarget !== rowAdd) setHot(null); });

// A plain click on a line starts a comment too. Dragging or double-clicking to select text
// leaves a selection, which goes to the "Comment" button instead; links and controls keep
// their own clicks.
content.addEventListener('click', e => {
  if (getSelection().toString().trim()) return;
  if (e.target.closest('a, button, input, textarea, .thread, .resolved-pin')) return;
  const block = e.target.closest('[data-block]');
  if (block) openForm(block, blockText(block), '', '');
});

// Selecting words in a line offers a "Comment" button for just those words.
const selBtn = $('sel-btn');
document.addEventListener('mouseup', e => {
  if (e.target === selBtn) return;
  const sel = getSelection();
  const block = sel.anchorNode?.parentElement?.closest('[data-block]');
  if (!norm(sel.toString()) || !block || !content.contains(block)) { selBtn.style.display = 'none'; return; }
  // A comment is on one block, so a selection running into the next stops at this one's edge.
  const range = sel.getRangeAt(0).cloneRange();
  if (!block.contains(range.startContainer)) range.setStart(block, 0);
  if (!block.contains(range.endContainer)) range.setEnd(block, block.childNodes.length);
  if (range.toString() !== sel.toString()) { sel.removeAllRanges(); sel.addRange(range); }
  const full = blockText(block);
  // Trim anything the block's own text doesn't have (a nested list, the "+" button) off the ends.
  let words = norm(range.toString()).replace(/^\+\s*/, '').split(' ');
  while (words.length && !full.includes(words.join(' '))) words = words.slice(0, -1);
  const text = words.join(' ');
  if (!text) { selBtn.style.display = 'none'; return; }
  const rect = range.getBoundingClientRect();
  selBtn.style.left = (rect.right + scrollX + 6) + 'px';
  selBtn.style.top = (rect.top + scrollY - 4) + 'px';
  selBtn.style.display = 'block';
  selBtn.onclick = () => {
    const at = Math.max(0, full.indexOf(text));
    selBtn.style.display = 'none';
    openForm(block, text, full.slice(Math.max(0, at - 30), at), full.slice(at + text.length, at + text.length + 30));
  };
});
selBtn.addEventListener('mousedown', e => e.preventDefault());
