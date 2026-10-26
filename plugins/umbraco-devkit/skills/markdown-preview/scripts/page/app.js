// The page's lifecycle: drawing the current file, noticing changes, and moving between
// files without a reload. Loaded by index.html; everything else hangs off the modules it
// imports.
import { $, content, fetchText, page, setPage, showStatus } from './state.js';
import { enhance, markBlocks, setHot } from './doc.js';
import { renderComments } from './threads.js';
import { showChanges } from './changes.js';
import { jumpToComment } from './comment-menu.js';
import { showKeysHint } from './keys.js';
import './editor.js';

// The file list sits beside the content on wide screens; on narrow ones it folds away.
$('filebox').open = matchMedia('(min-width: 901px)').matches;

// Drop the path trail above the scope's folder, and the separator after each dropped part.
function trimCrumbs() {
  if (!page.scoped) return;
  document.querySelectorAll('.crumbs [data-path]').forEach(el => {
    if (el.dataset.path.length < page.home.length) { el.nextElementSibling?.remove(); el.remove(); }
  });
}

async function loadFileList() {
  $('files').innerHTML = await fetchText('/__list?path=' + encodeURIComponent(page.folderPath)
    + '&current=' + encodeURIComponent(page.isFolder ? 'README.md' : page.path.slice(page.folderPath.length))
    + (page.scoped ? '&home=' + encodeURIComponent(page.home) : ''));
}

let pageFresh = true;  // a newly shown page starts at its top (or its #anchor)

async function load() {
  // Don't wipe a comment someone is halfway through writing.
  if (document.querySelector('.thread.new textarea')?.value || document.querySelector('.thread.editing')) return setTimeout(load, 1000);
  showStatus('Rendering…', 'busy');
  try {
    const y = pageFresh ? 0 : scrollY;
    await loadFileList();
    const res = await fetch('/__render?path=' + encodeURIComponent(page.docPath));
    const box = $('doc');
    if (res.status === 404 && page.isFolder) {
      box.hidden = true;  // a folder without a README shows just its file list
    } else {
      const text = await res.text();
      if (!res.ok) throw new Error(text);
      content.innerHTML = text;
      box.hidden = false;
      enhance();
      if (page.canComment) markBlocks();
      await showChanges();
      if (page.canComment) await renderComments();
    }
    scrollTo(0, y);
    showStatus('');
    if (pageFresh && location.hash)
      location.hash.startsWith('#comment-') ? jumpToComment() : document.getElementById(location.hash.slice(1))?.scrollIntoView();
    pageFresh = false;
  } catch (e) {
    showStatus(e.message, 'error');
  }
}

// Redraw threads and the file list's comment counts without touching the doc itself.
async function refreshComments() {
  if (!page.canComment || content.hidden || !content.innerHTML) return;
  await loadFileList();
  await renderComments();
}

// ---------- moving between files ----------
// Swaps the page's parts in place (path trail, file list, doc) rather than reloading, with
// a quick fade. Anything that can't be swapped falls back to a normal load.

let navigating = false;
let seen = null;  // the last change markers from the server, to tell what changed

async function navigate(href, push = true) {
  const u = new URL(href, location.href);
  navigating = true;
  content.classList.add('leaving');
  try {
    const res = await fetch(u.pathname + u.search);
    if (!res.ok) throw new Error('not a preview page');
    const next = new DOMParser().parseFromString(await res.text(), 'text/html');
    const boot = next.getElementById('boot');
    if (!boot) throw new Error('not a preview page');
    if (push) history.pushState(null, '', u.pathname + u.search + u.hash);
    document.title = next.title;
    document.querySelector('.crumbs').innerHTML = next.querySelector('.crumbs').innerHTML;
    $('docname').textContent = next.getElementById('docname').textContent;
    setPage(JSON.parse(boot.textContent).path);
    trimCrumbs();
    showKeysHint();
    setHot(null);
    pageFresh = true;
    seen = JSON.parse(await fetchText('/__changes?path=' + encodeURIComponent(page.path)));
    await load();
  } catch {
    location.assign(u.href);
  } finally {
    content.classList.remove('leaving');
    navigating = false;
  }
}

document.addEventListener('click', e => {
  const a = e.target.closest('a[href]');
  if (!a || e.defaultPrevented || e.button !== 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey || a.target) return;
  const u = new URL(a.href, location.href);
  if (u.origin !== location.origin || u.pathname.startsWith('/__') || !/(\.md|\/)$/.test(u.pathname)) return;
  if (u.pathname === location.pathname && u.search === location.search) return;  // an anchor on this page
  e.preventDefault();
  navigate(u.href);
});
addEventListener('popstate', () => navigate(location.href, false));

// ---------- noticing changes ----------
// A quick check every 0.4s rather than a held-open connection: browsers allow only six
// connections to one host, so a few open tabs each holding one would starve the rest.

async function poll() {
  if (navigating) return setTimeout(poll, 400);
  try {
    const now = JSON.parse(await fetchText('/__changes?path=' + encodeURIComponent(page.path)));
    if (now.navigate) { await navigate(now.navigate); return setTimeout(poll, 400); }  // another request reused this tab
    if ($('status').className === 'error' && $('status').textContent === 'Preview server stopped') showStatus('');
    if (!seen || now.doc !== seen.doc) { seen = now; await load(); }
    else if (now.comments !== seen.comments) { seen = now; await refreshComments(); }
  } catch {
    showStatus('Preview server stopped', 'error');
  }
  setTimeout(poll, 400);
}

trimCrumbs();
showKeysHint();
poll();
