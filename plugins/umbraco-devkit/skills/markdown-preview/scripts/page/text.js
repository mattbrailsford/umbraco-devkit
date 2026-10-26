// A block's own text, and marking or adding to it, across whatever formatting it has (bold, a
// link, code). Comment highlights and change marks both work through these.

// The text nodes a block shows as its own: not a thread, a button, or a list item's nested list.
function ownTextNodes(block) {
  const nested = block.matches('li') ? [...block.querySelectorAll(':scope > ul, :scope > ol')] : [];
  const walker = document.createTreeWalker(block, NodeFilter.SHOW_TEXT, {
    acceptNode: n => n.parentElement.closest('.thread, .add-btn, .resolved-pin, del.ch-del') || nested.some(l => l.contains(n))
      ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT,
  });
  const nodes = [];
  for (let n; (n = walker.nextNode());) nodes.push(n);
  return nodes;
}

export const ownText = block => ownTextNodes(block).map(n => n.nodeValue).join('');

// Wrap stretches of a block's own text ([start, end) in ownText) in marks, even where a
// stretch runs across bold, a link or code.
export function wrapText(block, ranges, className) {
  const cuts = [];
  let offset = 0;
  for (const n of ownTextNodes(block)) {
    const len = n.nodeValue.length;
    for (const [a, b] of ranges) {
      const from = Math.max(a, offset), to = Math.min(b, offset + len);
      if (from < to) cuts.push([n, from - offset, to - offset]);
    }
    offset += len;
  }
  // Last first, so splitting a text node leaves the earlier offsets in it as they were.
  for (const [n, from, to] of cuts.reverse()) {
    const range = document.createRange();
    range.setStart(n, from);
    range.setEnd(n, to);
    const mark = document.createElement('mark');
    mark.className = className;
    range.surroundContents(mark);
  }
  return cuts.length > 0;
}

// Put nodes (or text) into a block's own text at an offset in ownText.
export function insertText(block, offset, nodes) {
  let at = 0;
  for (const n of ownTextNodes(block)) {
    if (offset <= at + n.nodeValue.length) {
      n.splitText(offset - at).before(...nodes);
      return;
    }
    at += n.nodeValue.length;
  }
  block.append(...nodes);
}
