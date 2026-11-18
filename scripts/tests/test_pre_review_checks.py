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

    # test-skip

    def add(self, path, content):
        self.write(path, content)
        git(self.repo, "add", "-N", path)

    def test_ignored_nunit_test(self):
        self.add("tests/Foo.Tests/ThingTests.cs", '[Test, Ignore("flaky")]\npublic void Saves() { }\n')
        findings = self.run_checks()
        self.assertEqual(self.names(findings), ["test-skip"])
        self.assertEqual(findings[0]["line"], 1)

    def test_xunit_skip_and_if_false(self):
        self.add("src/Foo.Tests/ThingTests.cs", '[Fact(Skip = "later")]\npublic void A() { }\n#if false\n#endif\n')
        self.assertEqual([f["line"] for f in self.run_checks()], [1, 3])

    def test_pending_spec_is_allowed(self):
        self.add("src/Foo.Tests/ThingTests.cs", '[Test, Ignore("Pending")]\npublic void A() { }\n')
        self.add("client/el.test.ts", 'it.skip("pending implementation", () => {});\n')
        self.assertEqual(self.run_checks(), [])

    def test_js_skip_and_only(self):
        self.add("client/el.test.ts", 'it.skip("saves", () => {});\ndescribe.only("x", () => {});\n')
        self.assertEqual(self.names(self.run_checks()), ["test-skip"])

    def test_focused_test_is_reported_even_if_pending(self):
        self.add("e2e/save.spec.ts", 'test.only("pending", async () => {});\n')
        self.assertEqual(self.names(self.run_checks()), ["test-skip"])

    def test_ignore_attribute_outside_tests_is_fine(self):
        self.add("src/Persistence/ThingDto.cs", "[Ignore]\npublic string Name { get; set; }\n")
        self.add("src/Latest.cs", '[Ignore("x")]\nclass Latest { }\n')
        self.assertEqual(self.run_checks(), [])

    # test-sleep

    def test_sleep_in_test(self):
        self.add("tests/ThingTests.cs", "await Task.Delay(500);\nThread.Sleep(10);\n")
        self.add("e2e/save.spec.ts", "await page.waitForTimeout(1000);\n")
        findings = self.run_checks()
        self.assertEqual(self.names(findings), ["test-sleep"])
        self.assertEqual(len(findings), 3)

    def test_delay_outside_tests_is_fine(self):
        self.write("src/Thing.cs", "namespace X;\n\npublic class Thing { Task Wait() => Task.Delay(10); }\n")
        self.assertEqual(self.run_checks(), [])

    # empty-catch

    def test_empty_catch_one_line_and_multi_line(self):
        self.write("src/Thing.cs", "namespace X;\n\npublic class Thing {\n void A() { try { } catch { } }\n"
                                   " void B() {\n  try { }\n  catch (Exception)\n  {\n  }\n }\n}\n")
        self.add("client/el.ts", "try { go(); } catch (e) {}\n")
        findings = self.run_checks()
        self.assertEqual(self.names(findings), ["empty-catch"])
        self.assertEqual(sorted((f["path"], f["line"]) for f in findings),
                         [("client/el.ts", 1), ("src/Thing.cs", 4), ("src/Thing.cs", 7)])

    def test_catch_with_comment_or_body_is_fine(self):
        self.write("src/Thing.cs", "namespace X;\n\npublic class Thing {\n void A() { try { } catch { /* optional cache */ } }\n"
                                   " void B() { try { } catch (Exception ex) { _log.Warn(ex); } }\n}\n")
        self.assertEqual(self.run_checks(), [])

    # warning-suppression

    def test_pragma_and_nullable_without_reason(self):
        self.write("src/Thing.cs", "#pragma warning disable CS0618\n#nullable disable\nnamespace X;\n\npublic class Thing { }\n")
        findings = self.run_checks()
        self.assertEqual(self.names(findings), ["warning-suppression"])
        self.assertEqual(len(findings), 2)

    def test_pragma_with_reason_on_line_or_above(self):
        self.write("src/Thing.cs", "#pragma warning disable CS0618 // IPublishedCache is obsolete until v18\n"
                                   "// Generated code; nullable annotations don't apply\n#nullable disable\n"
                                   "namespace X;\n\npublic class Thing { }\n")
        self.assertEqual(self.run_checks(), [])

    def test_suppress_message_needs_justification(self):
        self.write("src/Thing.cs", 'namespace X;\n\n[SuppressMessage("Design", "CA1000")]\n'
                                   '[SuppressMessage("Design", "CA1001", Justification = "Owned by the DI container")]\n'
                                   "public class Thing { }\n")
        findings = self.run_checks()
        self.assertEqual([f["line"] for f in findings], [3])

    def test_project_file_settings(self):
        self.add("src/Thing.csproj", "<Project>\n<PropertyGroup>\n<NoWarn>$(NoWarn);CS1591</NoWarn>\n"
                                     "<TreatWarningsAsErrors>false</TreatWarningsAsErrors>\n"
                                     "<!-- Docs are generated elsewhere -->\n<NoWarn>$(NoWarn);CS1573</NoWarn>\n"
                                     "</PropertyGroup>\n</Project>\n")
        self.assertEqual([f["line"] for f in self.run_checks()], [3, 4])

    def test_editorconfig_severity(self):
        self.add(".editorconfig", "[*.cs]\ndotnet_diagnostic.CA2007.severity = none\n"
                                  "# Umbraco has no sync context\ndotnet_diagnostic.CA2008.severity = none\n"
                                  "dotnet_diagnostic.CA1000.severity = error\n")
        self.assertEqual([f["line"] for f in self.run_checks()], [2])

    def test_typescript_suppressions(self):
        self.add("client/el.ts", "// @ts-ignore\nconst a = b;\n"
                                 "// @ts-expect-error the generated client types this field wrongly\nconst c = d;\n"
                                 "// eslint-disable-next-line no-explicit-any\nlet e: any;\n"
                                 "// eslint-disable-next-line no-explicit-any -- payload shape is open\nlet f: any;\n")
        self.assertEqual([f["line"] for f in self.run_checks()], [1, 5])

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
