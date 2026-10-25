// The "N open comments" count in the doc's header, which opens a list of them: in doc order or
// latest first, the icon's colour saying whose move it is. Clicking one glides to it. Other
// files' comments show as the counts in the file list.
import { $, ago, esc, replay } from './state.js';
import { SUGGESTION } from './threads.js';

const LABEL = { addressed: 'To check', replied: 'Waiting on you', draft: 'Not sent', sent: 'With Claude',
                working: 'With Claude', deferred: 'Later step' };
const ORDERS = {
  doc: { label: 'In doc order', icon: '<svg viewBox="0 0 16 16" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M2 3.5h7M2 8h7M2 12.5h4M12.5 2.5v10.5M10.5 11l2 2 2-2"/></svg>' },
  latest: { label: 'Latest first', icon: '<svg viewBox="0 0 16 16" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="8" cy="8" r="6"/><path d="M8 4.75V8l2.25 1.5"/></svg>' },
};
const ICON_COMMENT = '<svg class="icon" viewBox="0 0 16 16" width="16" height="16"><path d="M1 2.75C1 1.784 1.784 1 2.75 1h10.5c.966 0 1.75.784 1.75 1.75v7.5A1.75 1.75 0 0 1 13.25 12H9.06l-2.573 2.573A1.458 1.458 0 0 1 4 13.543V12H2.75A1.75 1.75 0 0 1 1 10.25Zm1.75-.25a.25.25 0 0 0-.25.25v7.5c0 .138.112.25.25.25h2a.75.75 0 0 1 .75.75v2.19l2.72-2.72a.749.749 0 0 1 .53-.22h4.5a.25.25 0 0 0 .25-.25v-7.5a.25.25 0 0 0-.25-.25Z"/></svg>';
const CARET = '<svg class="caret" viewBox="0 0 16 16" width="12" height="12"><path d="m4.427 7.427 3.396 3.396a.25.25 0 0 0 .354 0l3.396-3.396A.25.25 0 0 0 11.396 7H4.604a.25.25 0 0 0-.177.427Z"/></svg>';

let open = [];
let menuOpen = false;
let orderBy = (() => { try { return localStorage.getItem('commentOrder') || 'doc'; } catch { return 'doc'; } })();

const lastOf = c => c.replies.at(-1) || { body: c.body, created: c.created };

// Doc order is where each thread sits on the page; one with nowhere to sit goes last.
function sortComments(list) {
  if (orderBy === 'latest') return list.sort((a, b) => (lastOf(b).created || '').localeCompare(lastOf(a).created || ''));
  const at = c => document.getElementById('comment-' + c.id);
  return list.sort((a, b) => {
    const x = at(a), y = at(b);
    if (!x || !y) return !x - !y;
    return x.compareDocumentPosition(y) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1;
  });
}

// A one-line snippet: the latest message, with Markdown's punctuation taken out.
function snippet(text) {
  return text.replace(SUGGESTION, '± suggested change')
    .replace(/\[([^\]]*)\]\([^)]*\)/g, '$1').replace(/[*_`#>]+/g, '').replace(/^\s*[-+] /gm, '').replace(/\s+/g, ' ').trim();
}

function item(c) {
  const last = lastOf(c);
  const label = c.status === 'deferred' && c.owner ? `For ${c.owner}` : LABEL[c.status];
  return `<a class="cm-item" href="#comment-${c.id}" title="${esc(label)}">`
    + ICON_COMMENT.replace('class="icon"', `class="icon ${c.status}"`)
    + `<span class="cm-body"><span class="cm-text">${esc(snippet(last.body))}</span>`
    + `<span class="cm-meta">${[c.section, ago(last.created)].filter(Boolean).map(esc).join(' · ')}</span></span></a>`;
}

function draw() {
  const count = $('count');
  if (!open.length) { menuOpen = false; return count.replaceChildren(); }
  const toCheck = open.filter(c => c.status === 'addressed').length;
  const next = orderBy === 'doc' ? 'latest' : 'doc';
  count.innerHTML = `<button class="cm-btn" aria-haspopup="true" aria-expanded="${menuOpen}">`
    + `${open.length} open comment${open.length > 1 ? 's' : ''}${toCheck ? ` · ${toCheck} to check` : ''}${CARET}</button>`
    + `<div class="cm-menu"${menuOpen ? '' : ' hidden'}><div class="cm-head">Open comments`
    + `<button class="cm-order" title="${ORDERS[orderBy].label}: click for ${ORDERS[next].label.toLowerCase()}">${ORDERS[orderBy].icon}</button></div>`
    + `<div class="cm-list">${sortComments([...open]).map(item).join('')}</div></div>`;

  count.querySelector('.cm-btn').onclick = () => { menuOpen = !menuOpen; draw(); };
  count.querySelector('.cm-order').onclick = () => {
    orderBy = next;
    try { localStorage.setItem('commentOrder', orderBy); } catch {}
    draw();
  };
  // Glide to it, rather than the browser's instant hash jump.
  count.querySelectorAll('.cm-item').forEach(a => a.addEventListener('click', e => {
    e.preventDefault();
    menuOpen = false;
    draw();
    history.replaceState(null, '', a.getAttribute('href'));
    jumpToComment();
  }));
}

// Called with this doc's comments whenever they're drawn.
export function renderOverview(comments) {
  open = comments.filter(c => c.status !== 'resolved');
  draw();
}

function close() {
  if (menuOpen) { menuOpen = false; draw(); }
}
// The event's path, not e.target: a click inside redraws the menu, taking its target off the page.
document.addEventListener('click', e => { if (!e.composedPath().some(el => el.id === 'count')) close(); });
document.addEventListener('keydown', e => { if (e.key === 'Escape') close(); });

export function jumpToComment() {
  const t = location.hash.startsWith('#comment-') && document.getElementById(location.hash.slice(1));
  if (!t) return;
  t.scrollIntoView({ block: 'center', behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth' });
  replay(t, 'flash');
}
addEventListener('hashchange', jumpToComment);
