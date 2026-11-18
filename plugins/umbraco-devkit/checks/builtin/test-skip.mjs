// A test switched off in a test file: an agent's quickest way to a green run. A spec marked
// pending (bdd-specs writes them that way until a task makes them pass) is allowed.

const isTestFile = (path) => /(^|[\/.])(tests?|specs?|e2e)([\/.]|$)/i.test(path) || /Tests?\.cs$/.test(path);
const CS = [
  /[\[,]\s*(Ignore|Explicit|Skip)\s*[\](,]/, // NUnit, TUnit: [Ignore(...)], [Test, Explicit]
  /\bSkip\s*=/, // xUnit [Fact(Skip = "...")]
  /\bAssert\.(Ignore|Inconclusive|Skip(When|Unless)?)\s*\(/,
  /^\s*#if\s+false\b/,
];
const JS = [/\b(it|test|describe|suite|context)\.(skip|only|fixme)\s*\(/, /\b[xf](it|describe|test)\s*\(/];
const FOCUS = /\.only\s*\(|\bf(it|describe)\s*\(/;

export default {
  name: "test-skip",
  files: (path) => isTestFile(path) && /\.(cs|ts|tsx|js|mjs)$/i.test(path),
  checkFile({ path, added }) {
    const patterns = /\.cs$/i.test(path) ? CS : JS;
    return added
      .filter((l) => patterns.some((p) => p.test(l.text)))
      .filter((l) => FOCUS.test(l.text) || !/pending/i.test(l.text))
      .map((l) => ({
        line: l.line,
        message: FOCUS.test(l.text)
          ? "a focused test (.only) stops the rest of the suite running; remove it"
          : "test switched off; make it pass, or mark it pending if no task has built it yet",
      }));
  },
};
