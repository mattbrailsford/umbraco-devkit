#!/usr/bin/env python3
"""Preview Markdown exactly as GitHub renders it, with live reload.

Usage:
  preview.py <file-or-folder> [--scope [DIR]] [--no-comments] [--root DIR] [--port N] [--no-open]
  preview.py wait                       block until the reviewer sends comments, then print them
  preview.py comments [--file PATH...]  list comments waiting on Claude, or open ones on PATH
  preview.py reply ID TEXT [--done | --defer STEP] [--move TEXT]

Renders through GitHub's Markdown API (with the `gh` CLI's sign-in), serves the page on
127.0.0.1 and refreshes it in place whenever the file changes on disk. A folder opens
GitHub-style: its file list beside its README. Readers can leave review comments on any
line, then send them to Claude in one batch.

One server runs per git worktree; asking again reuses it, and an open preview tab is sent to
the new page rather than opening another. The server stops once its worktree is removed.
Comments live in the worktree's git folder, so they're never committed and any step can read
them without the server running.
"""
import argparse
import atexit
import hashlib
import html
import http.client
import json
import mimetypes
import os
import re
import signal
import subprocess
import sys
import tempfile
import threading
import time
import urllib.parse
import urllib.request
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

CSS_URL = "https://cdn.jsdelivr.net/npm/github-markdown-css@5.6.1/github-markdown.css"
STATE_DIR = os.path.join(tempfile.gettempdir(), "umbraco-devkit-preview")

ICON_DIR = ('<svg class="icon dir" viewBox="0 0 16 16" width="16" height="16"><path d="M1.75 1A1.75 1.75 0 0 0 0 2.75v10.5C0 '
            '14.216.784 15 1.75 15h12.5A1.75 1.75 0 0 0 16 13.25v-8.5A1.75 1.75 0 0 0 14.25 3H7.5a.25.25 0 0 1-.2-.1l-.9-1.2C6.07 '
            '1.26 5.55 1 5 1H1.75Z"/></svg>')
ICON_FILE = ('<svg class="icon" viewBox="0 0 16 16" width="16" height="16"><path d="M2 1.75C2 .784 2.784 0 3.75 0h6.586c.464 0 '
             '.909.184 1.237.513l2.914 2.914c.329.328.513.773.513 1.237v9.586A1.75 1.75 0 0 1 13.25 16h-9.5A1.75 1.75 0 0 1 2 '
             '14.25Zm1.75-.25a.25.25 0 0 0-.25.25v12.5c0 .138.112.25.25.25h9.5a.25.25 0 0 0 .25-.25V6h-2.75A1.75 1.75 0 0 1 9 '
             '4.25V1.5Zm6.75.062V4.25c0 .138.112.25.25.25h2.688l-.011-.013-2.914-2.914-.013-.011Z"/></svg>')

PAGE = """<!doctype html>
<html>
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>__TITLE__</title>
<style>
__CSS__
:root { --bg: #ffffff; --fg: #1f2328; --muted: #59636e; --border: #d1d9e0; --header: #f6f8fa; --link: #0969da; --hover: #f6f8fa; }
@media (prefers-color-scheme: dark) {
  :root { --bg: #0d1117; --fg: #f0f6fc; --muted: #9198a1; --border: #3d444d; --header: #151b23; --link: #4493f8; --hover: #151b23; }
}
body { margin: 0; background: var(--bg); color: var(--fg); font: 14px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }
main { box-sizing: border-box; max-width: 1280px; margin: 0 auto; padding: 24px 16px 48px; }
.layout { display: grid; grid-template-columns: 260px minmax(0, 1fr) 24px; gap: 24px; align-items: start; }
aside { position: sticky; top: 16px; max-height: calc(100vh - 32px); overflow-y: auto; }
aside summary { display: none; }
@media (max-width: 900px) {
  .layout { grid-template-columns: minmax(0, 1fr) 24px; gap: 12px; }
  aside { grid-column: 1 / -1; }
  aside { position: static; max-height: none; }
  aside summary { display: block; cursor: pointer; padding: 8px 0; font-weight: 600; color: var(--link); }
}
.files a.current { background: var(--hover); font-weight: 600; box-shadow: inset 2px 0 0 var(--link); }
.crumbs { font-size: 20px; margin-bottom: 16px; word-break: break-all; }
.crumbs a { color: var(--link); text-decoration: none; }
.crumbs a:hover { text-decoration: underline; }
.crumbs .sep { color: var(--muted); margin: 0 4px; }
.crumbs .here { font-weight: 600; }
.box { border: 1px solid var(--border); border-radius: 6px; margin-bottom: 16px; overflow: hidden; }
.box-header { background: var(--header); border-bottom: 1px solid var(--border); padding: 10px 16px; font-weight: 600; }
.files a { display: flex; gap: 10px; align-items: center; padding: 8px 16px; color: var(--fg); text-decoration: none; border-top: 1px solid var(--border); }
.files a:first-child { border-top: 0; }
.files a:hover { background: var(--hover); color: var(--link); }
.icon { fill: var(--muted); flex: none; }
.icon.dir { fill: #54aeff; }
.markdown-body { box-sizing: border-box; padding: 32px; }
@media (max-width: 767px) { .markdown-body { padding: 16px; } }
.sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; }
#status { position: fixed; top: 8px; right: 8px; padding: 4px 10px; border-radius: 6px; font-size: 12px; display: none; }
#status.error { display: block; background: #d1242f; color: #fff; }
#status.busy { display: block; background: #0969da; color: #fff; }
:root { --pending: #9a6700; --pending-bg: #fff8c5; --done: #1a7f37; --accent-bg: #ddf4ff; --deferred: #8250df; }
@media (prefers-color-scheme: dark) { :root { --pending: #d29922; --pending-bg: #bb800926; --done: #3fb950; --accent-bg: #388bfd1a; --deferred: #ab7df8; } }
.box-header { display: flex; justify-content: space-between; }
#doc { overflow: visible; }
#doc .box-header { border-radius: 6px 6px 0 0; }

.box-header .count { font-weight: 400; color: var(--muted); }
.files .dot { margin-left: auto; min-width: 18px; padding: 0 6px; border-radius: 10px; background: var(--link); color: #fff; font-size: 12px; text-align: center; }
/* Hover a block to get a "+" in the gutter, like a PR diff line. */
#content [data-block] { position: relative; }
#content math-renderer[data-block] { display: block; }
#content markdown-accessiblity-table { display: block; position: relative; }
#row-add { position: absolute; z-index: 4; }
#content tr.thread-row > td { padding: 8px; background: var(--bg); }
#content .row-thread { position: absolute; left: 9px; right: 0; margin: 0; z-index: 2; }
#content .hot { background: var(--accent-bg); border-radius: 4px; cursor: pointer; }
#content .thread { cursor: auto; }
.add-btn { position: absolute; left: -26px; top: 2px; width: 20px; height: 20px; border-radius: 6px; border: 0; background: var(--link); color: #fff; font: 600 14px/20px sans-serif; cursor: pointer; display: none; padding: 0; }
#content .hot > .add-btn { display: block; }
#sel-btn { position: absolute; display: none; z-index: 5; padding: 4px 10px; border: 0; border-radius: 6px; background: var(--link); color: #fff; font-size: 12px; cursor: pointer; }
.thread { border: 1px solid var(--border); border-radius: 8px; margin: 8px 0 16px; background: var(--bg); font-size: 14px; line-height: 1.5; overflow: hidden; }
.thread.draft { border-color: var(--pending); border-left-width: 3px; }
.thread .msg { display: flex; gap: 10px; padding: 12px 14px; }
.thread .msg + .msg { border-top: 1px solid var(--border); }
.thread .msg.claude { background: var(--header); }
.avatar { flex: none; width: 24px; height: 24px; border-radius: 50%; display: grid; place-items: center; font: 600 11px/1 sans-serif; color: #fff; background: #6e7781; overflow: hidden; }
.avatar img { width: 100%; height: 100%; }
.avatar.claude { background: #d97757; }
.msg-main { min-width: 0; flex: 1; }
.msg-head { display: flex; align-items: baseline; gap: 6px; flex-wrap: wrap; }
.msg-head b { font-weight: 600; }
.msg-head .when { color: var(--muted); font-size: 12px; }
.msg-head .state { margin-left: auto; font-size: 12px; display: inline-flex; align-items: center; gap: 5px; }
.state::before { content: ""; width: 7px; height: 7px; border-radius: 50%; background: currentColor; }
.state.draft { color: var(--pending); }
.state.sent, .state.working { color: var(--link); }
.state.replied { color: var(--pending); }
.state.deferred { color: var(--deferred); }
.state.working::before { animation: pulse 1.2s ease-in-out infinite; }
@keyframes pulse { 50% { opacity: .25; } }
.state.resolved { color: var(--done); }
.msg-body { margin-top: 2px; overflow-wrap: anywhere; }
.thread.draft:not(.editing) .msg.pending .msg-body { cursor: text; border-radius: 4px; margin-left: -4px; padding: 0 4px; }
.thread.draft:not(.editing) .msg.pending .msg-body:hover { background: var(--pending-bg); }
.reply-box { border-top: 1px solid var(--border); padding: 8px 14px 8px 48px; }
.thread-actions { padding: 0 14px 10px 48px; }
.thread-actions:first-of-type, .msg + .thread-actions { border-top: 1px solid var(--border); padding-top: 10px; }
.thread-actions .btn { margin-left: 0; }
.reply-box textarea { width: 100%; box-sizing: border-box; padding: 5px 8px; border: 1px solid var(--border); border-radius: 6px; background: var(--bg); color: var(--fg); font: inherit; resize: none; }
.reply-box.active textarea { min-height: 64px; resize: vertical; }
.reply-actions { display: none; text-align: right; margin-top: 6px; }
.reply-box.active .reply-actions { display: block; }
.msg-was { margin: 4px 0 2px; padding-left: 8px; border-left: 2px solid var(--border); color: var(--muted); font-size: 13px;
           white-space: nowrap; overflow: hidden; text-overflow: ellipsis; cursor: pointer; }
.msg-was.open { white-space: normal; }
.msg-was s { text-decoration-color: color-mix(in srgb, var(--muted) 70%, transparent); }
.msg-quote { margin: 4px 0 2px; padding-left: 8px; border-left: 2px solid var(--border); color: var(--muted); font-size: 13px; }
.link-btn { border: 0; background: none; padding: 0; color: var(--muted); font-size: 12px; cursor: pointer; }
.link-btn:hover { color: var(--link); text-decoration: underline; }
.thread .summary { display: none; padding: 8px 14px; color: var(--muted); font-size: 13px; cursor: pointer; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.thread .summary:hover { color: var(--fg); }
.thread .summary .tick { color: var(--done); font-weight: 600; margin-right: 4px; }
.thread.resolved { display: none; }
.thread.resolved.open { display: block; }
.resolved-pin { position: absolute; top: 2px; height: 20px; min-width: 20px; padding: 0 4px; border: 0; border-radius: 10px; background: none; color: var(--done); opacity: .75; font: 600 11px/20px sans-serif; cursor: pointer; display: flex; align-items: center; gap: 2px; }
.resolved-pin:hover, .resolved-pin.on { opacity: 1; background: var(--hover); box-shadow: 0 0 0 1px var(--border); }
.resolved-pin svg { fill: currentColor; }
.thread.outdated .msg:first-child .msg-quote::before { content: "No longer in the doc · "; font-weight: 600; }
.thread.line-removed .msg:first-child .msg-quote::before { content: "Line removed · "; font-weight: 600; }
.state.addressed { color: var(--done); }
#content .orphans { margin-top: 32px; padding-top: 16px; border-top: 1px solid var(--border); }
#content .orphans h4 { margin: 0 0 8px; color: var(--muted); font-size: 13px; font-weight: 600; }
mark.cmark { background: var(--pending-bg); color: inherit; border-bottom: 2px solid var(--pending); padding: 0 1px; }
.comment-form { padding: 12px 14px; display: flex; gap: 10px; }
.thread.editing .msg-body textarea, .comment-form textarea { width: 100%; box-sizing: border-box; min-height: 64px; padding: 8px; border: 1px solid var(--border); border-radius: 6px; background: var(--bg); color: var(--fg); font: inherit; resize: vertical; }
.btn { padding: 4px 12px; border-radius: 6px; border: 1px solid var(--border); background: var(--header); color: var(--fg); font: 500 13px/20px sans-serif; cursor: pointer; margin-left: 6px; }
.btn.primary { background: #1f883d; border-color: #1f883d; color: #fff; }
#sendbar { position: fixed; bottom: 20px; left: 50%; transform: translateX(-50%); display: none; align-items: center; gap: 12px; padding: 10px 12px 10px 16px; border: 1px solid var(--border); border-radius: 8px; background: var(--bg); box-shadow: 0 8px 24px rgba(0,0,0,.2); z-index: 10; }
#sendbar.show { display: flex; }
.thread.flash { animation: flash 1s ease-out; }
#content .just-resolved { animation: resolved-glow 1.8s ease-out; border-radius: 4px; }
@keyframes resolved-glow { 0%, 25% { background: color-mix(in srgb, var(--done) 30%, transparent); } 100% { background: transparent; } }
.resolved-pin.pop { animation: pop .7s cubic-bezier(.3, 1.6, .5, 1); opacity: 1; }
@keyframes pop { 0% { transform: scale(.3); opacity: 0; } 100% { transform: scale(1); opacity: 1; } }
@keyframes flash { from { box-shadow: 0 0 0 4px var(--link); } }
kbd { display: inline-block; padding: 1px 6px; border: 1px solid var(--border); border-bottom-width: 2px; border-radius: 5px; background: var(--header); font: 11px/16px ui-monospace, monospace; color: var(--fg); }
#keys-hint { position: fixed; left: 16px; bottom: 16px; border: 0; background: none; color: var(--muted); font-size: 12px; cursor: pointer; }
#keys-hint:hover { color: var(--fg); }
#keys { position: fixed; left: 16px; bottom: 44px; display: none; width: 320px; padding: 12px 16px; border: 1px solid var(--border); border-radius: 8px; background: var(--bg); box-shadow: 0 8px 24px rgba(0,0,0,.2); z-index: 11; font-size: 13px; }
#keys.show { display: block; }
#keys .keys-head { font-weight: 600; margin-bottom: 8px; }
#keys dl { display: grid; grid-template-columns: auto 1fr; gap: 6px 12px; margin: 0; }
#keys dt { white-space: nowrap; }
#keys dd { margin: 0; color: var(--muted); }
#sendbar .note { color: var(--muted); }
</style>
</head>
<body>
<div id="status"></div>
<main>
<nav class="crumbs">__CRUMBS__</nav>
<div class="layout">
<aside><details id="filebox"><summary>Files in this folder</summary><div id="files"></div></details></aside>
<div class="box" id="doc" hidden>
  <div class="box-header"><span>__DOCNAME__</span><span class="count" id="count"></span></div>
  <article id="content" class="markdown-body"></article>
</div>
</div>
</main>
<button id="sel-btn">Comment</button>
<button id="row-add" class="add-btn" title="Comment on this row">+</button>
<div id="keys"><div class="keys-head">Keyboard shortcuts</div><dl></dl></div>
<button id="keys-hint" onclick="document.getElementById('keys').classList.toggle('show')"><kbd>?</kbd> shortcuts</button>
<div id="sendbar"><span class="note" id="sendnote"></span><button class="btn primary" id="sendbtn" title="Shift+S">Send to Claude</button></div>
<script src="https://cdn.jsdelivr.net/npm/mermaid@11.3.0/dist/mermaid.min.js"></script>
<script>
window.MathJax = { tex: { inlineMath: [['$', '$']], displayMath: [['$$', '$$']] } };
</script>
<script async src="https://cdn.jsdelivr.net/npm/mathjax@3.2.2/es5/tex-mml-chtml.js"></script>
<script>
const pagePath = __PATH__;
// A scoped tab (opened on a plan folder, say) keeps its scope as you follow links inside it.
function tabSetting(name, fallback) {
  const given = new URLSearchParams(location.search).get(name);
  try { if (given) sessionStorage.setItem(name, given); return given || sessionStorage.getItem(name) || fallback; }
  catch { return given || fallback; }
}
const home = tabSetting('home', '/');
const scoped = home !== '/' && (pagePath + '/').startsWith(home);
// Comments are on inside the scope (or everywhere, unscoped) unless the tab was opened read-only.
const canComment = tabSetting('comments', 'on') !== 'off' && (home === '/' || scoped);
if (scoped) {
  // Drop the path trail above the scope's folder, and the separator after each dropped part.
  document.querySelectorAll('.crumbs [data-path]').forEach(el => {
    if (el.dataset.path.length < home.length) { el.nextElementSibling?.remove(); el.remove(); }
  });
}
const isFolder = pagePath.endsWith('/');
const folderPath = pagePath.slice(0, pagePath.lastIndexOf('/') + 1);
// The file list sits beside the content on wide screens; on narrow ones it folds away.
document.getElementById('filebox').open = matchMedia('(min-width: 901px)').matches;
const content = document.getElementById('content');
const status = document.getElementById('status');
const dark = matchMedia('(prefers-color-scheme: dark)').matches;
mermaid.initialize({ startOnLoad: false, theme: dark ? 'dark' : 'default' });
let renderCount = 0;

function showStatus(text, kind) {
  status.textContent = text;
  status.className = kind || '';
}

// GitHub finishes several things in the browser; repeat them after each render.
function enhance() {
  const seen = {};
  content.querySelectorAll('h1,h2,h3,h4,h5,h6').forEach(h => {
    let slug = h.textContent.trim().toLowerCase().replace(/[^\\p{L}\\p{N}\\s_-]/gu, '').replace(/\\s/g, '-');
    const n = seen[slug] = (seen[slug] ?? -1) + 1;
    if (n) slug += '-' + n;
    h.id = slug;
  });
  content.querySelectorAll('[id^="user-content-"]').forEach(el => el.id = el.id.slice(13));
  content.querySelectorAll('a[href^="#user-content-"]').forEach(a => a.setAttribute('href', '#' + a.getAttribute('href').slice(14)));

  const run = ++renderCount;
  content.querySelectorAll('div.highlight-source-mermaid > pre').forEach(async (pre, i) => {
    pre.dataset.source = 'Diagram: ' + norm(pre.textContent);
    try { pre.innerHTML = (await mermaid.render(`mermaid-${run}-${i}`, pre.textContent)).svg; } catch (e) { console.error(e); }
  });

  content.querySelectorAll('math-renderer').forEach(m => { m.dataset.tex = norm(m.textContent); });
  if (window.MathJax?.typesetPromise) {
    MathJax.typesetClear([content]);
    MathJax.typesetPromise([content]).catch(console.error);
  }
}

async function fetchText(url) {
  const res = await fetch(url);
  const text = await res.text();
  if (!res.ok) throw new Error(text);
  return text;
}

// ---- Review comments: drafts pile up on the page, then go to Claude in one batch. ----
const docPath = isFolder ? pagePath + 'README.md' : pagePath;
const user = __USER__;
const esc = s => s.replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const norm = s => s.replace(/\\s+/g, ' ').trim();
let hot = null;

function blockText(el) {
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

function submitOnEnter(box, submit, cancel) {
  box.addEventListener('keydown', e => {
    if (e.key === 'Enter' && !e.shiftKey && !e.isComposing) { e.preventDefault(); submit(); }
    if (e.key === 'Escape') { e.preventDefault(); cancel(); }
  });
}

function markBlocks() {
  const kinds = 'p, li, h1, h2, h3, h4, h5, h6, pre, tr, math-renderer.js-display-math';
  content.querySelectorAll(kinds).forEach(el => {
    if (el.matches('li') && el.querySelector(':scope > p')) return;
    // Skip hidden headings, and anything inside a block already taken (a table's cells, say).
    if (el.matches('.sr-only') || el.parentElement.closest('[data-block]:not(li)')) return;
    if (el.matches('math-renderer') && el.closest('p')) return;
    el.dataset.block = '';
    if (el.matches('tr')) return;
    const btn = document.createElement('button');
    btn.className = 'add-btn';
    btn.textContent = '+';
    btn.title = 'Comment on this';
    btn.onclick = e => { e.stopPropagation(); openForm(el, blockText(el), '', ''); };
    el.prepend(btn);
  });
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

function place(block, el) {
  if (block.matches('tr')) {
    const row = document.createElement('tr');
    row.className = 'thread-row';
    row.innerHTML = `<td colspan="${block.cells.length}"><div class="thread-slot"></div></td>`;
    // Keep threads in order under the row, after any already there.
    let after = block;
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

// The heading of the section a block sits in (or the block itself, if it's a heading).
function sectionOf(block) {
  let el = block;
  while (el.parentElement && el.parentElement !== content) el = el.parentElement;
  for (; el; el = el.previousElementSibling)
    if (el.matches('h1, h2, h3, h4, h5, h6')) return blockText(el);
  return '';
}

function removeThread(thread) {
  thread?.slotRow?.remove();
  thread?.remove();
}

// Size each slot to its thread, then line each thread up with its slot. Two passes, since
// growing one slot moves every slot below it.
function layoutRowThreads() {
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

function openForm(block, quote, prefix, suffix) {
  removeThread(document.querySelector('.thread.new'));
  const thread = document.createElement('div');
  thread.className = 'thread new';
  const quoteLine = quote !== blockText(block) ? `<div class="msg-quote">${esc(quote)}</div>` : '';
  thread.innerHTML = `<div class="comment-form">${avatar('you')}<div class="msg-main">${quoteLine}<textarea placeholder="Leave a comment · Enter to add, Shift+Enter for a new line"></textarea>
    <div style="text-align:right;margin-top:6px"><button class="btn cancel">Cancel</button><button class="btn primary add">Add comment</button></div></div></div>`;
  place(block, thread);
  const box = thread.querySelector('textarea');
  box.focus();
  submitOnEnter(box, () => thread.querySelector('.add').click(), () => thread.querySelector('.cancel').click());
  thread.querySelector('.cancel').onclick = () => removeThread(thread);
  thread.querySelector('.add').onclick = async () => {
    if (!box.value.trim()) return;
    await post('/__comments', { path: docPath, quote, prefix, suffix, section: sectionOf(block), body: box.value.trim() });
    removeThread(thread);
    renderComments();
  };
}

const rowAdd = document.getElementById('row-add');
rowAdd.onclick = () => hot && openForm(hot, blockText(hot), '', '');

function setHot(block) {
  hot?.classList.remove('hot');
  hot = block;
  hot?.classList.add('hot');
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

// The element a table's gutter items (the row "+", resolved ticks) are measured against.
function tableBox(row) {
  return row.closest('markdown-accessiblity-table') || row.closest('table');
}

// Pinned as "Column: value · Column: value", so a short row reads clearly to Claude and two
// look-alike rows don't get mixed up. The header row stands for the whole table.
function rowText(tr) {
  const cells = [...tr.cells].map(c => norm(c.textContent));
  if (tr.closest('thead')) return 'Table: ' + cells.join(' | ');
  const heads = [...(tr.closest('table').tHead?.rows[0]?.cells || [])].map(c => norm(c.textContent));
  return cells.map((c, i) => heads[i] ? `${heads[i]}: ${c}` : c).join(' · ');
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
  const mid = innerHeight / 2;
  const tops = threads.map(t => t.getBoundingClientRect().top - mid);
  const i = step > 0 ? tops.findIndex(t => t > 5) : tops.map(t => t < -5).lastIndexOf(true);
  const target = threads[i < 0 ? (step > 0 ? 0 : threads.length - 1) : i];
  target.scrollIntoView({ block: 'center', behavior: 'smooth' });
  target.classList.remove('flash');
  void target.offsetWidth;
  target.classList.add('flash');
}

if (!canComment) document.getElementById('keys-hint').hidden = true;

const SHORTCUTS = [
  ['j / ↓', 'Next line'], ['k / ↑', 'Previous line'], ['c / Enter', 'Comment on the line'],
  ['n', 'Next open comment'], ['p', 'Previous open comment'], ['e', 'Edit your pending comment on the line'],
  ['r', 'Reply on the line'], ['Shift+S', 'Send pending comments to Claude'],
  ['Enter', 'Add or save, in a comment box'], ['Shift+Enter', 'New line, in a comment box'], ['Esc', 'Cancel, or close this list'],
  ['?', 'Show or hide this list'],
];
const help = document.getElementById('keys');
help.querySelector('dl').innerHTML = SHORTCUTS.map(([k, v]) => `<dt>${k.split(' / ').map(x => `<kbd>${x}</kbd>`).join(' ')}</dt><dd>${v}</dd>`).join('');

document.addEventListener('keydown', e => {
  if (e.target.closest('textarea, input') || e.metaKey || e.ctrlKey || e.altKey) return;
  const threadOf = block => {
    if (!block) return null;
    if (block.matches('li')) return block.querySelector(':scope > .thread:not(.new)');
    if (block.matches('tr')) return block.nextElementSibling?.matches('.thread-row') && block.nextElementSibling.thread;
    return block.nextElementSibling?.matches('.thread') && block.nextElementSibling;
  };
  const keys = {
    j: () => moveLine(1), ArrowDown: () => moveLine(1), k: () => moveLine(-1), ArrowUp: () => moveLine(-1),
    c: () => hot && openForm(hot, blockText(hot), '', ''), Enter: () => hot && openForm(hot, blockText(hot), '', ''),
    n: () => moveThread(1), p: () => moveThread(-1),
    e: () => threadOf(hot)?.querySelector('.edit')?.click(),
    r: () => {
      const thread = threadOf(hot);
      if (thread?.classList.contains('resolved'))
        [...content.querySelectorAll('.resolved-pin')].find(p => p.row === hot || p.parentElement === hot)?.click();
      thread?.querySelector('.reply-box textarea')?.focus();
    },
    S: () => document.getElementById('sendbar').classList.contains('show') && document.getElementById('sendbtn').click(),
    '?': () => help.classList.toggle('show'),
    Escape: () => { help.classList.remove('show'); setHot(null); },
  };
  const action = keys[e.key];
  if (!action) return;
  // Arrow keys still scroll the page until you've started moving between lines.
  if ((e.key === 'ArrowDown' || e.key === 'ArrowUp') && !hot) return;
  e.preventDefault();
  action();
});

const selBtn = document.getElementById('sel-btn');
document.addEventListener('mouseup', e => {
  if (e.target === selBtn) return;
  const sel = getSelection();
  const text = norm(sel.toString());
  const block = sel.anchorNode?.parentElement?.closest('[data-block]');
  if (!text || !block || !content.contains(block)) { selBtn.style.display = 'none'; return; }
  const rect = sel.getRangeAt(0).getBoundingClientRect();
  selBtn.style.left = (rect.right + scrollX + 6) + 'px';
  selBtn.style.top = (rect.top + scrollY - 4) + 'px';
  selBtn.style.display = 'block';
  selBtn.onclick = () => {
    const full = blockText(block);
    const at = Math.max(0, full.indexOf(text));
    selBtn.style.display = 'none';
    openForm(block, text, full.slice(Math.max(0, at - 30), at), full.slice(at + text.length, at + text.length + 30));
  };
});
selBtn.addEventListener('mousedown', e => e.preventDefault());

async function post(url, body) {
  const res = await fetch(url, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(body) });
  if (!res.ok) showStatus(await res.text(), 'error');
}

function findBlock(c) {
  if (!c.quote) return null;
  const blocks = [...content.querySelectorAll('[data-block]')].map(el => [el, blockText(el)]);
  const exact = blocks.find(([, t]) => t.includes(c.prefix + c.quote + c.suffix));
  const loose = blocks.find(([, t]) => t.includes(c.quote));
  if (exact || loose) return (exact || loose)[0];
  // The text was edited: follow it to the block sharing most of its words, if any shares most.
  const words = new Set(c.quote.toLowerCase().split(' '));
  let best = null, bestScore = 0.5;
  for (const [el, t] of blocks) {
    const shared = t.toLowerCase().split(' ').filter(w => words.has(w)).length / words.size;
    if (shared > bestScore) [best, bestScore] = [el, shared];
  }
  return best;
}

// Only the reader resolves: Claude's best is "addressed", which waits on their check.
const STATE = { draft: 'Pending', sent: 'Sent', working: 'Claude is on it', replied: 'Waiting on you',
                addressed: 'Done, please check', deferred: 'Left for a later step', resolved: 'Resolved' };
const TICK = '<svg viewBox="0 0 16 16" width="14" height="14"><path d="M13.78 4.22a.75.75 0 0 1 0 1.06l-7.25 7.25a.75.75 0 0 1-1.06 0L2.22 9.28a.75.75 0 0 1 1.06-1.06L6 10.94l6.72-6.72a.75.75 0 0 1 1.06 0Z"/></svg>';

function avatar(who) {
  if (who === 'claude') return '<span class="avatar claude">C</span>';
  return user.login
    ? `<span class="avatar"><img src="https://github.com/${encodeURIComponent(user.login)}.png?size=48" alt=""></span>`
    : '<span class="avatar">Y</span>';
}

function ago(iso) {
  if (!iso) return '';
  const mins = Math.round((Date.now() - new Date(iso)) / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins} min ago`;
  const hours = Math.round(mins / 60);
  return hours < 24 ? `${hours} h ago` : new Date(iso).toLocaleDateString('en-GB');
}

function message(who, name, when, body, extra) {
  return `<div class="msg ${who}">${avatar(who)}<div class="msg-main"><div class="msg-head"><b>${esc(name)}</b>`
    + `<span class="when">${ago(when)}</span>${extra.head || ''}</div>${extra.quote || ''}`
    + `<div class="msg-body">${esc(body).replace(/\\n/g, '<br>')}</div></div></div>`;
}

// Highlight a few selected words in the doc, so the thread needn't repeat them.
function markQuote(block, quote) {
  const walker = document.createTreeWalker(block, NodeFilter.SHOW_TEXT, {
    acceptNode: n => n.parentElement.closest('.thread, .add-btn, .resolved-pin') ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT,
  });
  for (let n; (n = walker.nextNode());) {
    const at = n.nodeValue.indexOf(quote);
    if (at < 0) continue;
    const range = document.createRange();
    range.setStart(n, at);
    range.setEnd(n, at + quote.length);
    const mark = document.createElement('mark');
    mark.className = 'cmark';
    range.surroundContents(mark);
    return true;
  }
  return false;
}

function pendingText(c) {
  const last = c.replies[c.replies.length - 1];
  return last && last.author === 'you' ? last.body : c.body;
}

function editDraft(thread, c) {
  const body = thread.querySelector('.msg.pending .msg-body');
  thread.classList.add('editing');
  body.innerHTML = `<textarea></textarea><div style="text-align:right;margin-top:6px">
    <button class="btn cancel">Cancel</button><button class="btn primary save">Save</button></div>`;
  const box = body.querySelector('textarea');
  box.value = pendingText(c);
  box.focus();
  box.setSelectionRange(box.value.length, box.value.length);
  const done = () => { thread.classList.remove('editing'); renderComments(); };
  body.querySelector('.cancel').onclick = done;
  body.querySelector('.save').onclick = async () => {
    if (box.value.trim()) await post('/__comments/edit', { id: c.id, body: box.value.trim() });
    done();
  };
  submitOnEnter(box, () => body.querySelector('.save').click(), done);
}

const openResolved = new Set();
// Each comment's status at the last redraw, so a line can celebrate the moment it's resolved
// (but not on first load, when everything already resolved would flash at once).
let lastStatus = null;

function celebrate(block, pin) {
  for (const [el, cls] of [[block, 'just-resolved'], [pin, 'pop']]) {
    el.classList.remove(cls);
    void el.offsetWidth;  // restart the animation if it's already run
    el.classList.add(cls);
    el.addEventListener('animationend', () => el.classList.remove(cls), { once: true });
  }
}

function placePins() {
  const edge = document.getElementById('doc').getBoundingClientRect().right + 6;
  content.querySelectorAll('.resolved-pin').forEach(pin => {
    const box = pin.parentElement.getBoundingClientRect();
    pin.style.left = (edge - box.left) + 'px';
    if (pin.row) pin.style.top = (pin.row.getBoundingClientRect().top - box.top + 4) + 'px';
  });
}
addEventListener('resize', placePins);

async function renderComments() {
  if (document.querySelector('.thread.editing') || [...document.querySelectorAll('.reply-box textarea')].some(t => t.value))
    return setTimeout(renderComments, 1000);
  const comments = JSON.parse(await fetchText('/__comments?path=' + encodeURIComponent(docPath)));
  content.querySelectorAll('.thread:not(.new)').forEach(removeThread);
  content.querySelectorAll('.resolved-pin, .orphans').forEach(p => p.remove());
  let orphans = null;
  content.querySelectorAll('mark.cmark').forEach(m => m.replaceWith(...m.childNodes));
  content.normalize();
  for (const c of comments) {
    // Its own line if it's still there; else the heading of the section it was in; else the
    // list at the bottom of the doc. A resolved comment on vanished text needs no place.
    let block = findBlock(c);
    let lineGone = false;
    if (!block && c.section) {
      block = [...content.querySelectorAll('h1[data-block], h2[data-block], h3[data-block], h4[data-block], h5[data-block], h6[data-block]')]
        .find(h => blockText(h) === c.section) || null;
      lineGone = !!block;
    }
    if (!block && c.status === 'resolved') continue;
    const thread = document.createElement('div');
    thread.className = 'thread ' + c.status + (lineGone ? ' line-removed' : block ? '' : ' outdated');
    // Whole-line comments sit right under their line; only a picked-out phrase, or text
    // that's since been edited away, needs quoting.
    const partial = block && !lineGone && c.quote !== blockText(block);
    const marked = partial && c.status !== 'resolved' && markQuote(block, c.quote);
    const quote = !block || lineGone || (partial && !marked) ? `<div class="msg-quote">${esc(c.quote)}</div>` : '';
    const action = c.status === 'draft' ? '<button class="link-btn edit">Edit</button><button class="link-btn del">Delete</button>' : '';
    const label = c.status === 'deferred' && c.owner ? `For ${esc(c.owner)}` : STATE[c.status];
    const head = `<span class="state ${c.status}">${label}</span>${action}`;
    const you = user.login || 'You';
    const was = c.original && c.original !== c.quote
      ? `<div class="msg-was" title="Click to show it all"><b>Was:</b> <s>${esc(c.original)}</s></div>` : '';
    thread.innerHTML = [message('you', you, c.created, c.body, { head, quote: was + quote })]
      .concat(c.replies.map(r => r.author === 'you' ? message('you', you, r.created, r.body, {}) : message('claude', 'Claude', r.created, r.body, {})))
      .join('');
    thread.querySelectorAll('.msg.you').forEach((m, i, all) => i === all.length - 1 && c.status === 'draft' && m.classList.add('pending'));
    // Answer Claude, or reopen a resolved thread, from the bottom of the thread.
    if (['replied', 'addressed', 'deferred', 'resolved'].includes(c.status)) {
      const reply = document.createElement('div');
      reply.className = 'reply-box';
      reply.innerHTML = `<textarea rows="1" placeholder="${c.status === 'resolved' ? 'Reply to reopen…' : 'Reply…'}"></textarea>
        <div class="reply-actions"><button class="btn cancel">Cancel</button><button class="btn primary send">Reply</button></div>`;
      const box = reply.querySelector('textarea');
      box.onfocus = () => reply.classList.add('active');
      reply.querySelector('.cancel').onclick = () => { box.value = ''; reply.classList.remove('active'); };
      reply.querySelector('.send').onclick = async () => {
        if (!box.value.trim()) return;
        const text = box.value.trim();
        box.value = '';  // sent, so it no longer holds back a redraw
        await post('/__comments/reply', { id: c.id, body: text });
        openResolved.delete(c.id);
        renderComments();
      };
      submitOnEnter(box, () => reply.querySelector('.send').click(), () => { reply.querySelector('.cancel').click(); box.blur(); });
      thread.append(reply);
    }
    if (c.status !== 'draft' && c.status !== 'resolved') {
      const foot = document.createElement('div');
      foot.className = 'thread-actions';
      foot.innerHTML = `<button class="btn resolve${c.status === 'addressed' ? ' primary' : ''}">Resolve conversation</button>`;
      thread.append(foot);
    }
    thread.querySelector('.msg-was')?.addEventListener('click', e => e.currentTarget.classList.toggle('open'));
    thread.querySelector('.del')?.addEventListener('click', async () => { await post('/__comments/delete', { id: c.id }); renderComments(); });
    thread.querySelector('.edit')?.addEventListener('click', () => editDraft(thread, c));
    if (c.status === 'draft') {
      const text = thread.querySelector('.msg.pending .msg-body');
      text.title = 'Click to edit';
      text.onclick = () => thread.classList.contains('editing') || editDraft(thread, c);
    }
    thread.querySelector('.resolve')?.addEventListener('click', async () => { await post('/__comments/resolve', { id: c.id }); renderComments(); });
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
    if (c.status !== 'resolved') block.closest('details')?.setAttribute('open', '');
    if (block.matches('tr')) placePins();
    if (c.status !== 'resolved') continue;
    // Resolved: out of the reading flow, behind a faint tick in the right margin.
    const holder = block.matches('tr') ? tableBox(block) : block;
    let pin = [...holder.querySelectorAll(':scope > .resolved-pin')].find(p => p.row === (block.matches('tr') ? block : undefined));
    if (!pin) {
      pin = document.createElement('button');
      pin.className = 'resolved-pin';
      pin.title = 'Resolved comments';
      pin.dataset.count = '0';
      pin.onclick = e => {
        e.stopPropagation();
        const on = pin.classList.toggle('on');
        pin.threads.forEach(t => t.classList.toggle('open', on));
        pin.ids.forEach(id => on ? openResolved.add(id) : openResolved.delete(id));
        layoutRowThreads();
      };
      pin.ids = [];
      pin.threads = [];
      if (block.matches('tr')) pin.row = block;
      holder.append(pin);
    }
    pin.threads.push(thread);
    pin.ids.push(c.id);
    if (openResolved.has(c.id)) { thread.classList.add('open'); pin.classList.add('on'); }
    if (lastStatus && lastStatus[c.id] && lastStatus[c.id] !== 'resolved') celebrate(block, pin);
    pin.dataset.count = String(+pin.dataset.count + 1);
    pin.innerHTML = TICK + (+pin.dataset.count > 1 ? pin.dataset.count : '');
  }
  placePins();
  lastStatus = Object.fromEntries(comments.map(c => [c.id, c.status]));
  const open = comments.filter(c => c.status !== 'resolved').length;
  const toCheck = comments.filter(c => c.status === 'addressed').length;
  document.getElementById('count').textContent = !open ? ''
    : `${open} open comment${open > 1 ? 's' : ''}` + (toCheck ? ` · ${toCheck} to check` : '');
  const drafts = JSON.parse(await fetchText('/__comments?drafts=1')).length;
  const bar = document.getElementById('sendbar');
  if (drafts) {
    document.getElementById('sendnote').textContent = `${drafts} pending comment${drafts > 1 ? 's' : ''}`;
    document.getElementById('sendbtn').style.display = '';
    bar.classList.add('show');
  } else if (!bar.dataset.sent) {
    bar.classList.remove('show');
  }
}

document.getElementById('sendbtn').onclick = async () => {
  await post('/__comments/send', {});
  const bar = document.getElementById('sendbar');
  bar.dataset.sent = '1';
  const listening = (await fetchText('/__listening')) === '1';
  document.getElementById('sendnote').textContent = listening
    ? 'Sent. Claude is picking them up.' : 'Sent. Tell Claude: "go through my comments".';
  document.getElementById('sendbtn').style.display = 'none';
  setTimeout(() => { delete bar.dataset.sent; bar.classList.remove('show'); }, 8000);
  renderComments();
};

async function load() {
  // Don't wipe a comment someone is halfway through writing.
  if (document.querySelector('.thread.new textarea')?.value || document.querySelector('.thread.editing')) return setTimeout(load, 1000);
  showStatus('Rendering…', 'busy');
  try {
    const y = scrollY;
    document.getElementById('files').innerHTML = await fetchText('/__list?path=' + encodeURIComponent(folderPath)
      + '&current=' + encodeURIComponent(isFolder ? 'README.md' : pagePath.slice(folderPath.length))
      + (scoped ? '&home=' + encodeURIComponent(home) : ''));
    const res = await fetch('/__render?path=' + encodeURIComponent(docPath));
    const box = document.getElementById('doc');
    if (res.status === 404 && isFolder) {
      box.hidden = true;  // a folder without a README shows just its file list
    } else {
      const text = await res.text();
      if (!res.ok) throw new Error(text);
      content.innerHTML = text;
      box.hidden = false;
      enhance();
      if (canComment) {
        markBlocks();
        await renderComments();
      }
    }
    scrollTo(0, y);
    showStatus('');
    if (location.hash && renderCount === 1) document.getElementById(location.hash.slice(1))?.scrollIntoView();
  } catch (e) {
    showStatus(e.message, 'error');
  }
}

let seen = null;
async function poll() {
  try {
    const now = JSON.parse(await fetchText('/__changes?path=' + encodeURIComponent(pagePath)));
    if (now.navigate) return location.assign(now.navigate);
    if (status.className === 'error' && status.textContent === 'Preview server stopped') showStatus('');
    if (!seen || now.doc !== seen.doc) { seen = now; await load(); }
    else if (now.comments !== seen.comments) { seen = now; await refreshComments(); }
  } catch {
    showStatus('Preview server stopped', 'error');
  }
  setTimeout(poll, 400);
}
poll();

// Redraw threads and the file list's comment counts without touching the doc itself.
async function refreshComments() {
  if (!canComment || content.hidden || !content.innerHTML) return;
  document.getElementById('files').innerHTML = await fetchText('/__list?path=' + encodeURIComponent(folderPath)
    + '&current=' + encodeURIComponent(isFolder ? 'README.md' : pagePath.slice(folderPath.length))
      + (scoped ? '&home=' + encodeURIComponent(home) : ''));
  await renderComments();
}
events.onerror = () => showStatus('Preview server stopped', 'error');
</script>
</body>
</html>
"""


class Renderer:
    """Renders Markdown via GitHub, caching by content hash."""

    def __init__(self, context):
        self.context = context
        self.cache = {}
        self.lock = threading.Lock()
        token = subprocess.run(["gh", "auth", "token"], capture_output=True, text=True)
        self.token = token.stdout.strip() if token.returncode == 0 else None
        self.conn = None

    def render(self, text):
        key = hashlib.sha256(text.encode()).hexdigest()
        with self.lock:
            if key in self.cache:
                return self.cache[key]
            body = {"text": text, "mode": "gfm"}
            if self.context:
                body["context"] = self.context
            html_out = self.post(body) if self.token else self.post_with_gh(body)
            if len(self.cache) > 50:
                self.cache.clear()
            self.cache[key] = html_out
            return html_out

    def post(self, body):
        headers = {"Authorization": f"Bearer {self.token}", "Accept": "application/vnd.github+json",
                   "Content-Type": "application/json", "User-Agent": "umbraco-devkit-markdown-preview"}
        for attempt in (1, 2):  # a kept-open connection may have been closed by GitHub
            try:
                if self.conn is None:
                    self.conn = http.client.HTTPSConnection("api.github.com", timeout=20)
                self.conn.request("POST", "/markdown", json.dumps(body), headers)
                res = self.conn.getresponse()
                data = res.read().decode()
            except (OSError, http.client.HTTPException):
                self.conn = None
                if attempt == 2:
                    raise RuntimeError("Can't reach GitHub")
                continue
            if res.status != 200:
                raise RuntimeError(f"GitHub said {res.status}: {data[:200]}")
            return data

    @staticmethod
    def post_with_gh(body):
        result = subprocess.run(
            ["gh", "api", "-X", "POST", "/markdown", "--input", "-"],
            input=json.dumps(body), capture_output=True, text=True,
        )
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip() or "GitHub render failed")
        return result.stdout


def repo_context(directory):
    result = subprocess.run(
        ["gh", "repo", "view", "--json", "nameWithOwner", "-q", ".nameWithOwner"],
        cwd=directory, capture_output=True, text=True,
    )
    return result.stdout.strip() if result.returncode == 0 else None


def github_user():
    """The signed-in GitHub login, so comments show the reviewer's own name and avatar."""
    result = subprocess.run(["gh", "api", "user", "-q", ".login"], capture_output=True, text=True)
    return {"login": result.stdout.strip()} if result.returncode == 0 else {}


def find_git(start):
    """The worktree holding `start` and its git folder, found by walking up for `.git` rather
    than running git, so it also works where git can't run. (None, None) outside a repo."""
    d = os.path.realpath(start)
    while True:
        dot = os.path.join(d, ".git")
        if os.path.isdir(dot):
            return d, dot
        if os.path.isfile(dot):  # a linked worktree: `.git` is a file naming its git folder
            with open(dot) as f:
                line = f.read().strip()
            if line.startswith("gitdir:"):
                return d, os.path.realpath(os.path.join(d, line[len("gitdir:"):].strip()))
        parent = os.path.dirname(d)
        if parent == d:
            return None, None
        d = parent


def git_root(directory):
    return find_git(directory)[0]


def breadcrumbs(root, url_path):
    """GitHub-style path trail: each parent folder links to its folder view."""
    parts = [p for p in url_path.strip("/").split("/") if p]
    trail = [(os.path.basename(root), "/")]
    for i, part in enumerate(parts):
        href = "/" + "/".join(parts[:i + 1])
        is_last = i == len(parts) - 1
        trail.append((part, href if is_last and not url_path.endswith("/") else href + "/"))
    items = [f'<a href="{html.escape(urllib.parse.quote(href))}" data-path="{html.escape(href)}">{html.escape(name)}</a>'
             for name, href in trail[:-1]]
    items.append(f'<span class="here" data-path="{html.escape(trail[-1][1])}">{html.escape(trail[-1][0])}</span>')
    return '<span class="sep">/</span>'.join(items)


def reading_order(folder):
    """Files the folder's README links to, in the order it lists them. A plan folder's README
    is its read-order index, so its files list brief first, then design, then plan."""
    try:
        with open(os.path.join(folder, "README.md"), encoding="utf-8") as f:
            text = f.read()
    except OSError:
        return []
    order = []
    for target in re.findall(r"\]\(\s*<?(?:\./)?([^)#?\s>/]+)", text):
        name = urllib.parse.unquote(target)
        if name not in order and os.path.isfile(os.path.join(folder, name)):
            order.append(name)
    return order


def folder_listing(folder, url_path, current, counts, home="/"):
    entries = [e for e in os.scandir(folder) if not e.name.startswith(".")]
    order = reading_order(folder)
    # Folders first, as on GitHub; then the files in the README's reading order; then the rest.
    entries.sort(key=lambda e: (not e.is_dir(), e.name not in order,
                                order.index(e.name) if e.name in order else 0, e.name.lower()))
    rows = []
    if url_path not in ("/", home):
        rows.append(f'<a href="{urllib.parse.quote(url_path)}..">{ICON_DIR}..</a>')
    for e in entries:
        href = urllib.parse.quote(url_path + e.name) + ("/" if e.is_dir() else "")
        cls = ' class="current"' if e.name == current else ""
        count = counts.get(url_path + e.name)
        dot = f'<span class="dot" title="Open comments">{count}</span>' if count else ""
        rows.append(f'<a href="{href}"{cls}>{ICON_DIR if e.is_dir() else ICON_FILE}{html.escape(e.name)}{dot}</a>')
    return f'<div class="box files">{"".join(rows)}</div>'


def change_marker(path):
    """Something that changes whenever the page for `path` needs a refresh."""
    try:
        folder, doc = (path, os.path.join(path, "README.md")) if os.path.isdir(path) else (os.path.dirname(path), path)
        names = tuple(sorted(e.name for e in os.scandir(folder)))
        return (names, os.stat(doc).st_mtime_ns if os.path.isfile(doc) else None)
    except FileNotFoundError:
        return None  # editors sometimes delete and rewrite on save


class Comments:
    """Review comments for one worktree, kept outside the repo so they never get committed.

    A comment is a draft until the reviewer sends the batch, then `sent` until it's resolved.
    It's pinned by the text it quotes (plus a little either side), since GitHub's HTML carries
    no source line numbers.
    """

    def __init__(self, path):
        self.path = path
        self.lock = threading.Lock()

    def mtime(self):
        return os.stat(self.path).st_mtime_ns if os.path.exists(self.path) else None

    def load(self):
        try:
            with open(self.path) as f:
                return json.load(f)
        except (FileNotFoundError, ValueError):
            return []

    def save(self, items):
        os.makedirs(os.path.dirname(self.path), exist_ok=True)
        tmp = self.path + ".tmp"
        with open(tmp, "w") as f:
            json.dump(items, f, indent=1)
        os.replace(tmp, self.path)

    def change(self, fn):
        with self.lock:
            items = self.load()
            result = fn(items)
            self.save(items)
            return result

    def add(self, path, quote, prefix, suffix, section, body):
        def add(items):
            item = {"id": f"c{max([int(c['id'][1:]) for c in items] + [0]) + 1}", "path": path,
                    "quote": quote, "prefix": prefix, "suffix": suffix, "section": section, "body": body,
                    "status": "draft", "replies": [], "created": time.strftime("%Y-%m-%dT%H:%M:%S")}
            items.append(item)
            return item
        return self.change(add)

    def update(self, comment_id, fn):
        def update(items):
            for c in items:
                if c["id"] == comment_id:
                    fn(c)
                    return c
            raise KeyError(comment_id)
        return self.change(update)

    def delete(self, comment_id):
        self.change(lambda items: items.__setitem__(slice(None), [c for c in items if c["id"] != comment_id]))

    def send_drafts(self):
        def send(items):
            for c in items:
                if c["status"] == "draft":
                    c["status"] = "sent"
        self.change(send)


def state_paths(root):
    """Where this worktree's server details, comments and waiting helper are kept. Comments go
    in the worktree's git folder: never committed, kept across restarts, and removed with the
    worktree. The rest only matters while running, so it goes in the temp folder."""
    key = hashlib.sha1(root.encode()).hexdigest()[:16]
    git_dir = find_git(root)[1]
    comments = (os.path.join(git_dir, "markdown-preview", "comments.json") if git_dir
                else os.path.join(STATE_DIR, key + "-comments.json"))
    return os.path.join(STATE_DIR, key + ".json"), comments, os.path.join(STATE_DIR, key + "-waiter.pid")


class Tabs:
    """Whether a preview tab is open (they check in every 0.4s), and where to send it next."""

    def __init__(self):
        self.seen = 0.0
        self.go_to = None

    def open(self, url_path):
        """Point the open tab at url_path; False if no tab has checked in lately."""
        if time.time() - self.seen > 2:
            return False
        self.go_to = "/" + url_path
        return True


def make_handler(root, css, renderer, comments, user, waiter_file, tabs):
    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *args):
            pass

        def resolve(self, url_path):
            """Map a URL path to a file or folder under root, refusing anything outside it."""
            rel = urllib.parse.unquote(url_path).lstrip("/")
            full = os.path.realpath(os.path.join(root, rel))
            if full != root and not full.startswith(root + os.sep):
                return None
            return full if os.path.exists(full) else None

        def send(self, status, body, content_type="text/html; charset=utf-8"):
            data = body.encode() if isinstance(body, str) else body
            self.send_response(status)
            self.send_header("Content-Type", content_type)
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            self.wfile.write(data)

        def page(self, url_path, docname):
            body = (PAGE.replace("__CSS__", css)
                        .replace("__TITLE__", html.escape(urllib.parse.unquote(url_path)))
                        .replace("__CRUMBS__", breadcrumbs(root, urllib.parse.unquote(url_path)))
                        .replace("__DOCNAME__", html.escape(docname))
                        .replace("__PATH__", json.dumps(url_path))
                        .replace("__USER__", json.dumps(user)))
            self.send(200, body)

        def do_GET(self):
            url = urllib.parse.urlparse(self.path)
            query = urllib.parse.parse_qs(url.query)

            if url.path == "/__ping":
                return self.send(200, root, "text/plain")
            if url.path == "/__listening":
                return self.send(200, "1" if helper_running(waiter_file) else "0", "text/plain")
            if url.path == "/__comments":
                items = comments.load()
                if "drafts" in query:
                    items = [c for c in items if c["status"] == "draft"]
                else:
                    items = [c for c in items if c["path"] == query.get("path", [""])[0]]
                return self.send(200, json.dumps(items), "application/json")
            if url.path in ("/__render", "/__changes", "/__list"):
                target = self.resolve(query.get("path", [""])[0])
                if not target:
                    return self.send(404, "Not found", "text/plain")
                if url.path == "/__render":
                    return self.render(target)
                if url.path == "/__list":
                    current = query.get("current", [""])[0]
                    counts = {}
                    for c in comments.load():
                        if c["status"] != "resolved":
                            counts[c["path"]] = counts.get(c["path"], 0) + 1
                    home = query.get("home", ["/"])[0]
                    return self.send(200, folder_listing(target, query["path"][0], current, counts, home))
                marks = {"doc": repr(change_marker(target)), "comments": repr(comments.mtime())}
                tabs.seen = time.time()
                if tabs.go_to:
                    marks["navigate"], tabs.go_to = tabs.go_to, None
                return self.send(200, json.dumps(marks), "application/json")

            target = self.resolve(url.path)
            if not target:
                return self.send(404, "Not found", "text/plain")
            if os.path.isdir(target):
                if not url.path.endswith("/"):
                    self.send_response(301)
                    self.send_header("Location", url.path + "/")
                    self.end_headers()
                    return
                return self.page(url.path, "README.md")
            if target.endswith(".md"):
                return self.page(url.path, os.path.basename(target))
            with open(target, "rb") as f:
                self.send(200, f.read(), mimetypes.guess_type(target)[0] or "application/octet-stream")

        def do_POST(self):
            url = urllib.parse.urlparse(self.path)
            length = int(self.headers.get("Content-Length") or 0)
            try:
                data = json.loads(self.rfile.read(length) or b"{}")
                if url.path == "/__open":
                    return self.send(200, "reused" if tabs.open(data["path"]) else "none", "text/plain")
                if url.path == "/__comments":
                    if not self.resolve(data["path"]):
                        return self.send(404, "Not found", "text/plain")
                    comments.add(data["path"], data["quote"], data.get("prefix", ""), data.get("suffix", ""),
                                 data.get("section", ""), data["body"])
                elif url.path == "/__comments/send":
                    comments.send_drafts()
                elif url.path == "/__comments/resolve":
                    comments.update(data["id"], lambda c: c.update(status="resolved"))
                elif url.path == "/__comments/edit":
                    def edit(c):
                        if c["status"] != "draft":
                            raise ValueError("only a pending comment can be edited")
                        if c["replies"] and c["replies"][-1]["author"] == "you":
                            c["replies"][-1]["body"] = data["body"]
                        else:
                            c["body"] = data["body"]
                    comments.update(data["id"], edit)
                elif url.path == "/__comments/reply":
                    # Replying reopens the thread; the reply goes out with the next batch.
                    def reply(c):
                        c["replies"].append({"author": "you", "body": data["body"], "created": time.strftime("%Y-%m-%dT%H:%M:%S")})
                        c["status"] = "draft"
                    comments.update(data["id"], reply)
                elif url.path == "/__comments/delete":
                    # A pending reply is withdrawn on its own; the thread before it stays.
                    item = next((c for c in comments.load() if c["id"] == data["id"]), None)
                    if item and item["replies"] and item["replies"][-1]["author"] == "you":
                        def withdraw(c):
                            c["replies"].pop()
                            c["status"] = "replied"
                        comments.update(data["id"], withdraw)
                    else:
                        comments.delete(data["id"])
                else:
                    return self.send(404, "Not found", "text/plain")
            except (KeyError, ValueError) as e:
                return self.send(400, f"Bad request: {e}", "text/plain")
            self.send(200, "ok", "text/plain")

        def render(self, doc):
            if not os.path.isfile(doc):
                return self.send(404, "Not found", "text/plain")
            try:
                with open(doc, encoding="utf-8") as f:
                    self.send(200, renderer.render(f.read()))
            except Exception as e:
                self.send(502, str(e), "text/plain")

    return Handler


def comments_cli(argv):
    """`wait` blocks until the reviewer sends a batch, then prints it and exits, so a background
    run of it wakes Claude. `comments` lists what's waiting; `reply` answers one."""
    parser = argparse.ArgumentParser(prog="preview.py wait|comments|reply")
    parser.add_argument("command", choices=["wait", "comments", "reply"])
    parser.add_argument("id", nargs="?")
    parser.add_argument("text", nargs="?")
    # No --resolve: only the reader resolves. --done hands it back to them to check.
    outcome = parser.add_mutually_exclusive_group()
    outcome.add_argument("--done", action="store_true", help="dealt with; the reader checks and resolves it")
    outcome.add_argument("--defer", metavar="STEP", help="another step owns the file; leave it for STEP")
    parser.add_argument("--move", metavar="TEXT", help="re-pin the comment to TEXT, which replaced what it was on")
    parser.add_argument("--file", action="append", help="comments: open comments on this file instead")
    parser.add_argument("--root", help="worktree (default: the one holding the current folder)")
    args = parser.parse_args(argv)
    root = os.path.realpath(args.root or git_root(os.getcwd()) or os.getcwd())
    store = Comments(state_paths(root)[1])

    if args.command == "wait":
        waiter = state_paths(root)[2]
        if helper_running(waiter):
            print("Already waiting for comments on this worktree; nothing more to do.")
            return
        os.makedirs(STATE_DIR, exist_ok=True)
        with open(waiter, "w") as f:
            f.write(str(os.getpid()))
        atexit.register(lambda: os.path.exists(waiter) and os.remove(waiter))
        signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))

        def claim(items):
            batch = [c for c in items if c["status"] == "sent"]
            for c in batch:
                c["status"] = "working"
            return batch
        while not any(c["status"] == "sent" for c in store.load()):
            time.sleep(1)
        batch = store.change(claim)
        print(f"The reviewer sent {len(batch)} comment{'s' if len(batch) > 1 else ''}:")
        print_comments(batch)
        return

    if args.command == "comments":
        if args.file:
            # Everything still open on these files, whoever it's waiting on; drafts aren't sent yet.
            wanted = {"/" + os.path.relpath(os.path.realpath(f), root).replace(os.sep, "/") for f in args.file}
            items = [c for c in store.load() if c["path"] in wanted and c["status"] not in ("draft", "resolved")]
        else:
            items = [c for c in store.load() if c["status"] in ("sent", "working")]
        if not items:
            print("No open comments." if args.file else "No comments waiting.")
        print_comments(items)
        return
    if not (args.id and args.text):
        sys.exit("Usage: preview.py reply <id> <text> [--done | --defer STEP] [--move TEXT]")

    def reply(c):
        c["replies"].append({"author": "claude", "body": args.text, "created": time.strftime("%Y-%m-%dT%H:%M:%S")})
        c["status"] = "addressed" if args.done else "deferred" if args.defer else "replied"
        c["owner"] = args.defer
        if args.move:
            c.setdefault("original", c["quote"])  # what the reader actually commented on
            c["quote"], c["prefix"], c["suffix"] = args.move, "", ""
    store.update(args.id, reply)
    outcome = " and marked it done" if args.done else f" and left it for {args.defer}" if args.defer else ""
    print(f"Replied to {args.id}{outcome}" + (" (moved to its new text)" if args.move else ""))


def helper_running(waiter_file):
    try:
        with open(waiter_file) as f:
            os.kill(int(f.read()), 0)
        return True
    except (OSError, ValueError):
        return False


# How each status reads to Claude in a listing: whose move it is.
STATUS_NOTE = {
    "sent": "new, for you", "working": "new, for you", "deferred": "left for {owner}",
    "replied": "waiting on the reader's answer", "addressed": "done, waiting on the reader's check",
}


def print_comments(items):
    for c in items:
        print(f"[{c['id']}] {c['path'].lstrip('/')} ({STATUS_NOTE[c['status']].format(owner=c.get('owner'))})")
        print(f"  on: \"{c['quote']}\"")
        if c.get("original"):
            print(f"  originally on: \"{c['original']}\"")
        if c.get("section"):
            print(f"  in section: {c['section']}")
        print(f"  context: ...{c['prefix']}[{c['quote']}]{c['suffix']}...")
        print(f"  says: {c['body']}")
        for r in c["replies"]:
            print(f"  {'Reviewer' if r['author'] == 'you' else 'Claude'} replied: {r['body']}")


def main():
    if len(sys.argv) > 1 and sys.argv[1] in ("wait", "comments", "reply"):
        return comments_cli(sys.argv[1:])
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("path", help="Markdown file or folder to open")
    parser.add_argument("--root", help="folder to serve (default: the git worktree, else the file's folder)")
    parser.add_argument("--port", type=int, default=0, help="port to use (default: any free port)")
    parser.add_argument("--no-open", action="store_true", help="don't open the browser")
    parser.add_argument("--scope", nargs="?", const="", metavar="DIR",
                        help="keep navigation and comments inside DIR (default: the opened folder, or the file's folder)")
    parser.add_argument("--no-comments", action="store_true", help="open read-only, with no review comments")
    args = parser.parse_args()

    target = os.path.realpath(args.path)
    if not os.path.exists(target):
        sys.exit(f"Not found: {args.path}")
    start_dir = target if os.path.isdir(target) else os.path.dirname(target)
    root = os.path.realpath(args.root or git_root(start_dir) or start_dir)
    if target != root and not target.startswith(root + os.sep):
        sys.exit(f"{args.path} is not inside {root}")

    rel = os.path.relpath(target, root)
    url_path = "" if rel == "." else urllib.parse.quote(rel) + ("/" if os.path.isdir(target) else "")
    params = {}
    if args.scope is not None:
        scope = os.path.realpath(args.scope) if args.scope else start_dir
        if scope != root and not scope.startswith(root + os.sep):
            sys.exit(f"{args.scope} is not inside {root}")
        home = "/" + os.path.relpath(scope, root).replace(os.sep, "/") + "/"
        params["home"] = "/" if home == "/./" else home
    if args.no_comments:
        params["comments"] = "off"
    if params:
        url_path += "?" + urllib.parse.urlencode(params)

    state_file, comments_file, waiter_file = state_paths(root)
    port = running_port(state_file, root)
    if port:
        url = f"http://127.0.0.1:{port}/{url_path}"
        if not args.no_open:
            req = urllib.request.Request(f"http://127.0.0.1:{port}/__open", json.dumps({"path": url_path}).encode(), method="POST")
            with urllib.request.urlopen(req, timeout=2) as res:
                reused = res.read().decode() == "reused"
            if not reused:
                webbrowser.open(url)
            print(f"Preview already running for {root}; {'showing it in the open tab' if reused else 'opened'} {url}", flush=True)
        return

    with urllib.request.urlopen(CSS_URL) as res:
        css = res.read().decode()
    renderer = Renderer(repo_context(start_dir))

    tabs = Tabs()
    server = ThreadingHTTPServer(("127.0.0.1", args.port), make_handler(root, css, renderer, Comments(comments_file), github_user(), waiter_file, tabs))
    server.daemon_threads = True
    port = server.server_address[1]
    os.makedirs(STATE_DIR, exist_ok=True)
    with open(state_file, "w") as f:
        json.dump({"root": root, "port": port, "pid": os.getpid()}, f)
    atexit.register(lambda: os.path.exists(state_file) and os.remove(state_file))
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))  # so atexit still runs when killed
    threading.Thread(target=stop_when_gone, args=(server, root), daemon=True).start()

    url = f"http://127.0.0.1:{port}/{url_path}"
    print(f"Previewing {url}", flush=True)

    def show():
        time.sleep(1.5)
        if not tabs.open(url_path):
            webbrowser.open(url)
    if not args.no_open:
        threading.Thread(target=show, daemon=True).start()
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass


def running_port(state_file, root):
    """The port of a live server already previewing this root, or None."""
    try:
        with open(state_file) as f:
            state = json.load(f)
        os.kill(state["pid"], 0)
        with urllib.request.urlopen(f"http://127.0.0.1:{state['port']}/__ping", timeout=1) as res:
            return state["port"] if res.read().decode() == root else None
    except (OSError, ValueError, KeyError):
        return None


def stop_when_gone(server, root):
    """A removed worktree has nothing left to preview, so shut down with it."""
    while os.path.isdir(root):
        time.sleep(2)
    server.shutdown()


if __name__ == "__main__":
    main()
