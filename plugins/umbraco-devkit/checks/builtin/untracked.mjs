// A new file git doesn't track yet. `git diff` leaves it out, so the reviewer never sees it and
// the task's commit can miss it.

export default {
  name: "untracked",
  checkRepo({ untracked }) {
    return untracked.map((path) => ({
      path,
      message: "new file git doesn't track; run `git add -N` on it if it's part of the task, or delete it",
    }));
  },
};
