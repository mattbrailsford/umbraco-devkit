"""Tests for the plugin's trunk-gate hook (plugins/umbraco-devkit/hooks/trunk-gate.mjs).

Each test builds a throwaway git repo, feeds the hook the JSON Claude Code would send, and
checks it stays quiet, asks, or blocks. Needs node and git; skipped without node. Run with
`scripts/check-skill-scripts.sh`, or `python3 -m unittest discover -s scripts/tests`.
"""
import json
import os
import shutil
import subprocess
import tempfile
import unittest

HOOK = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..",
                                     "plugins", "umbraco-devkit", "hooks", "trunk-gate.mjs"))
HOOKS_JSON = os.path.join(os.path.dirname(HOOK), "hooks.json")


def git(cwd, *args):
    subprocess.run(["git", *args], cwd=cwd, check=True, capture_output=True)


@unittest.skipUnless(shutil.which("node"), "node is not installed")
class TrunkGateTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.mkdtemp()
        self.repo = os.path.join(self.tmp, "repo")
        os.makedirs(self.repo)
        git(self.repo, "init", "-q", "-b", "main")
        git(self.repo, "-c", "user.name=t", "-c", "user.email=t@t", "commit", "-q", "--allow-empty", "-m", "init")

    def tearDown(self):
        shutil.rmtree(self.tmp, ignore_errors=True)

    def checkout(self, branch):
        git(self.repo, "checkout", "-q", "-B", branch)

    def run_hook(self, command, cwd=None, tool="Bash", env=None, raw=None):
        payload = raw if raw is not None else json.dumps({
            "hook_event_name": "PreToolUse",
            "tool_name": tool,
            "tool_input": {"command": command},
            "cwd": cwd or self.repo,
        })
        full_env = {k: v for k, v in os.environ.items() if k != "UMBRACO_DEVKIT_TRUNK_GATE"}
        full_env.update(env or {})
        p = subprocess.run(["node", HOOK], input=payload, capture_output=True, text=True, env=full_env)
        self.assertEqual(p.returncode, 0, p.stderr)
        if not p.stdout.strip():
            return None
        out = json.loads(p.stdout)["hookSpecificOutput"]
        self.assertEqual(out["hookEventName"], "PreToolUse")
        self.assertTrue(out["permissionDecisionReason"])
        return out["permissionDecision"]

    # Commits

    def test_commit_on_main_asks(self):
        self.assertEqual(self.run_hook('git commit -m "fix: thing"'), "ask")

    def test_commit_on_feature_branch_is_quiet(self):
        self.checkout("feature/x")
        self.assertIsNone(self.run_hook('git add . && git commit -m "feat: x"'))

    def test_commit_on_support_and_version_lines_asks(self):
        for branch in ["support/16.x", "v17/main", "v17/dev", "master"]:
            self.checkout(branch)
            self.assertEqual(self.run_hook("git commit -am wip"), "ask", branch)

    def test_version_feature_branch_is_quiet(self):
        self.checkout("v17/feature/x")
        self.assertIsNone(self.run_hook("git commit -am wip"))

    def test_remote_default_branch_is_protected(self):
        self.checkout("develop")
        git(self.repo, "update-ref", "refs/remotes/origin/develop", "HEAD")
        git(self.repo, "symbolic-ref", "refs/remotes/origin/HEAD", "refs/remotes/origin/develop")
        self.assertEqual(self.run_hook("git commit -am wip"), "ask")

    def test_dash_c_and_cd_point_at_the_repo(self):
        elsewhere = os.path.join(self.tmp, "other")
        os.makedirs(elsewhere)
        self.assertEqual(self.run_hook(f'git -C "{self.repo}" commit -m x', cwd=elsewhere), "ask")
        self.assertEqual(self.run_hook(f"cd {self.repo} && git commit -m x", cwd=elsewhere), "ask")

    def test_heredoc_message_stays_one_word(self):
        cmd = 'git commit -m "$(cat <<\'EOF\'\nfeat: x\n\ngit push origin main later\nEOF\n)"'
        self.checkout("feature/x")
        self.assertIsNone(self.run_hook(cmd))

    def test_merge_variants(self):
        self.assertEqual(self.run_hook("git merge feature/x"), "ask")
        self.assertIsNone(self.run_hook("git merge --ff-only origin/main"))
        self.assertIsNone(self.run_hook("git merge --abort"))
        self.assertEqual(self.run_hook("git cherry-pick abc123"), "ask")

    # Pushes

    def test_push_to_main_from_feature_asks(self):
        self.checkout("feature/x")
        self.assertEqual(self.run_hook("git push origin main"), "ask")
        self.assertEqual(self.run_hook("git push origin HEAD:refs/heads/main"), "ask")

    def test_push_feature_is_quiet(self):
        self.checkout("feature/x")
        self.assertIsNone(self.run_hook("git push -u origin feature/x"))
        self.assertIsNone(self.run_hook("git push"))

    def test_bare_push_on_main_asks(self):
        self.assertEqual(self.run_hook("git push"), "ask")

    def test_force_push_to_protected_is_blocked(self):
        self.checkout("feature/x")
        for cmd in ["git push --force origin main", "git push -uf origin main",
                    "git push origin +main", "git push --force-with-lease origin v17/main"]:
            self.assertEqual(self.run_hook(cmd), "deny", cmd)

    def test_force_push_to_feature_is_quiet(self):
        self.checkout("feature/x")
        self.assertIsNone(self.run_hook("git push --force-with-lease origin feature/x"))

    def test_deleting_protected_is_blocked(self):
        self.checkout("feature/x")
        self.assertEqual(self.run_hook("git push origin --delete support/16.x"), "deny")
        self.assertEqual(self.run_hook("git push origin :main"), "deny")

    def test_deny_wins_over_ask(self):
        self.assertEqual(self.run_hook("git commit -m x && git push -f origin main"), "deny")

    # Everything else

    def test_unrelated_commands_are_quiet(self):
        for cmd in ["git status", "git log --oneline", 'echo "git push origin main"', "dotnet build", "npm test"]:
            self.assertIsNone(self.run_hook(cmd), cmd)

    def test_powershell_tool_is_checked(self):
        self.assertEqual(self.run_hook("git commit -m x", tool="PowerShell"), "ask")

    def test_off_switch(self):
        self.assertIsNone(self.run_hook("git commit -m x", env={"UMBRACO_DEVKIT_TRUNK_GATE": "off"}))

    def test_not_a_repo_is_quiet(self):
        elsewhere = os.path.join(self.tmp, "other")
        os.makedirs(elsewhere)
        self.assertIsNone(self.run_hook("git commit -m x", cwd=elsewhere))

    def test_bad_input_fails_open(self):
        self.assertIsNone(self.run_hook("", raw="not json"))

    def test_hooks_json_runs_this_script(self):
        with open(HOOKS_JSON, encoding="utf-8") as f:
            config = json.load(f)
        entry = config["hooks"]["PreToolUse"][0]
        self.assertIn("Bash", entry["matcher"])
        hook = entry["hooks"][0]
        self.assertEqual(hook["command"], "node")
        self.assertEqual(hook["args"], ["${CLAUDE_PLUGIN_ROOT}/hooks/trunk-gate.mjs"])


if __name__ == "__main__":
    unittest.main()
