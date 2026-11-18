// A fixed wait in a test: passes on a fast machine, fails on a slow one, and hides the
// condition the test is really waiting for. Wait on that condition instead.

const isTestFile = (path) => /(^|[\/.])(tests?|specs?|e2e)([\/.]|$)/i.test(path) || /Tests?\.cs$/.test(path);
const SLEEP = /\b(Thread\.Sleep|Task\.Delay|waitForTimeout|setTimeout)\s*\(/;

export default {
  name: "test-sleep",
  files: (path) => isTestFile(path) && /\.(cs|ts|tsx|js|mjs)$/i.test(path),
  checkFile({ added }) {
    return added
      .filter((l) => SLEEP.test(l.text) && !/^\s*(\/\/|\*)/.test(l.text))
      .map((l) => ({ line: l.line, message: "fixed wait in a test; wait for the condition itself (an element, a result, an event)" }));
  },
};
