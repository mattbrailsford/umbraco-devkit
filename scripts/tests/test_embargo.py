"""Tests for the plugin's security embargo (plugins/umbraco-devkit/hooks/embargo.mjs and
embargo-gate.mjs).

Each test builds a throwaway repo with a "public" remote and a "private fork", records an
embargo on a fix branch, then tries the ways the fix could leak: pushing it, merging or
cherry-picking it into another branch, opening a PR, and lifting the embargo. The hook tests feed
embargo-gate.mjs the JSON Claude Code would send; the pre-push tests run real pushes into bare
repos. Needs node and git; skipped without node. Run with `scripts/check-skill-scripts.sh`, or
`python3 -m unittest discover -s scripts/tests`.
"""
import json
import os
import pathlib
import shutil
import subprocess
import tempfile
import unittest

HOOKS = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..",
                                      "plugins", "umbraco-devkit", "hooks"))
GATE = os.path.join(HOOKS, "embargo-gate.mjs")
CLI = os.path.join(HOOKS, "embargo.mjs")
HOOKS_JSON = os.path.join(HOOKS, "hooks.json")

PUBLIC_URL = "https://github.com/example/Example.Package.git"
FORK_URL = "git@github.com:example/Example.Package-ghsa-abcd-efgh-ijkl.git"
ID = "GHSA-abcd-efgh-ijkl"
FIX = "v18/hotfix/access-check"

ENV = {**os.environ, "GIT_AUTHOR_NAME": "t", "GIT_AUTHOR_EMAIL": "t@t",
       "GIT_COMMITTER_NAME": "t", "GIT_COMMITTER_EMAIL": "t@t"}


def git(cwd, *args, check=True):
    return subprocess.run(["git", *args], cwd=cwd, check=check, capture_output=True, text=True, env=ENV)


def commit(repo, name, text, message):
    with open(os.path.join(repo, name), "w") as f:
        f.write(text)
    git(repo, "add", name)
    git(repo, "commit", "-q", "-m", message)


def cli(repo, *args):
    return subprocess.run(["node", CLI, *args], cwd=repo, capture_output=True, text=True, env=ENV)


class Base(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.repo = os.path.join(self.tmp, "repo")
        os.makedirs(self.repo)
        git(self.repo, "init", "-q", "-b", "v18/dev")
        commit(self.repo, "app.cs", "class App {}\n", "init")

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def make_fix(self):
        git(self.repo, "checkout", "-q", "-b", FIX)
        commit(self.repo, "auth.cs", "check();\n", "fix(core): Check access consistently")
        git(self.repo, "checkout", "-q", "v18/dev")

    def embargo(self, id=ID):
        r = cli(self.repo, "add", id, "--branch", FIX)
        self.assertEqual(r.returncode, 0, r.stderr)
        return r


@unittest.skipUnless(shutil.which("node"), "node is not installed")
class GateTests(Base):
    """The Claude Code hook. Remotes point at GitHub URLs but nothing is ever pushed."""

    def setUp(self):
        super().setUp()
        git(self.repo, "remote", "add", "origin", PUBLIC_URL)
        git(self.repo, "remote", "add", "fork", FORK_URL)
        git(self.repo, "update-ref", "refs/remotes/origin/v18/dev", "v18/dev")
        self.make_fix()

    def run_hook(self, command=None, cwd=None, tool="Bash", file_path=None, raw=None):
        tool_input = {"command": command} if command is not None else {"file_path": file_path}
        payload = raw if raw is not None else json.dumps({
            "hook_event_name": "PreToolUse", "tool_name": tool,
            "tool_input": tool_input, "cwd": cwd or self.repo,
        })
        p = subprocess.run(["node", GATE], input=payload, capture_output=True, text=True, env=ENV)
        self.assertEqual(p.returncode, 0, p.stderr)
        if not p.stdout.strip():
            return None
        out = json.loads(p.stdout)["hookSpecificOutput"]
        self.assertEqual(out["hookEventName"], "PreToolUse")
        self.assertTrue(out["permissionDecisionReason"])
        return out["permissionDecision"]

    # Without an embargo nothing changes

    def test_no_embargo_is_quiet(self):
        self.assertIsNone(self.run_hook(f"git push origin {FIX}"))
        self.assertIsNone(self.run_hook("gh pr create --fill"))

    # Pushes

    def test_push_fix_to_public_is_blocked(self):
        self.embargo()
        self.assertEqual(self.run_hook(f"git push -u origin {FIX}"), "deny")

    def test_push_fix_to_fork_is_quiet(self):
        self.embargo()
        self.assertIsNone(self.run_hook(f"git push -u fork {FIX}"))

    def test_bare_push_on_fix_branch_is_blocked(self):
        self.embargo()
        git(self.repo, "checkout", "-q", FIX)
        self.assertEqual(self.run_hook("git push"), "deny")

    def test_renamed_destination_is_blocked(self):
        self.embargo()
        git(self.repo, "checkout", "-q", FIX)
        self.assertEqual(self.run_hook("git push origin HEAD:refs/heads/v18/feature/tidy"), "deny")

    def test_branch_with_fix_merged_in_is_blocked(self):
        self.embargo()
        git(self.repo, "checkout", "-q", "-b", "v18/release/1.2.3")
        git(self.repo, "merge", "-q", "--no-ff", "-m", "merge", FIX)
        self.assertEqual(self.run_hook("git push origin v18/release/1.2.3"), "deny")

    def test_cherry_picked_and_reworded_copy_is_blocked(self):
        self.embargo()
        git(self.repo, "checkout", "-q", "-b", "v18/release/1.2.3")
        commit(self.repo, "other.cs", "x\n", "chore: unrelated")
        git(self.repo, "cherry-pick", FIX)
        git(self.repo, "commit", "-q", "--amend", "-m", "fix(core): Tidy up")
        self.assertEqual(self.run_hook("git push origin v18/release/1.2.3"), "deny")

    def test_unrelated_branch_is_quiet(self):
        self.embargo()
        git(self.repo, "checkout", "-q", "-b", "v18/feature/x")
        commit(self.repo, "feature.cs", "x\n", "feat: x")
        self.assertIsNone(self.run_hook("git push -u origin v18/feature/x"))

    def test_push_everything_or_to_a_url_is_blocked(self):
        self.embargo()
        self.assertEqual(self.run_hook("git push --all origin"), "deny")
        self.assertEqual(self.run_hook("git push --mirror origin"), "deny")
        self.assertEqual(self.run_hook(f"git push https://github.com/someone/else {FIX}"), "deny")

    def test_fork_url_in_any_form_is_allowed(self):
        self.embargo()
        self.assertIsNone(self.run_hook(f"git push https://github.com/example/Example.Package-ghsa-abcd-efgh-ijkl {FIX}"))

    def test_id_without_a_private_fork_blocks_every_push(self):
        self.embargo("TICKET-123")
        self.assertEqual(self.run_hook(f"git push fork {FIX}"), "deny")

    def test_fork_for_another_advisory_is_blocked(self):
        self.embargo()
        self.assertEqual(self.run_hook(f"git push https://github.com/example/Example.Package-ghsa-zzzz-zzzz-zzzz {FIX}"), "deny")
        self.assertEqual(self.run_hook(f"git push https://github.com/someone/Example.Package-ghsa-abcd-efgh-ijkl {FIX}"), "deny")

    def test_checkout_cloned_from_the_fork_can_push_to_it(self):
        git(self.repo, "remote", "remove", "fork")
        git(self.repo, "remote", "set-url", "origin", FORK_URL)
        self.embargo()
        self.assertIsNone(self.run_hook(f"git push origin {FIX}"))

    def test_cd_and_dash_c_reach_the_repo(self):
        self.embargo()
        self.assertEqual(self.run_hook(f"cd \"{self.repo}\" && git push origin {FIX}", cwd=self.tmp), "deny")
        self.assertEqual(self.run_hook(f"git -C repo push origin {FIX}", cwd=self.tmp), "deny")

    def test_worktree_shares_the_embargo(self):
        self.embargo()
        wt = os.path.join(self.tmp, "wt")
        git(self.repo, "worktree", "add", "-q", wt, FIX)
        self.assertEqual(self.run_hook("git push origin HEAD", cwd=wt), "deny")

    def test_unknown_ref_fails_closed(self):
        self.embargo()
        self.assertEqual(self.run_hook("git push origin no-such-branch"), "deny")

    def test_delete_is_quiet(self):
        self.embargo()
        self.assertIsNone(self.run_hook(f"git push origin --delete {FIX}"))

    # Pull requests

    def test_pr_from_fix_branch_to_public_is_blocked(self):
        self.embargo()
        git(self.repo, "checkout", "-q", FIX)
        self.assertEqual(self.run_hook("gh pr create --draft --fill"), "deny")
        self.assertEqual(self.run_hook("gh pr create -R example/Example.Package --fill"), "deny")

    def test_pr_on_the_fork_is_quiet(self):
        self.embargo()
        git(self.repo, "checkout", "-q", FIX)
        self.assertIsNone(self.run_hook("gh pr create --repo example/Example.Package-ghsa-abcd-efgh-ijkl --fill"))

    # Lifting or loosening

    def test_lifting_or_loosening_is_blocked(self):
        self.embargo()
        for cmd in [f"git config --remove-section devkit-embargo.{ID}",
                    f"git config --unset-all devkit-embargo.{ID}.branch",
                    f"git config unset devkit-embargo.{ID}.branch",
                    f"git config --add devkit-embargo.{ID}.remote {PUBLIC_URL}",
                    "git config --edit"]:
            self.assertEqual(self.run_hook(cmd), "deny", cmd)

    def test_reading_or_adding_a_branch_is_quiet(self):
        self.embargo()
        self.assertIsNone(self.run_hook("git config --get-regexp ^devkit-embargo\\."))
        self.assertIsNone(self.run_hook(f"git config --add devkit-embargo.{ID}.branch v17/hotfix/access-check"))

    def test_file_tools_cannot_edit_git_config_or_hooks(self):
        self.embargo()
        self.assertEqual(self.run_hook(tool="Edit", file_path=os.path.join(self.repo, ".git", "config")), "deny")
        self.assertEqual(self.run_hook(tool="Write", file_path=os.path.join(self.repo, ".git", "hooks", "pre-push")), "deny")
        self.assertIsNone(self.run_hook(tool="Edit", file_path=os.path.join(self.repo, "app.cs")))

    def test_file_tools_are_quiet_without_an_embargo(self):
        self.assertIsNone(self.run_hook(tool="Edit", file_path=os.path.join(self.repo, ".git", "config")))

    # Wording

    def test_advisory_or_ticket_id_in_published_text_is_blocked(self):
        self.embargo()
        git(self.repo, "config", "--add", f"devkit-embargo.{ID}.ticket", "SEC-881")
        for cmd in [f'git commit -m "fix: tidy {ID.lower()}"',
                    'git commit -am "fix(core): tidy" -m "Refs SEC-881"',
                    "git commit -m \"$(cat <<'EOF'\nfix: tidy\n\nCVE-2026-12345\nEOF\n)\"",
                    "git checkout -b v18/hotfix/sec-881",
                    "git tag v18.0.1 -m 'GHSA-zzzz-yyyy-xxxx'",
                    'gh pr create -R example/Example.Package-ghsa-abcd-efgh-ijkl --title "Tidy" --body "Fixes SEC-881"',
                    'gh issue comment 12 --body "see sec-881"']:
            self.assertEqual(self.run_hook(cmd), "deny", cmd)

    def test_message_file_is_read(self):
        self.embargo()
        with open(os.path.join(self.repo, "msg.txt"), "w") as f:
            f.write(f"fix: tidy\n\n{ID}\n")
        self.assertEqual(self.run_hook("git commit -F msg.txt"), "deny")

    def test_telling_words_are_asked_about(self):
        self.embargo()
        self.assertEqual(self.run_hook('git commit -m "fix: prevent permission bypass"'), "ask")
        self.assertEqual(self.run_hook('gh pr create --title "Fix XSS in picker" --body x'), "ask")

    def test_neutral_text_and_places_are_quiet(self):
        self.embargo()
        git(self.repo, "config", "--add", f"devkit-embargo.{ID}.ticket", "SEC-881")
        for cmd in ['git commit -m "fix(core): Check access consistently" -- src/Security/Access.cs',
                    'gh pr create -R example/Example.Package-ghsa-abcd-efgh-ijkl --title "Check access consistently" --body "Tidy."',
                    f"git worktree add -b v18/hotfix/access-check ../Example.Package-{ID}",
                    "git checkout -- src/Security/Access.cs",
                    "git branch -d v18/hotfix/sec-881-old"]:
            self.assertIsNone(self.run_hook(cmd), cmd)

    def test_wording_is_quiet_without_an_embargo(self):
        self.assertIsNone(self.run_hook(f'git commit -m "fix {ID} bypass"'))

    def test_pushed_commit_messages_are_checked_even_to_the_fork(self):
        self.embargo()
        git(self.repo, "checkout", "-q", FIX)
        commit(self.repo, "more.cs", "x\n", f"fix: follow-up for {ID}")
        self.assertEqual(self.run_hook(f"git push fork {FIX}"), "deny")

    def test_adding_a_ticket_is_quiet(self):
        self.embargo()
        self.assertIsNone(self.run_hook(f"git config --add devkit-embargo.{ID}.ticket SEC-881"))

    # Plumbing

    def test_bad_input_is_quiet(self):
        self.assertIsNone(self.run_hook(raw="not json"))

    def test_hooks_json_runs_this_script(self):
        with open(HOOKS_JSON) as f:
            entries = json.load(f)["hooks"]["PreToolUse"]
        matchers = {e["matcher"]: [a for h in e["hooks"] for a in h.get("args", [])] for e in entries}
        for matcher in ["Bash|PowerShell", "Edit|Write|MultiEdit|NotebookEdit"]:
            self.assertIn("${CLAUDE_PLUGIN_ROOT}/hooks/embargo-gate.mjs", matchers.get(matcher, []), matcher)


@unittest.skipUnless(shutil.which("node"), "node is not installed")
class CliTests(Base):
    def setUp(self):
        super().setUp()
        git(self.repo, "remote", "add", "fork", FORK_URL)
        self.make_fix()

    def test_add_records_the_embargo_and_installs_the_guard(self):
        r = self.embargo()
        self.assertIn(ID, r.stdout)
        self.assertIn("pre-push guard: installed", r.stdout)
        self.assertIn("Private fork: github.com/example/example.package-ghsa-abcd-efgh-ijkl", r.stdout)
        config = git(self.repo, "config", "--get-regexp", "^devkit-embargo\\.").stdout
        self.assertEqual(config.strip(), f"devkit-embargo.{ID}.branch {FIX}")
        self.assertTrue(os.path.exists(os.path.join(self.repo, ".git", "hooks", "umbraco-devkit-embargo.mjs")))

    def test_ticket_is_recorded_and_shown(self):
        r = cli(self.repo, "add", ID, "--branch", FIX, "--ticket", "SEC-881")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("Ticket: SEC-881", r.stdout)
        self.assertIn(f"devkit-embargo.{ID}.ticket SEC-881", git(self.repo, "config", "--get-regexp", "^devkit-embargo\\.").stdout)

    def test_a_remote_cannot_be_named(self):
        r = cli(self.repo, "add", ID, "--branch", FIX, "--remote", PUBLIC_URL)
        self.assertNotEqual(r.returncode, 0)
        self.assertEqual(git(self.repo, "config", "--get-regexp", "^devkit-embargo\\.", check=False).stdout, "")

    def test_id_case_does_not_make_a_second_embargo(self):
        self.embargo()
        self.assertEqual(cli(self.repo, "add", ID.lower(), "--branch", "v17/hotfix/x").returncode, 0)
        self.assertEqual(cli(self.repo, "status").stdout.count("Embargo "), 1)

    def test_no_private_fork_without_a_ghsa_id(self):
        r = self.embargo("TICKET-123")
        self.assertIn("Private fork: none", r.stdout)

    def test_add_more_branches_later(self):
        self.embargo()
        r = cli(self.repo, "add", ID, "--branch", "v17/hotfix/access-check")
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("v17/hotfix/access-check", r.stdout)

    def test_foreign_pre_push_hook_is_left_alone(self):
        hook = os.path.join(self.repo, ".git", "hooks", "pre-push")
        with open(hook, "w") as f:
            f.write("#!/bin/sh\nexit 0\n")
        r = self.embargo()
        self.assertIn("NOT installed", r.stdout)
        with open(hook) as f:
            self.assertEqual(f.read(), "#!/bin/sh\nexit 0\n")

    def test_hooks_path_managed_elsewhere_is_left_alone(self):
        git(self.repo, "config", "core.hooksPath", ".husky")
        r = self.embargo()
        self.assertIn("NOT installed", r.stdout)
        self.assertFalse(os.path.exists(os.path.join(self.repo, ".husky", "pre-push")))

    def test_status_warns_when_already_public(self):
        git(self.repo, "remote", "add", "origin", PUBLIC_URL)
        git(self.repo, "update-ref", f"refs/remotes/origin/{FIX}", FIX)
        self.embargo()
        self.assertIn("WARNING: already on public remote origin", cli(self.repo, "status").stdout)

    def test_bad_id_is_refused(self):
        self.assertNotEqual(cli(self.repo, "add", "bad id", "--branch", FIX).returncode, 0)


@unittest.skipUnless(shutil.which("node"), "node is not installed")
class PrePushTests(Base):
    """Real pushes into bare repos, as a person would run them outside Claude Code."""

    def setUp(self):
        super().setUp()
        self.public = os.path.join(self.tmp, "public.git")
        self.fork = os.path.join(self.tmp, "public-ghsa-abcd-efgh-ijkl.git")
        git(self.tmp, "init", "-q", "--bare", self.public)
        git(self.tmp, "init", "-q", "--bare", self.fork)
        git(self.repo, "remote", "add", "origin", self.public)
        git(self.repo, "remote", "add", "fork", self.fork)
        git(self.repo, "push", "-q", "origin", "v18/dev")
        self.make_fix()
        self.embargo()

    def on_public(self, branch):
        return git(self.public, "rev-parse", "--verify", "--quiet", f"refs/heads/{branch}", check=False).returncode == 0

    def test_push_to_public_is_stopped(self):
        r = git(self.repo, "push", "origin", FIX, check=False)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("embargo", r.stderr)
        self.assertFalse(self.on_public(FIX))

    def test_merged_copy_to_public_is_stopped(self):
        git(self.repo, "checkout", "-q", "-b", "v18/release/x")
        git(self.repo, "merge", "-q", "--no-ff", "-m", "merge", FIX)
        self.assertNotEqual(git(self.repo, "push", "origin", "v18/release/x", check=False).returncode, 0)
        self.assertFalse(self.on_public("v18/release/x"))

    def test_push_to_fork_and_unrelated_pushes_go_through(self):
        self.assertEqual(git(self.repo, "push", "-q", "fork", FIX, check=False).returncode, 0)
        git(self.repo, "checkout", "-q", "-b", "v18/feature/x")
        commit(self.repo, "f.cs", "x\n", "feat: x")
        self.assertEqual(git(self.repo, "push", "-q", "origin", "v18/feature/x", check=False).returncode, 0)

    def test_lifting_the_embargo_lets_it_ship(self):
        git(self.repo, "config", "--remove-section", f"devkit-embargo.{ID}")
        self.assertEqual(git(self.repo, "push", "-q", "origin", FIX, check=False).returncode, 0)
        self.assertTrue(self.on_public(FIX))

    def test_id_in_a_commit_message_is_stopped_even_to_the_fork(self):
        git(self.repo, "checkout", "-q", FIX)
        commit(self.repo, "more.cs", "x\n", f"fix: follow-up for {ID}")
        r = git(self.repo, "push", "fork", FIX, check=False)
        self.assertNotEqual(r.returncode, 0)
        self.assertIn("neutral words", r.stderr)

    def test_telling_words_only_warn(self):
        git(self.repo, "checkout", "-q", "-b", "v18/feature/y")
        commit(self.repo, "y.cs", "y\n", "feat: add an exploit-proof thing")
        r = git(self.repo, "push", "origin", "v18/feature/y", check=False)
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn("exploit", r.stderr)

    def test_push_from_a_worktree_is_stopped(self):
        wt = os.path.join(self.tmp, "wt")
        git(self.repo, "worktree", "add", "-q", wt, FIX)
        self.assertNotEqual(git(wt, "push", "origin", FIX, check=False).returncode, 0)
        self.assertFalse(self.on_public(FIX))


@unittest.skipUnless(shutil.which("node"), "node is not installed")
class NormalizeUrlTests(unittest.TestCase):
    def test_forms_compare_equal(self):
        script = (
            f"import {{ normalizeUrl }} from {json.dumps(pathlib.Path(CLI).as_uri())};"
            "console.log(JSON.stringify(process.argv.slice(1).map(normalizeUrl)));"
        )
        urls = ["https://github.com/Umbraco/Repo.git", "git@github.com:umbraco/repo.git",
                "ssh://git@github.com/umbraco/repo", "https://x-access-token:abc@github.com/umbraco/repo/"]
        p = subprocess.run(["node", "--input-type=module", "-e", script, *urls], capture_output=True, text=True)
        self.assertEqual(p.returncode, 0, p.stderr)
        self.assertEqual(set(json.loads(p.stdout)), {"github.com/umbraco/repo"})


if __name__ == "__main__":
    unittest.main()
