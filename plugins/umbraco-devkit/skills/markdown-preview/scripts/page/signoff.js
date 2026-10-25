// Signing off a doc, as a PR is approved on GitHub: a button in the doc's header when the step
// that owns the doc has asked for it, once the doc's comments are all resolved. Only the
// reader can sign off; Claude hears once every doc asked for is done.
import { $, ago, esc, fetchText, page, post } from './state.js';

const TICK = '<svg viewBox="0 0 16 16" width="16" height="16"><path fill="currentColor" d="M8 16A8 8 0 1 1 8 0a8 8 0 0 1 0 16Zm3.78-9.72a.751.751 0 0 0-.018-1.042.751.751 0 0 0-1.042-.018L6.75 9.19 5.28 7.72a.751.751 0 0 0-1.042.018.751.751 0 0 0-.018 1.042l2 2a.75.75 0 0 0 1.06 0Z"/></svg>';

export async function renderSignOff() {
  const slot = $('signoff');
  if (!page.canComment) return slot.replaceChildren();
  let s;
  try {
    s = JSON.parse(await fetchText('/__signoff?path=' + encodeURIComponent(page.docPath)));
  } catch { return slot.replaceChildren(); }
  if (!s.state) return slot.replaceChildren();
  if (s.state === 'signed')
    return slot.innerHTML = `<span class="so-done" title="Signed off by you ${esc(ago(s.at))}">${TICK}Signed off</span>`;
  const again = s.state === 'changed';
  const blocked = s.open > 0;
  const title = blocked ? `Resolve the ${s.open} open comment${s.open > 1 ? 's' : ''} first`
    : again ? 'Changed since you signed it off' : 'Approve this doc, so the next step can start';
  slot.innerHTML = `<button class="so-btn${again ? ' again' : ''}" title="${esc(title)}"${blocked ? ' disabled' : ''}>`
    + `${again ? 'Sign off again' : 'Sign off'}</button>`;
  slot.querySelector('button').onclick = async () => {
    await post('/__signoff', { path: page.docPath });
    renderSignOff();
  };
}
