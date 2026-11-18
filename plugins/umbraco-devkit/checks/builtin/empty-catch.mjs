// A catch block with nothing in it, not even a comment: the error disappears and the code
// carries on as if it worked. Handle it, log it, let it through, or say in a comment why it's safe.

const CODE = /\.(cs|ts|tsx|js|mjs)$/i;
const EMPTY = /\bcatch\s*(\([^)]*\))?\s*\{\s*\}/g;

export default {
  name: "empty-catch",
  files: (path) => CODE.test(path),
  checkFile({ added, text }) {
    if (text === null) return [];
    const addedLines = new Set(added.map((l) => l.line));
    const findings = [];
    for (const m of text.matchAll(EMPTY)) {
      const line = text.slice(0, m.index).split("\n").length;
      if (addedLines.has(line)) findings.push({ line, message: "empty catch swallows the error; handle it, or say in the block why ignoring it is safe" });
    }
    return findings;
  },
};
