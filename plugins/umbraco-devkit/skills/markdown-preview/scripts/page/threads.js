// Comment threads in the doc: drawing them under their lines, the forms for writing,
// editing and replying, resolved ticks in the margin, and the "Send to Claude" bar.
//
// A comment moves through: draft (not sent) -> sent -> working (Claude has it) -> replied
// (Claude asked something), addressed (Claude says it's done) or deferred (left for another
// step) -> resolved. Only the reader resolves.
import { $, ago, avatar, content, esc, fetchText, page, post, replay } from './state.js';
import { blockText, clearQuoteMarks, findBlock, findHeading, markQuote, sectionOf, tableBox } from './doc.js';
import { attachHighlight, autoGrow, prepareBox, submitOnEnter } from './editor.js';
import { renderOverview } from './overview.js';

const svg = body => '<svg viewBox="0 0 16 16" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.5" '
  + `stroke-linecap="round" stroke-linejoin="round">${body}</svg>`;
const STATE_ICON = {
  draft: svg('<circle cx="8" cy="8" r="5.75" stroke-dasharray="2.5 2"/>'),
  sent: svg('<path d="M14 2 7 9M14 2l-4.5 12L7 9 2 6.5z"/>'),
  working: svg('<path d="M8 2.25a5.75 5.75 0 1 0 5.75 5.75"/>'),
  replied: svg('<path d="M2.5 3.5h11v7H8l-3 2.5v-2.5H2.5z"/><path d="M8 5.75v1.5M8 8.75h.01"/>'),
  addressed: svg('<circle cx="8" cy="8" r="5.75"/><path d="m5.5 8 1.75 1.75L10.75 6"/>'),
  deferred: svg('<path d="M2.5 8h9M8.5 4.5 12 8l-3.5 3.5"/><path d="M14 3.5v9"/>'),
  resolved: svg('<path d="m3.5 8.5 3 3 6-7"/>'),
};
const STATE = { draft: 'Pending', sent: 'Sent', working: 'Claude is on it', replied: 'Waiting on you',
                addressed: 'Done, please check', deferred: 'Left for a later step', resolved: 'Resolved' };
const TICK = '<svg viewBox="0 0 16 16" width="14" height="14"><path d="M13.78 4.22a.75.75 0 0 1 0 1.06l-7.25 7.25a.75.75 0 0 1-1.06 0L2.22 9.28a.75.75 0 0 1 1.06-1.06L6 10.94l6.72-6.72a.75.75 0 0 1 1.06 0Z"/></svg>';

export const SUGGESTION = /```suggestion\n([\s\S]*?)\n?```/;

// ---------- messages ----------

const drawn = new Map();  // comment text -> GitHub's HTML for it

// A message's body: its text (drawn by GitHub once that's come back, plain until then), and
// a suggestion block shown as a before/after against the line it was made on.
function bodyHtml(body, was) {
  const m = body.match(SUGGESTION);
  const text = m ? body.replace(SUGGESTION, '').trim() : body;
  const prose = !text ? '' : drawn.has(text) ? drawn.get(text) : `<p>${esc(text).replace(/\n/g, '<br>')}</p>`;
  const diff = !m ? '' : `<div class="suggestion"><div class="sg-head">Suggested change</div>`
    + (was ? `<div class="sg-del">- ${esc(was)}</div>` : '') + `<div class="sg-add">+ ${esc(m[1])}</div></div>`;
  return { html: prose + diff, text };
}

function message(who, when, body, { head = '', quote = '', was = '' } = {}) {
  const name = who === 'claude' ? 'Claude' : (page.user.login || 'You');
  const { html, text } = bodyHtml(body, was);
  return `<div class="msg ${who}">${avatar(who)}<div class="msg-main"><div class="msg-head"><b>${esc(name)}</b>`
    + `<span class="when">${ago(when)}</span>${head}</div>${quote}`
    + `<div class="msg-body" data-md="${esc(text)}" data-raw="${esc(body)}" data-was="${esc(was)}">${html}</div></div></div>`;
}

// Draw any comment text not drawn yet, in one call to GitHub, then put it in place.
async function drawComments() {
  const bodies = [...content.querySelectorAll('.thread .msg-body[data-md]')];
  const todo = [...new Set(bodies.map(b => b.dataset.md).filter(t => t && !drawn.has(t)))];
  if (todo.length) {
    try {
      const res = await fetch('/__md', { method: 'POST', body: JSON.stringify({ texts: todo }) });
      if (!res.ok) return;
      (await res.json()).html.forEach((h, i) => drawn.set(todo[i], h));
    } catch { return; }
  }
  for (const b of bodies) {
    if (!b.dataset.md || !drawn.has(b.dataset.md) || b.closest('.editing')) continue;
    b.innerHTML = bodyHtml(b.dataset.raw, b.dataset.was).html;
  }
  layoutRowThreads();
}

// ---------- placing threads ----------

// A thread goes under its line; in a list item, above any sub-list; for a table row, in a
// slot row under it (see layoutRowThreads).
function place(block, el) {
  if (block.matches('tr')) {
    const row = document.createElement('tr');
    row.className = 'thread-row';
    row.innerHTML = `<td colspan="${block.cells.length}"><div class="thread-slot"></div></td>`;
    let after = block;  // keep threads in order under the row, after any already there
    while (after.nextElementSibling?.matches('.thread-row')) after = after.nextElementSibling;
    after.after(row);
    el.classList.add('row-thread');
    tableBox(block).append(el);
    row.thread = el;
    el.slotRow = row;
    rowThreadSizes.observe(el);
    requestAnimationFrame(layoutRowThreads);
    return;
  }
  if (!block.matches('li')) return block.after(el);
  const sublist = block.querySelector(':scope > ul, :scope > ol');
  sublist ? sublist.before(el) : block.append(el);
}

function removeThread(thread) {
  thread?.slotRow?.remove();
  thread?.remove();
}

// A thread inside a table cell could only be as wide as the table, so a row's thread floats
// at full width over an empty slot row sized to match. Two passes: size each slot to its
// thread, then line each thread up with its slot (growing one slot moves those below it).
export function layoutRowThreads() {
  const threads = [...content.querySelectorAll('.row-thread')].filter(t => t.slotRow);
  for (const t of threads) {
    const shown = getComputedStyle(t).display !== 'none';
    t.slotRow.style.display = shown ? '' : 'none';
    if (shown) t.slotRow.querySelector('.thread-slot').style.height = t.offsetHeight + 'px';
  }
  for (const t of threads) {
    if (t.slotRow.style.display === 'none') continue;
    const slot = t.slotRow.querySelector('.thread-slot').getBoundingClientRect();
    t.style.top = (slot.top - t.parentElement.getBoundingClientRect().top) + 'px';
  }
  placePins();
}
const rowThreadSizes = new ResizeObserver(() => layoutRowThreads());
addEventListener('resize', layoutRowThreads);

// Resolved ticks sit just outside the doc's right edge, beside their line.
function placePins() {
  const edge = $('doc').getBoundingClientRect().right + 6;
  content.querySelectorAll('.resolved-pin').forEach(pin => {
    const box = pin.parentElement.getBoundingClientRect();
    pin.style.left = (edge - box.left) + 'px';
    if (pin.row) pin.style.top = (pin.row.getBoundingClientRect().top - box.top + 4) + 'px';
  });
}
addEventListener('resize', placePins);

// ---------- writing ----------

export function openForm(block, quote, prefix, suffix) {
  removeThread(document.querySelector('.thread.new'));
  const thread = document.createElement('div');
  thread.className = 'thread new';
  const quoteLine = quote !== blockText(block) ? `<div class="msg-quote">${esc(quote)}</div>` : '';
  thread.innerHTML = `<div class="comment-form">${avatar('you')}<div class="msg-main">${quoteLine}`
    + '<textarea placeholder="Leave a comment · Enter to add, Shift+Enter for a new line · ⌘B ⌘I ⌘E ⌘K to format"></textarea>'
    + '<div class="form-actions"><button class="btn suggest" title="Write the exact new wording">± Suggest a change</button><span>'
    + '<button class="btn cancel">Cancel</button><button class="btn primary add">Add comment</button></span></div></div></div>';
  place(block, thread);
  const box = thread.querySelector('textarea');
  prepareBox(box);
  // As on GitHub: a suggestion block holding the current wording, ready to edit.
  thread.querySelector('.suggest').onclick = () => {
    const before = box.value.slice(0, box.selectionStart);
    const suggestion = '```suggestion\n' + quote + '\n```';
    box.value = before + (before && !before.endsWith('\n') ? '\n' : '') + suggestion + box.value.slice(box.selectionEnd);
    const start = box.value.indexOf(suggestion) + '```suggestion\n'.length;
    box.focus();
    box.setSelectionRange(start, start + quote.length);
    autoGrow(box);
  };
  submitOnEnter(box, () => thread.querySelector('.add').click(), () => thread.querySelector('.cancel').click());
  thread.querySelector('.cancel').onclick = () => removeThread(thread);
  thread.querySelector('.add').onclick = async () => {
    if (!box.value.trim()) return;
    await post('/__comments', { path: page.docPath, quote, prefix, suffix, section: sectionOf(block), body: box.value.trim() });
    removeThread(thread);
    renderComments();
  };
}

// The pending message is the newest one of yours: the comment itself, or a reply that reopened it.
function pendingText(c) {
  const last = c.replies[c.replies.length - 1];
  return last && last.author === 'you' ? last.body : c.body;
}

function editDraft(thread, c) {
  const body = thread.querySelector('.msg.pending .msg-body');
  thread.classList.add('editing');
  body.innerHTML = '<textarea></textarea><div class="form-actions"><button class="btn danger del">Delete</button><span>'
    + '<button class="btn cancel">Cancel</button><button class="btn primary save">Save</button></span></div>';
  const box = body.querySelector('textarea');
  prepareBox(box, pendingText(c));
  box.setSelectionRange(box.value.length, box.value.length);
  const done = () => { thread.classList.remove('editing'); renderComments(); };
  body.querySelector('.cancel').onclick = done;
  body.querySelector('.del').onclick = async () => { await post('/__comments/delete', { id: c.id }); done(); };
  body.querySelector('.save').onclick = async () => {
    if (box.value.trim()) await post('/__comments/edit', { id: c.id, body: box.value.trim() });
    done();
  };
  submitOnEnter(box, () => body.querySelector('.save').click(), done);
}

// Answer Claude, or reopen a resolved thread, from the bottom of the thread.
function replyBox(c) {
  const reply = document.createElement('div');
  reply.className = 'reply-box';
  reply.innerHTML = `<textarea rows="1" placeholder="${c.status === 'resolved' ? 'Reply to reopen…' : 'Reply…'}"></textarea>`
    + '<div class="reply-actions"><button class="btn cancel">Cancel</button><button class="btn primary send">Reply</button></div>';
  const box = reply.querySelector('textarea');
  attachHighlight(box);
  box.onfocus = () => reply.classList.add('active');
  reply.querySelector('.cancel').onclick = () => { box.value = ''; reply.classList.remove('active'); };
  reply.querySelector('.send').onclick = async () => {
    const text = box.value.trim();
    if (!text) return;
    box.value = '';  // sent, so it no longer holds back a redraw
    await post('/__comments/reply', { id: c.id, body: text });
    openResolved.delete(c.id);
    renderComments();
  };
  submitOnEnter(box, () => reply.querySelector('.send').click(), () => { reply.querySelector('.cancel').click(); box.blur(); });
  return reply;
}

// ---------- drawing all of a doc's threads ----------

const openResolved = new Set();  // resolved threads the reader has opened, kept open across redraws
// Each comment's status at the last redraw, so a line can celebrate the moment it's resolved
// (but not on first load, when everything already resolved would flash at once).
let lastStatus = null;

function buildThread(c, { block, lineGone }) {
  const thread = document.createElement('div');
  thread.id = 'comment-' + c.id;
  thread.className = 'thread ' + c.status + (lineGone ? ' line-removed' : block ? '' : ' outdated');
  // Whole-line comments sit right under their line; only a picked-out phrase, or text
  // that's since been edited away, needs quoting.
  const partial = block && !lineGone && c.quote !== blockText(block);
  const marked = partial && c.status !== 'resolved' && markQuote(block, c.quote);
  const quote = !block || lineGone || (partial && !marked) ? `<div class="msg-quote">${esc(c.quote)}</div>` : '';
  const was = c.original && c.original !== c.quote
    ? `<div class="msg-was" title="Click to show it all"><b>Was:</b> <s>${esc(c.original)}</s></div>` : '';
  const label = c.status === 'deferred' && c.owner ? `For ${esc(c.owner)}` : STATE[c.status];
  const head = `<span class="state-icon ${c.status}" title="${label}" aria-label="${label}" role="img">${STATE_ICON[c.status]}</span>`;
  // An unsent reply carries the status itself; the comment above it is already sent.
  const replyPending = c.status === 'draft' && c.replies.at(-1)?.author === 'you';
  thread.innerHTML = [message('you', c.created, c.body, { head: replyPending ? '' : head, quote: was + quote, was: c.original || c.quote })]
    .concat(c.replies.map((r, i) => r.author === 'you'
      ? message('you', r.created, r.body, { head: replyPending && i === c.replies.length - 1 ? head : '' })
      : message('claude', r.created, r.body)))
    .join('');
  if (c.status === 'draft') {
    const mine = [...thread.querySelectorAll('.msg.you')].at(-1);
    mine.classList.add('pending');
    const text = mine.querySelector('.msg-body');
    text.title = 'Click to edit';
    text.onclick = () => thread.classList.contains('editing') || editDraft(thread, c);
  }
  if (['replied', 'addressed', 'deferred', 'resolved'].includes(c.status)) thread.append(replyBox(c));
  if (c.status !== 'draft' && c.status !== 'resolved') {
    const foot = document.createElement('div');
    foot.className = 'thread-actions';
    foot.innerHTML = `<button class="btn resolve${c.status === 'addressed' ? ' primary' : ''}">Resolve conversation</button>`;
    foot.querySelector('.resolve').onclick = async () => { await post('/__comments/resolve', { id: c.id }); renderComments(); };
    thread.append(foot);
  }
  thread.querySelector('.msg-was')?.addEventListener('click', e => e.currentTarget.classList.toggle('open'));
  return thread;
}

// Resolved: out of the reading flow, behind a faint tick in the right margin.
function pinResolved(c, block, thread) {
  const isRow = block.matches('tr');
  const holder = isRow ? tableBox(block) : block;
  let pin = [...holder.querySelectorAll(':scope > .resolved-pin')].find(p => p.row === (isRow ? block : undefined));
  if (!pin) {
    pin = document.createElement('button');
    pin.className = 'resolved-pin';
    pin.title = 'Resolved comments';
    pin.threads = [];
    pin.ids = [];
    if (isRow) pin.row = block;
    pin.onclick = e => {
      e.stopPropagation();
      const on = pin.classList.toggle('on');
      pin.threads.forEach(t => t.classList.toggle('open', on));
      pin.ids.forEach(id => on ? openResolved.add(id) : openResolved.delete(id));
      layoutRowThreads();
    };
    holder.append(pin);
  }
  pin.threads.push(thread);
  pin.ids.push(c.id);
  if (openResolved.has(c.id)) { thread.classList.add('open'); pin.classList.add('on'); }
  if (lastStatus?.[c.id] && lastStatus[c.id] !== 'resolved') {
    // It was just resolved: a brief glow on the line, and the tick pops in.
    for (const [el, cls] of [[block, 'just-resolved'], [pin, 'pop']]) {
      replay(el, cls);
      el.addEventListener('animationend', () => el.classList.remove(cls), { once: true });
    }
  }
  pin.innerHTML = TICK + (pin.threads.length > 1 ? pin.threads.length : '');
}

export async function renderComments() {
  // Don't redraw underneath someone mid-edit or mid-reply; try again once they're done.
  if (document.querySelector('.thread.editing') || [...document.querySelectorAll('.reply-box textarea')].some(t => t.value))
    return setTimeout(renderComments, 1000);
  const comments = JSON.parse(await fetchText('/__comments?path=' + encodeURIComponent(page.docPath)));
  content.querySelectorAll('.thread:not(.new)').forEach(removeThread);
  content.querySelectorAll('.resolved-pin, .orphans').forEach(p => p.remove());
  clearQuoteMarks();
  let orphans = null;
  for (const c of comments) {
    // Its own line if it's still there; else the heading of the section it was in; else the
    // list at the bottom of the doc. A resolved comment on vanished text needs no place.
    let block = findBlock(c);
    const lineGone = !block && !!c.section && !!(block = findHeading(c.section));
    if (!block && c.status === 'resolved') continue;
    const thread = buildThread(c, { block, lineGone });
    if (!block) {
      if (!orphans) {
        orphans = document.createElement('section');
        orphans.className = 'orphans';
        orphans.innerHTML = "<h4>On text that's no longer here</h4>";
        content.append(orphans);
      }
      orphans.append(thread);
      continue;
    }
    place(block, thread);
    if (c.status === 'resolved') pinResolved(c, block, thread);
    else block.closest('details')?.setAttribute('open', '');
  }
  placePins();
  drawComments();
  renderOverview();
  lastStatus = Object.fromEntries(comments.map(c => [c.id, c.status]));
  const open = comments.filter(c => c.status !== 'resolved').length;
  const toCheck = comments.filter(c => c.status === 'addressed').length;
  $('count').textContent = !open ? '' : `${open} open comment${open > 1 ? 's' : ''}` + (toCheck ? ` · ${toCheck} to check` : '');
  await updateSendBar();
}

// ---------- "Send to Claude" ----------

async function updateSendBar() {
  const drafts = JSON.parse(await fetchText('/__comments?drafts=1')).length;
  const bar = $('sendbar');
  if (drafts) {
    $('sendnote').textContent = `${drafts} pending comment${drafts > 1 ? 's' : ''}`;
    $('sendbtn').style.display = '';
    bar.classList.add('show');
  } else if (!bar.dataset.sent) {
    bar.classList.remove('show');
  }
}

$('sendbtn').onclick = async () => {
  await post('/__comments/send', {});
  const bar = $('sendbar');
  bar.dataset.sent = '1';
  const listening = (await fetchText('/__listening')) === '1';
  $('sendnote').textContent = listening ? 'Sent. Claude is picking them up.' : 'Sent. Tell Claude: "go through my comments".';
  $('sendbtn').style.display = 'none';
  setTimeout(() => { delete bar.dataset.sent; bar.classList.remove('show'); }, 8000);
  renderComments();
};
