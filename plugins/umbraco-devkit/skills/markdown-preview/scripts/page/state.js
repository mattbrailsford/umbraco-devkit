// Which page this tab is on, and small helpers every other module uses.
//
// The server hands the page its starting state as JSON in #boot. Moving to another file
// (app.js's navigate) calls setPage rather than reloading, so other modules read these
// values from `page` each time instead of keeping their own copies.

export const $ = id => document.getElementById(id);
export const content = $('content');

const boot = JSON.parse($('boot').textContent);

// A setting given in the address (?home=…, ?comments=off) sticks to this tab as you follow
// links inside it.
function tabSetting(name, fallback) {
  const given = new URLSearchParams(location.search).get(name);
  try { if (given) sessionStorage.setItem(name, given); return given || sessionStorage.getItem(name) || fallback; }
  catch { return given || fallback; }
}

export const page = {
  user: boot.user,
  home: tabSetting('home', '/'),  // the folder this tab is scoped to; '/' when unscoped
  path: '',         // the URL path of the file or folder shown
  scoped: false,    // whether this page sits inside the tab's scope
  canComment: false,
  isFolder: false,
  isDoc: false,     // a Markdown file or folder, rather than another file shown as code or a note
  folderPath: '',   // the folder the file list shows
  docPath: '',      // the file drawn: the page itself, or a folder's README.md
};

export function setPage(path) {
  page.path = path;
  page.scoped = page.home !== '/' && (path + '/').startsWith(page.home);
  page.isFolder = path.endsWith('/');
  page.isDoc = page.isFolder || path.endsWith('.md');  // not a source file shown as code
  // Comments are on for docs inside the scope (or everywhere, unscoped) unless the tab was opened read-only.
  page.canComment = page.isDoc && tabSetting('comments', 'on') !== 'off' && (page.home === '/' || page.scoped);
  page.folderPath = path.slice(0, path.lastIndexOf('/') + 1);
  page.docPath = page.isFolder ? path + 'README.md' : path;
}
setPage(boot.path);

export const esc = s => s.replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
export const norm = s => s.replace(/\s+/g, ' ').trim();

export async function fetchText(url) {
  const res = await fetch(url);
  const text = await res.text();
  if (!res.ok) throw new Error(text);
  return text;
}

export function showStatus(text, kind) {
  $('status').textContent = text;
  $('status').className = kind || '';
}

export async function post(url, body) {
  const res = await fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  if (!res.ok) showStatus(await res.text(), 'error');
}

export function ago(iso) {
  if (!iso) return '';
  const mins = Math.round((Date.now() - new Date(iso)) / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins} min ago`;
  const hours = Math.round(mins / 60);
  return hours < 24 ? `${hours} h ago` : new Date(iso).toLocaleDateString('en-GB');
}

export function avatar(who) {
  if (who === 'claude') return '<span class="avatar claude">C</span>';
  return page.user.login
    ? `<span class="avatar"><img src="https://github.com/${encodeURIComponent(page.user.login)}.png?size=48" alt=""></span>`
    : '<span class="avatar">Y</span>';
}

// Restart a one-off animation class on an element, even if it's already run.
export function replay(el, cls) {
  el.classList.remove(cls);
  void el.offsetWidth;
  el.classList.add(cls);
}
