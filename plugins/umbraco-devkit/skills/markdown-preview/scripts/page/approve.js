// Approving a doc, as a PR is approved on GitHub: a button in the doc's header when the step
// that owns the doc has asked for it, once the doc's comments are all resolved. Only the
// reader can approve; Claude hears once every doc asked for is done.
import { $, ago, esc, fetchText, page, post } from './state.js';

const TICK = '<svg viewBox="0 0 16 16" width="16" height="16"><path fill="currentColor" d="M8 16A8 8 0 1 1 8 0a8 8 0 0 1 0 16Zm3.78-9.72a.751.751 0 0 0-.018-1.042.751.751 0 0 0-1.042-.018L6.75 9.19 5.28 7.72a.751.751 0 0 0-1.042.018.751.751 0 0 0-.018 1.042l2 2a.75.75 0 0 0 1.06 0Z"/></svg>';

export async function renderApproval() {
  const slot = $('approval');
  if (!page.canComment) return slot.replaceChildren();
  let s;
  try {
    s = JSON.parse(await fetchText('/__approve?path=' + encodeURIComponent(page.docPath)));
  } catch { return slot.replaceChildren(); }
  if (!s.state) return slot.replaceChildren();
  if (s.state === 'approved')
    return slot.innerHTML = `<span class="ap-done" title="Approved by you ${esc(ago(s.at))}">${TICK}Approved</span>`;
  const again = s.state === 'changed';
  const blocked = s.open > 0;
  const title = blocked ? `Resolve the ${s.open} open comment${s.open > 1 ? 's' : ''} first`
    : again ? 'Changed since you approved it (⌘⇧Enter)' : 'Approve this doc, so the next step can start (⌘⇧Enter)';
  slot.innerHTML = `<button class="ap-btn${again ? ' again' : ''}" title="${esc(title)}"${blocked ? ' disabled' : ''}>`
    + `${again ? 'Approve again' : 'Approve'}</button>`;
  slot.querySelector('button').onclick = approve;
}

// ⌘⇧Enter, as GitHub's submit-review key: only when the button's there and usable.
export async function approve() {
  const btn = $('approval').querySelector('.ap-btn');
  if (!btn || btn.disabled) return;
  await post('/__approve', { path: page.docPath });
  renderApproval();
}
