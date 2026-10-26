// The "Send to Claude" bar: how many comments are waiting to go, and sending them in one batch.
import { $, fetchText, post } from './state.js';
import { renderComments } from './threads.js';

export async function updateSendBar() {
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
