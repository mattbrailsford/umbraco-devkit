// The "Comments" list beside the file list: every open comment in scope, the ones waiting on
// the reader first, in doc order or latest first. Ones with Claude or a later step fold into
// one line at the end. Clicking one glides to it.
import { $, ago, esc, fetchText, page, replay } from './state.js';
import { SUGGESTION } from './threads.js';

const MINE = ['addressed', 'replied', 'draft'];  // whose move: the reader's
const LABEL = { addressed: 'To check', replied: 'Waiting on you', draft: 'Not sent', sent: 'With Claude',
                working: 'With Claude', deferred: 'Later step' };
const ORDERS = {
  doc: { label: 'In doc order', icon: '<svg viewBox="0 0 16 16" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><path d="M2 3.5h7M2 8h7M2 12.5h4M12.5 2.5v10.5M10.5 11l2 2 2-2"/></svg>' },
  latest: { label: 'Latest first', icon: '<svg viewBox="0 0 16 16" width="16" height="16" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><circle cx="8" cy="8" r="6"/><path d="M8 4.75V8l2.25 1.5"/></svg>' },
};
const ICON_COMMENT = '<svg class="icon" viewBox="0 0 16 16" width="16" height="16"><path d="M1 2.75C1 1.784 1.784 1 2.75 1h10.5c.966 0 1.75.784 1.75 1.75v7.5A1.75 1.75 0 0 1 13.25 12H9.06l-2.573 2.573A1.458 1.458 0 0 1 4 13.543V12H2.75A1.75 1.75 0 0 1 1 10.25Zm1.75-.25a.25.25 0 0 0-.25.25v7.5c0 .138.112.25.25.25h2a.75.75 0 0 1 .75.75v2.19l2.72-2.72a.749.749 0 0 1 .53-.22h4.5a.25.25 0 0 0 .25-.25v-7.5a.25.25 0 0 0-.25-.25Z"/></svg>';

let showOthers = false;
let orderBy = (() => { try { return localStorage.getItem('commentOrder') || 'doc'; } catch { return 'doc'; } })();

const lastOf = c => c.replies.at(-1) || { body: c.body, created: c.created };

// "In doc order" uses the server's `place` for each comment: [folder, file rank, file, offset].
function sortComments(list) {
  if (orderBy === 'latest') return list.sort((a, b) => (lastOf(b).created || '').localeCompare(lastOf(a).created || ''));
  return list.sort((a, b) => {
    const x = a.place || [], y = b.place || [];
    for (let i = 0; i < 4; i++) {
      if (x[i] !== y[i]) return typeof x[i] === 'number' ? x[i] - y[i] : String(x[i]).localeCompare(String(y[i]));
    }
    return 0;
  });
}

// A one-line snippet: the latest message, with Markdown's punctuation taken out.
function snippet(text) {
  return text.replace(SUGGESTION, '± suggested change')
    .replace(/\[([^\]]*)\]\([^)]*\)/g, '$1').replace(/[*_`#>]+/g, '').replace(/^\s*[-+] /gm, '').replace(/\s+/g, ' ').trim();
}

// The icon's colour carries the status (named in its tooltip); the line under is just place and time.
function item(c) {
  const last = lastOf(c);
  const here = c.path === page.docPath;
  const where = [here ? '' : c.path.split('/').pop(), c.section].filter(Boolean).join(' › ');
  const label = c.status === 'deferred' && c.owner ? `For ${c.owner}` : LABEL[c.status];
  return `<a class="ov-item" href="${here ? '' : encodeURI(c.path)}#comment-${c.id}" title="${esc(label)}">`
    + ICON_COMMENT.replace('class="icon"', `class="icon ${c.status}"`)
    + `<span class="ov-body"><span class="ov-text">${esc(snippet(last.body))}</span>`
    + `<span class="ov-meta">${[where, ago(last.created)].filter(Boolean).map(esc).join(' · ')}</span></span></a>`;
}

function orderMenu() {
  return `<span class="ov-order"><button class="ov-order-btn" title="Order: ${ORDERS[orderBy].label}" aria-haspopup="true">${ORDERS[orderBy].icon}</button>`
    + `<span class="ov-menu" hidden>${Object.entries(ORDERS).map(([key, o]) =>
        `<button data-order="${key}"${key === orderBy ? ' class="on"' : ''}>${o.icon}${o.label}</button>`).join('')}</span></span>`;
}

export async function renderOverview() {
  const box = $('overview');
  if (!page.canComment) return box.replaceChildren();
  const open = JSON.parse(await fetchText('/__comments?open=1')).filter(c => !page.scoped || c.path.startsWith(page.home));
  if (!open.length) return box.replaceChildren();
  const mine = sortComments(open.filter(c => MINE.includes(c.status)));
  const others = sortComments(open.filter(c => !MINE.includes(c.status)));
  box.innerHTML = `<div class="box files ov-box"><div class="box-header">Comments${orderMenu()}</div>`
    + (mine.length ? mine.map(item).join('') : '<div class="ov-none">Nothing waiting on you.</div>')
    + (others.length ? `<button class="ov-more" title="Sent, with Claude, or left for a later step">`
      + `${showOthers ? 'Hide' : `${others.length} more,`} not waiting on you ${showOthers ? '▾' : '▸'}</button>`
      + (showOthers ? others.map(item).join('') : '') : '') + '</div>';

  box.querySelector('.ov-more')?.addEventListener('click', () => { showOthers = !showOthers; renderOverview(); });
  const menu = box.querySelector('.ov-menu');
  box.querySelector('.ov-order-btn').addEventListener('click', e => { e.stopPropagation(); menu.hidden = !menu.hidden; });
  menu.querySelectorAll('[data-order]').forEach(b => b.addEventListener('click', () => {
    orderBy = b.dataset.order;
    try { localStorage.setItem('commentOrder', orderBy); } catch {}
    renderOverview();
  }));
  // A comment on this page: glide to it instead of the browser's instant hash jump. One on
  // another page is left to the page switch (app.js), which glides once it's drawn.
  box.querySelectorAll('.ov-item[href^="#"]').forEach(a => a.addEventListener('click', e => {
    e.preventDefault();
    history.replaceState(null, '', a.getAttribute('href'));
    jumpToComment();
  }));
}

document.addEventListener('click', e => {
  if (!e.target.closest('.ov-order')) document.querySelectorAll('.ov-menu').forEach(m => { m.hidden = true; });
});

export function jumpToComment() {
  const t = location.hash.startsWith('#comment-') && document.getElementById(location.hash.slice(1));
  if (!t) return;
  t.scrollIntoView({ block: 'center', behavior: matchMedia('(prefers-reduced-motion: reduce)').matches ? 'auto' : 'smooth' });
  replay(t, 'flash');
}
addEventListener('hashchange', jumpToComment);
