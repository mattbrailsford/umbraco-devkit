"""Tests for advisory-fix's notes script (plugins/umbraco-devkit/skills/advisory-fix/scripts/notes.mjs).

Each test builds a throwaway repo and drives the script the way the skill does: create the
file, append to a section, replace a section, rewrite it whole. Needs node and git; skipped
without node. Run with `scripts/check-skill-scripts.sh`, or
`python3 -m unittest discover -s scripts/tests`.
"""
import os
import shutil
import subprocess
import tempfile
import unittest

SCRIPT = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..", "plugins", "umbraco-devkit",
                                       "skills", "advisory-fix", "scripts", "notes.mjs"))
KEY = "GHSA-abcd-efgh-ijkl"


def git(cwd, *args):
    return subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=True, text=True)


@unittest.skipUnless(shutil.which("node"), "node is not installed")
class NotesTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.repo = os.path.join(self.tmp, "repo")
        os.makedirs(self.repo)
        git(self.repo, "init", "-q", "-b", "main")
        git(self.repo, "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "--allow-empty", "-m", "init")
        self.file = os.path.join(self.repo, ".git", "devkit-advisories", f"{KEY}.md")

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def notes(self, *args, stdin=None, cwd=None):
        return subprocess.run(["node", SCRIPT, *args], cwd=cwd or self.repo, input=stdin,
                              capture_output=True, text=True)

    def read(self):
        with open(self.file) as f:
            return f.read()

    def test_first_call_creates_from_template_and_prints_it(self):
        r = self.notes(KEY)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertTrue(os.path.exists(self.file))
        self.assertTrue(self.read().startswith(f"# {KEY}\n"))
        self.assertIn("## Versions", r.stdout)
        self.assertIn(os.path.join("devkit-advisories", f"{KEY}.md"), r.stdout)

    def test_git_never_sees_it(self):
        self.notes(KEY)
        self.assertEqual(git(self.repo, "status", "--porcelain").stdout, "")

    def test_append_to_log_replaces_the_placeholder_then_keeps_adding(self):
        self.notes(KEY)
        self.assertEqual(self.notes(KEY, "--append", "log", stdin="- 25-11-2026: confirmed.\n").returncode, 0)
        self.notes(KEY, "--append", "Log", stdin="- 26-11-2026: embargo recorded.\n")
        log = self.read().split("## Log", 1)[1]
        self.assertNotIn("[DD-MM-YYYY", log)
        self.assertLess(log.index("confirmed"), log.index("embargo recorded"))

    def test_section_replaces_only_that_section(self):
        self.notes(KEY)
        table = "| Package | Line | Affected | Fixed in |\n|---|---|---|---|\n| P | 17 | `>= 17.1.1, < 17.2.1` | 17.2.1 |\n"
        r = self.notes(KEY, "--section", "Versions", stdin=table)
        self.assertEqual(r.returncode, 0, r.stderr)
        text = self.read()
        versions = text.split("## Versions", 1)[1].split("\n## ", 1)[0]
        self.assertIn("17.2.1", versions)
        self.assertNotIn("Introduced by", versions)
        self.assertIn("## Release", text)
        self.assertIn("## Plan", text)

    def test_missing_section_is_added_at_the_end(self):
        self.notes(KEY)
        self.notes(KEY, "--append", "Follow-ups", stdin="- Cap the page size.\n")
        self.assertTrue(self.read().rstrip().endswith("## Follow-ups\n\n- Cap the page size."))

    def test_write_replaces_the_file_and_keeps_a_backup(self):
        self.notes(KEY)
        before = self.read()
        self.notes(KEY, "--write", stdin=f"# {KEY}\n\nRewritten.\n")
        self.assertEqual(self.read(), f"# {KEY}\n\nRewritten.\n")
        with open(self.file + ".bak") as f:
            self.assertEqual(f.read(), before)

    def test_worktrees_share_the_file(self):
        self.notes(KEY)
        self.notes(KEY, "--append", "Log", stdin="- from main\n")
        wt = os.path.join(self.tmp, "wt")
        git(self.repo, "worktree", "add", "-q", "-b", "fix", wt)
        r = self.notes(KEY, cwd=wt)
        self.assertIn("- from main", r.stdout)

    def test_empty_stdin_and_bad_keys_are_refused(self):
        self.notes(KEY)
        self.assertNotEqual(self.notes(KEY, "--append", "Log", stdin="").returncode, 0)
        self.assertNotEqual(self.notes("../escape").returncode, 0)
        self.assertNotEqual(self.notes(KEY, "--section").returncode, 0)

    def test_list_shows_keys_and_their_tickets(self):
        self.assertIn("No advisory files", self.notes("--list").stdout)
        self.notes(KEY)
        with open(self.file) as f:
            text = f.read()
        with open(self.file, "w") as f:
            f.write(text.replace("- Report: [", "- Report: SEC-881 and the advisory [", 1))
        out = self.notes("--list").stdout
        self.assertIn(KEY, out)
        self.assertIn("SEC-881", out)

    def test_outside_a_repo_fails(self):
        self.assertNotEqual(self.notes(KEY, cwd=self.tmp).returncode, 0)


if __name__ == "__main__":
    unittest.main()
