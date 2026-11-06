"""Tests for the plugin's pre-review checks (plugins/umbraco-devkit/checks/run.mjs).

Each test builds a throwaway git repo with one committed file, makes an uncommitted change,
runs the checks and reads the findings as JSON. Needs node and git; skipped without node. Run
with `scripts/check-skill-scripts.sh`, or `python3 -m unittest discover -s scripts/tests`.
"""
import json
import os
import shutil
import subprocess
import tempfile
import unittest

RUNNER = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..",
                                       "plugins", "umbraco-devkit", "checks", "run.mjs"))


def git(cwd, *args):
    subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=True)


@unittest.skipUnless(shutil.which("node"), "node is not installed")
class PreReviewCheckTests(unittest.TestCase):
    def setUp(self):
        self.repo = tempfile.mkdtemp()
        git(self.repo, "init", "-q", "-b", "main")
        self.write("src/Thing.cs", "namespace X;\n\npublic class Thing { }\n")
        git(self.repo, "add", "-A")
        git(self.repo, "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "-m", "init")

    def tearDown(self):
        shutil.rmtree(self.repo, ignore_errors=True)

    def write(self, path, content):
        full = os.path.join(self.repo, *path.split("/"))
        os.makedirs(os.path.dirname(full), exist_ok=True)
        mode = "wb" if isinstance(content, bytes) else "w"
        with open(full, mode, **({} if mode == "wb" else {"encoding": "utf-8", "newline": ""})) as f:
            f.write(content)

    def run_checks(self, *args, expect=None):
        p = subprocess.run(["node", RUNNER, "--json", "--cwd", self.repo, *args],
                           capture_output=True, text=True)
        findings = json.loads(p.stdout or "[]")
        self.assertEqual(p.returncode, 1 if findings else 0, p.stderr)
        return findings

    def names(self, findings):
        return sorted({f["check"] for f in findings})

    def test_clean_change_has_no_findings(self):
        self.write("src/Thing.cs", "namespace X;\n\npublic class Thing { public int Id { get; set; } }\n")
        self.assertEqual(self.run_checks(), [])

    # encoding

    def test_windows_1252_byte_in_changed_file(self):
        self.write("src/Thing.cs", b"namespace X;\n// a \x97 dash\npublic class Thing { }\n")
        findings = self.run_checks()
        self.assertEqual(self.names(findings), ["encoding"])
        self.assertEqual(findings[0]["path"], "src/Thing.cs")

    def test_utf8_with_crlf_is_fine(self):
        self.write("src/Thing.cs", "namespace X;\r\n// café\r\npublic class Thing { }\r\n")
        self.assertEqual(self.run_checks(), [])

    # plan-links

    def test_comment_pointing_into_plan_folder(self):
        self.write("src/Thing.cs", "namespace X;\n\n// see docs/plans/tag-filters/SPEC.md\npublic class Thing { }\n")
        findings = self.run_checks()
        self.assertEqual(self.names(findings), ["plan-links"])
        self.assertEqual(findings[0]["line"], 3)

    def test_plan_files_may_mention_plan_folders(self):
        self.write("docs/plans/tag-filters/README.md", "See docs/plans/tag-filters/SPEC.md\n")
        git(self.repo, "add", "-N", "docs")
        self.assertEqual(self.run_checks(), [])

    def test_unchanged_line_is_not_reported(self):
        self.write("src/Old.cs", "// docs/archive/plans/old/BRIEF.md\n")
        git(self.repo, "add", "-A")
        git(self.repo, "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "-m", "old")
        self.write("src/Old.cs", "// docs/archive/plans/old/BRIEF.md\nclass Old { }\n")
        self.assertEqual(self.run_checks(), [])

    # unsafe-html

    def test_unsafe_html_without_sanitize(self):
        self.write("client/el.ts", "html`${unsafeHTML(this.summary)}`;\n")
        git(self.repo, "add", "-N", "client")
        self.assertEqual(self.names(self.run_checks()), ["unsafe-html"])

    def test_unsafe_html_with_sanitize(self):
        self.write("client/el.ts", "html`${unsafeHTML(sanitizeHTML(this.summary))}`;\n")
        git(self.repo, "add", "-N", "client")
        self.assertEqual(self.run_checks(), [])

    # untracked

    def test_untracked_file_is_reported(self):
        self.write("src/seed.uda", "{}\n")
        findings = self.run_checks()
        self.assertEqual(self.names(findings), ["untracked"])
        self.assertEqual(findings[0]["path"], "src/seed.uda")

    def test_ignored_file_is_not_reported(self):
        self.write(".gitignore", "bin/\n")
        git(self.repo, "add", ".gitignore")
        self.write("bin/out.dll", "x")
        self.assertEqual(self.run_checks(), [])

    # base

    def test_base_limits_to_changes_since_that_ref(self):
        self.write("src/Thing.cs", "// docs/plans/a/SPEC.md\npublic class Thing { }\n")
        git(self.repo, "add", "-A")
        git(self.repo, "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "-m", "round 1")
        self.write("src/Thing.cs", "// docs/plans/a/SPEC.md\npublic class Thing { int x; }\n")
        self.assertEqual(self.run_checks("--base", "HEAD"), [])
        self.assertEqual(self.names(self.run_checks("--base", "HEAD~1")), ["plan-links"])

    # project checks and config

    def test_project_check_is_loaded(self):
        self.write(".claude/checks/no-todo.mjs",
                   'export default { name: "no-todo", checkFile: ({ added }) =>'
                   ' added.filter(l => l.text.includes("TODO")).map(l => ({ line: l.line, message: "TODO left" })) };\n')
        git(self.repo, "add", "-A")
        git(self.repo, "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "-m", "check")
        self.write("src/Thing.cs", "// TODO\npublic class Thing { }\n")
        self.assertEqual(self.names(self.run_checks()), ["no-todo"])

    def test_config_turns_a_check_off(self):
        self.write(".claude/checks/config.json", '{ "disabled": ["untracked"] }\n')
        git(self.repo, "add", "-A")
        git(self.repo, "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "-m", "config")
        self.write("src/seed.uda", "{}\n")
        self.assertEqual(self.run_checks(), [])

    def test_outside_a_repo_exits_2(self):
        outside = tempfile.mkdtemp()
        try:
            p = subprocess.run(["node", RUNNER, "--cwd", outside], capture_output=True, text=True)
            self.assertEqual(p.returncode, 2)
        finally:
            shutil.rmtree(outside, ignore_errors=True)


if __name__ == "__main__":
    unittest.main()
