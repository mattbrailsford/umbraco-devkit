// Comparing two versions, with no page involved, so it can be tested on its own: blocks by
// their text, and an edited block's words.

// Longest common run between two lists: what's left over was removed or added. On a tie the
// remove comes first, so an edited block reads old, then new.
export function diff(a, b) {
  const n = a.length, m = b.length;
  const lcs = Array.from({ length: n + 1 }, () => new Uint16Array(m + 1));
  for (let i = n - 1; i >= 0; i--)
    for (let j = m - 1; j >= 0; j--)
      lcs[i][j] = a[i] === b[j] ? lcs[i + 1][j + 1] + 1 : Math.max(lcs[i + 1][j], lcs[i][j + 1]);
  const ops = [];
  let i = 0, j = 0;
  while (i < n || j < m) {
    if (i < n && j < m && a[i] === b[j]) { ops.push(['same', i++, j++]); continue; }
    if (j < m && (i === n || lcs[i][j + 1] > lcs[i + 1][j])) ops.push(['add', null, j++]);
    else ops.push(['remove', i++, null]);
  }
  return ops;
}

// Words and punctuation are separate pieces, so "h." and "h," still match on the "h". A
// word keeps its apostrophes and hyphens ("can't", "load-balanced").
const PIECE = /[\p{L}\p{N}_'’-]+|[^\s\p{L}\p{N}_'’-]+/gu;

export const pieces = text => [...text.matchAll(PIECE)].map(m => [m[0], m.index, m.index + m[0].length]);

// What changed between two versions of a block's text, as a list of changes, each with the
// stretch of old text it replaced and the new text that replaced it ([start, end), or null
// when nothing was removed or added). A change that only removed text also says where to put
// it back to show it in the new text: `put`, the old text with the spacing it had, goes in at
// `at` in the new text.
//
// A match of a piece or two stranded between two changes is folded into them, as diff tools'
// semantic clean-up does, so an edit reads as one swap rather than flicking between changed
// and unchanged ("then 2 h." -> "2 h, then 6 h." marks "then" and ", then 6 h").
export function wordChanges(oldText, newText) {
  const a = pieces(oldText), b = pieces(newText);
  const segs = [];
  for (const [kind, i, j] of diff(a.map(p => p[0]), b.map(p => p[0]))) {
    const type = kind === 'same' ? 'same' : 'change';
    if (segs.at(-1)?.type !== type) segs.push({ type, a: [], b: [] });
    if (i !== null) segs.at(-1).a.push(i);
    if (j !== null) segs.at(-1).b.push(j);
  }
  const size = seg => seg.a.length + seg.b.length;
  for (let k = 1; k < segs.length - 1; k++) {
    const [before, same, after] = [segs[k - 1], segs[k], segs[k + 1]];
    const n = same.a.length;
    if (same.type !== 'same' || before.type !== 'change' || after.type !== 'change' || n > 2 || n > size(before) || n > size(after)) continue;
    before.a.push(...same.a, ...after.a);
    before.b.push(...same.b, ...after.b);
    segs.splice(k, 2);
    k = Math.max(0, k - 2);
  }
  const span = (list, idx) => idx.length ? [list[idx[0]][1], list[idx.at(-1)][2]] : null;
  return segs.flatMap((seg, k) => {
    if (seg.type !== 'change') return [];
    const old = span(a, seg.a), change = { old, new: span(b, seg.b) };
    if (old && !change.new) {
      // After the piece before it, with the space that came before it in the old text; at the
      // very start, with the space that came after it.
      const prevA = segs[k - 1]?.a.at(-1), nextA = segs[k + 1]?.a[0], prevB = segs[k - 1]?.b.at(-1);
      change.put = prevA !== undefined ? [a[prevA][2], old[1]] : [old[0], nextA !== undefined ? a[nextA][1] : old[1]];
      change.at = prevB !== undefined ? b[prevB][2] : 0;
    }
    return [change];
  });
}
