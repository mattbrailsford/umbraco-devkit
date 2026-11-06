// An added line in code, a test or a CLAUDE.md that points into the plan folders. Plans are
// archived after merge, so the link breaks; a comment should say its reason itself.

const PLAN_PATH = /\bdocs\/(plans|archive|ideas)\//;
const PLAN_FILES = /^docs\/(plans|archive|ideas)\//;

export default {
  name: "plan-links",
  files: (path) => !PLAN_FILES.test(path),
  checkFile({ added }) {
    return added
      .filter((l) => PLAN_PATH.test(l.text))
      .map((l) => ({ line: l.line, message: "points into a plan folder, which moves when archived; say the reason here instead" }));
  },
};
