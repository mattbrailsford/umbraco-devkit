// Keyboard shortcuts while reading, and the "?" list of them.
import { $, content, page, replay } from './state.js';
import { blockText, hot, setHot } from './doc.js';
import { quoteInto } from './editor.js';
import { openForm } from './threads.js';
import { commentMenuOpen, toggleCommentMenu } from './comment-menu.js';
import { stepChange, toggleChanges } from './changes.js';
import { approve } from './approve.js';

const SHORTCUTS = [
  ['j / ↓', 'Next line'], ['k / ↑', 'Previous line'], ['c / Enter', 'Comment on the line'],
  ['n', 'Next open comment'], ['p', 'Previous open comment'], ['e', 'Edit your pending comment on the line'],
  ['r', 'Reply on the line, quoting any selected text'], ['Shift+S', 'Send pending comments to Claude'],
  ['o', 'Open the list of open comments (↑ ↓ Enter inside)'],
  ['] / [', 'Next or previous change since you sent comments'], ['d', 'Show or hide the change marks'],
  ['⌘⇧Enter', 'Approve the doc'],
  ['?', 'Show or hide this list'], ['Esc', 'Cancel, or close this list'],
];
// In a comment box: GitHub's own keys.
const BOX_SHORTCUTS = [
  ['⌘Enter', 'Add or save'],
  ['⌘B / ⌘I / ⌘E', 'Bold, italic, code'], ['⌘K', 'Link (or paste a web address over text)'],
  ['⌘⇧7 / ⌘⇧8', 'Numbered or bulleted list'], ['⌘⇧.', 'Quote'], ['⌘G', 'Suggest a change'],
];
const help = $('keys');
const rows = list => list.map(([k, v]) => `<dt>${k.split(' / ').map(x => `<kbd>${x}</kbd>`).join(' ')}</dt><dd>${v}</dd>`).join('');
help.querySelector('dl').innerHTML = rows(SHORTCUTS) + '<dt class="keys-group">In a comment box</dt>' + rows(BOX_SHORTCUTS);
$('keys-hint').onclick = () => help.classList.toggle('show');

// The shortcuts only mean anything where comments are on.
export function showKeysHint() {
  $('keys-hint').hidden = !page.canComment;
}

function moveLine(step) {
  const blocks = [...content.querySelectorAll('[data-block]')].filter(b => b.offsetParent);
  const at = blocks.indexOf(hot);
  const next = blocks[at < 0 ? (step > 0 ? 0 : blocks.length - 1) : Math.min(blocks.length - 1, Math.max(0, at + step))];
  setHot(next);
  next?.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
}

function moveThread(step) {
  const threads = [...content.querySelectorAll('.thread:not(.resolved):not(.new)')];
  if (!threads.length) return;
  const tops = threads.map(t => t.getBoundingClientRect().top - innerHeight / 2);
  const i = step > 0 ? tops.findIndex(t => t > 5) : tops.map(t => t < -5).lastIndexOf(true);
  const target = threads[i < 0 ? (step > 0 ? 0 : threads.length - 1) : i];
  target.scrollIntoView({ block: 'center', behavior: 'smooth' });
  replay(target, 'flash');
}

// The thread under a line, if it has one.
function threadOf(block) {
  if (!block) return null;
  if (block.matches('li')) return block.querySelector(':scope > .thread:not(.new)');
  if (block.matches('tr')) return block.nextElementSibling?.matches('.thread-row') && block.nextElementSibling.thread;
  return block.nextElementSibling?.matches('.thread') && block.nextElementSibling;
}

const KEYS = {
  j: () => moveLine(1), ArrowDown: () => moveLine(1), k: () => moveLine(-1), ArrowUp: () => moveLine(-1),
  c: () => hot && openForm(hot, blockText(hot), '', ''), Enter: () => hot && openForm(hot, blockText(hot), '', ''),
  n: () => moveThread(1), p: () => moveThread(-1),
  e: () => threadOf(hot)?.querySelector('.msg.pending .msg-body')?.click(),
  r: () => {
    // As on GitHub: selected text is quoted into the reply. The thread is the one the selection
    // sits in or under, else the current line's.
    const sel = getSelection();
    const text = sel.toString().trim();
    const node = text && sel.anchorNode;
    const at = node && content.contains(node) ? (node.nodeType === 1 ? node : node.parentElement) : null;
    const block = at ? at.closest('[data-block]') : hot;
    const thread = at?.closest('.thread:not(.new)') || threadOf(block);
    if (thread?.classList.contains('resolved'))
      [...content.querySelectorAll('.resolved-pin')].find(p => p.row === block || p.parentElement === block)?.click();
    const box = thread?.querySelector('.reply-box textarea');
    if (!box) return;
    if (text) quoteInto(box, text);
    else box.focus();
  },
  S: () => $('sendbar').classList.contains('show') && $('sendbtn').click(),
  '?': () => help.classList.toggle('show'),
  o: () => toggleCommentMenu(true),
  ']': () => stepChange(1), '[': () => stepChange(-1),
  d: () => toggleChanges(),
  Escape: () => { help.classList.remove('show'); setHot(null); },
};

document.addEventListener('keydown', e => {
  if (e.target.closest('textarea, input')) return;
  // GitHub submits a review with ⌘⇧Enter; here it approves.
  if (e.key === 'Enter' && e.shiftKey && (e.metaKey || e.ctrlKey)) { e.preventDefault(); return approve(); }
  if (e.metaKey || e.ctrlKey || e.altKey) return;
  // The open comments menu has the arrow keys and Enter to itself.
  if (commentMenuOpen() && ['ArrowDown', 'ArrowUp', 'Enter'].includes(e.key)) return;
  const action = KEYS[e.key];
  if (!action) return;
  // Arrow keys still scroll the page until you've started moving between lines.
  if ((e.key === 'ArrowDown' || e.key === 'ArrowUp') && !hot) return;
  e.preventDefault();
  action();
});
