// Keyboard shortcuts while reading, and the "?" list of them.
import { $, content, page, replay } from './state.js';
import { blockText, hot, setHot } from './doc.js';
import { openForm } from './threads.js';

const SHORTCUTS = [
  ['j / ↓', 'Next line'], ['k / ↑', 'Previous line'], ['c / Enter', 'Comment on the line'],
  ['n', 'Next open comment'], ['p', 'Previous open comment'], ['e', 'Edit your pending comment on the line'],
  ['r', 'Reply on the line'], ['Shift+S', 'Send pending comments to Claude'],
  ['Enter', 'Add or save, in a comment box'], ['⌘B / ⌘I / ⌘E / ⌘K', 'Bold, italic, code, link, in a comment box'],
  ['Shift+Enter', 'New line, in a comment box'], ['Esc', 'Cancel, or close this list'], ['?', 'Show or hide this list'],
];
const help = $('keys');
help.querySelector('dl').innerHTML = SHORTCUTS
  .map(([k, v]) => `<dt>${k.split(' / ').map(x => `<kbd>${x}</kbd>`).join(' ')}</dt><dd>${v}</dd>`).join('');
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
    const thread = threadOf(hot);
    if (thread?.classList.contains('resolved'))
      [...content.querySelectorAll('.resolved-pin')].find(p => p.row === hot || p.parentElement === hot)?.click();
    thread?.querySelector('.reply-box textarea')?.focus();
  },
  S: () => $('sendbar').classList.contains('show') && $('sendbtn').click(),
  '?': () => help.classList.toggle('show'),
  Escape: () => { help.classList.remove('show'); setHot(null); },
};

document.addEventListener('keydown', e => {
  if (e.target.closest('textarea, input') || e.metaKey || e.ctrlKey || e.altKey) return;
  const action = KEYS[e.key];
  if (!action) return;
  // Arrow keys still scroll the page until you've started moving between lines.
  if ((e.key === 'ArrowDown' || e.key === 'ArrowUp') && !hot) return;
  e.preventDefault();
  action();
});
