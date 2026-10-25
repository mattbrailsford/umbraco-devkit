"""Tests for the markdown-preview skill's scripts.

Standard library only, and no network: GitHub's renderer is swapped for a stand-in. Run with
`scripts/check-skill-scripts.sh`, or `python3 -m unittest discover -s scripts/tests`.
"""
import http.client
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import time
import unittest
import urllib.parse

SCRIPTS = os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "..",
                                        "plugins", "umbraco-devkit", "skills", "markdown-preview", "scripts"))
sys.path.insert(0, SCRIPTS)

import comments  # noqa: E402
import folders  # noqa: E402
import seen  # noqa: E402
import server  # noqa: E402
import signoffs  # noqa: E402
import worktree  # noqa: E402


def read(path):
    with open(path, encoding="utf-8") as f:
        return f.read()


def write(path, text):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


class TempRepo(unittest.TestCase):
    """Each test gets a throwaway repo: a folder with a `.git` folder, and a small plan."""

    def setUp(self):
        self.root = os.path.realpath(tempfile.mkdtemp(prefix="mdpreview-"))
        self.addCleanup(shutil.rmtree, self.root, ignore_errors=True)
        os.makedirs(os.path.join(self.root, ".git"))
        self.plan = os.path.join(self.root, "docs", "plans", "retries")
        write(os.path.join(self.plan, "README.md"),
              "# Retries\n\n1. [BRIEF.md](./BRIEF.md)\n2. [SPEC.md](SPEC.md)\n3. [PLAN.md](./PLAN.md)\n\n"
              "See [the repo](../README.md) and [GitHub](https://github.com).\n")
        write(os.path.join(self.plan, "BRIEF.md"),
              "# Brief\n\n## Problem\n\nWebhooks **fail silently** when the receiver is down.\n\n## Goals\n\n- Retry with backoff.\n")
        write(os.path.join(self.plan, "SPEC.md"), "# Spec\n\n- Five attempts.\n")
        write(os.path.join(self.plan, "notes.md"), "# Notes\n")
        self.store = comments.Comments(worktree.state_paths(self.root).comments)


class WorktreeTests(TempRepo):
    def test_finds_the_repo_from_inside_it(self):
        self.assertEqual(worktree.find_git(self.plan), (self.root, os.path.join(self.root, ".git")))

    def test_finds_a_linked_worktree_through_its_git_file(self):
        linked = os.path.join(self.root, "linked")
        gitdir = os.path.join(self.root, ".git", "worktrees", "linked")
        os.makedirs(gitdir)
        write(os.path.join(linked, ".git"), f"gitdir: {gitdir}\n")
        self.assertEqual(worktree.find_git(linked), (linked, gitdir))

    def test_outside_a_repo_finds_nothing(self):
        outside = tempfile.mkdtemp()
        self.addCleanup(shutil.rmtree, outside)
        self.assertEqual(worktree.find_git(outside), (None, None))

    def test_comments_live_in_the_git_folder(self):
        self.assertEqual(worktree.state_paths(self.root).comments,
                         os.path.join(self.root, ".git", "markdown-preview", "comments.json"))

    def test_pid_alive(self):
        pid_file = os.path.join(self.root, "pid")
        write(pid_file, str(os.getpid()))
        self.assertTrue(worktree.pid_alive(pid_file))
        write(pid_file, "not a pid")
        self.assertFalse(worktree.pid_alive(pid_file))
        self.assertFalse(worktree.pid_alive(os.path.join(self.root, "missing")))


class CommentStoreTests(TempRepo):
    brief = "/docs/plans/retries/BRIEF.md"

    def add(self, quote="Retry with backoff.", body="Why?"):
        return self.store.add(self.brief, quote, body, section="Goals")

    def test_ids_count_up(self):
        self.assertEqual([self.add()["id"] for _ in range(3)], ["c1", "c2", "c3"])

    def test_only_a_pending_comment_can_be_edited(self):
        c = self.add()
        self.store.edit(c["id"], "Why not?")
        self.assertEqual(self.store.load()[0]["body"], "Why not?")
        self.store.send_drafts()
        with self.assertRaises(ValueError):
            self.store.edit(c["id"], "Too late")

    def test_a_reply_reopens_the_thread_and_can_be_withdrawn(self):
        c = self.add()
        self.store.send_drafts()
        self.store.claude_reply(c["id"], "Which part?")
        self.store.reader_reply(c["id"], "The 2 h step")
        self.assertEqual(self.store.load()[0]["status"], "draft")
        self.store.edit(c["id"], "The 6 h step")  # edits the reply, not the comment
        self.assertEqual(self.store.load()[0]["replies"][-1]["body"], "The 6 h step")
        self.assertEqual(self.store.load()[0]["body"], "Why?")
        self.store.delete(c["id"])  # withdraws only the reply
        item = self.store.load()[0]
        self.assertEqual((item["status"], len(item["replies"])), ("replied", 1))

    def test_deleting_a_pending_comment_removes_it(self):
        c = self.add()
        self.store.delete(c["id"])
        self.assertEqual(self.store.load(), [])

    def test_claude_claims_a_sent_batch(self):
        self.add()
        self.add(body="And this?")
        self.assertEqual(self.store.claim_sent(), [])  # nothing sent yet
        self.store.send_drafts()
        self.assertEqual([c["status"] for c in self.store.claim_sent()], ["working", "working"])
        self.assertEqual(self.store.claim_sent(), [])

    def test_claude_reply_outcomes(self):
        a, b, c = self.add(), self.add(), self.add()
        self.store.claude_reply(a["id"], "Done", done=True)
        self.store.claude_reply(b["id"], "Left for feature-design.", defer="feature-design")
        self.store.claude_reply(c["id"], "Which one?")
        statuses = {x["id"]: (x["status"], x["owner"]) for x in self.store.load()}
        self.assertEqual(statuses, {"c1": ("addressed", None), "c2": ("deferred", "feature-design"), "c3": ("replied", None)})

    def test_moving_keeps_the_first_text_only(self):
        c = self.add(quote="TODO: decide")
        self.store.claude_reply(c["id"], "Decided", done=True, move="We decided A.")
        self.store.claude_reply(c["id"], "Reworded", done=True, move="We chose A.")
        item = self.store.load()[0]
        self.assertEqual((item["quote"], item["original"]), ("We chose A.", "TODO: decide"))

    def test_unresolved_under_a_folder(self):
        self.add()
        self.store.add("/docs/other/X.md", "x", "elsewhere")
        done = self.add()
        self.store.resolve(done["id"])
        self.assertEqual([c["path"] for c in self.store.unresolved(under="/docs/plans/")], [self.brief])
        self.assertEqual(self.store.open_counts(), {self.brief: 1, "/docs/other/X.md": 1})

    def test_describe_says_whose_move_it_is(self):
        c = self.store.add(self.brief, "Retry with backoff.", "```suggestion\nRetry twice.\n```", section="Goals")
        self.store.claude_reply(c["id"], "Left for later.", defer="feature-plan")
        text = comments.describe(self.store.load())
        self.assertIn("(left for feature-plan)", text)
        self.assertIn("in section: Goals", text)
        self.assertIn("has a suggested change", text)

    def test_changes_from_two_processes_are_never_lost(self):
        # The page server and Claude's commands write the same file at once: a read-change-write
        # without the file lock loses one side's change.
        c = self.add()
        code = ("import sys; sys.path.insert(0, %r); import comments; s = comments.Comments(%r)\n"
                "for i in range(40): s.claude_reply('c1', f'{sys.argv[1]}-{i}')") % (SCRIPTS, self.store.path)
        procs = [subprocess.Popen([sys.executable, "-c", code, name]) for name in ("a", "b")]
        for p in procs:
            self.assertEqual(p.wait(timeout=60), 0)
        self.assertEqual(len(self.store.load()[0]["replies"]), 80)


class FolderTests(TempRepo):
    def test_reading_order_follows_the_readme(self):
        # Missing files, links out of the folder and web links are skipped.
        write(os.path.join(self.plan, "README.md"), read(os.path.join(self.plan, "README.md")) + "- [GONE.md](GONE.md)\n")
        self.assertEqual(folders.reading_order(self.plan), ["BRIEF.md", "SPEC.md"])

    def test_file_list_puts_folders_then_reading_order_then_the_rest(self):
        os.makedirs(os.path.join(self.plan, "diagrams"))
        listing = folders.folder_listing(self.plan, "/docs/plans/retries/", "BRIEF.md", {"/docs/plans/retries/SPEC.md": 2})
        names = re.findall(r"</svg>([^<]+)", listing)
        self.assertEqual(names, ["..", "diagrams", "BRIEF.md", "SPEC.md", "notes.md", "README.md"])
        self.assertIn('class="current"', listing)
        self.assertIn('<span class="dot" title="Open comments">2</span>', listing)

    def test_no_way_up_from_the_top_of_the_scope(self):
        listing = folders.folder_listing(self.plan, "/docs/plans/retries/", "", {}, home="/docs/plans/retries/")
        self.assertNotIn(">..<", listing)

    def test_breadcrumbs_carry_their_paths(self):
        trail = folders.breadcrumbs(self.root, "/docs/plans/retries/BRIEF.md")
        self.assertEqual(re.findall(r'data-path="([^"]+)"', trail), ["/", "/docs/", "/docs/plans/", "/docs/plans/retries/", "/docs/plans/retries/BRIEF.md"])

    def test_change_marker_notices_edits_and_new_files(self):
        brief = os.path.join(self.plan, "BRIEF.md")
        before = folders.change_marker(brief)
        time.sleep(0.01)
        write(brief, "# Changed\n")
        after_edit = folders.change_marker(brief)
        write(os.path.join(self.plan, "NEW.md"), "x")
        self.assertNotEqual(before, after_edit)
        self.assertNotEqual(after_edit, folders.change_marker(brief))


class CommandTests(TempRepo):
    def run_cli(self, *args, timeout=20):
        return subprocess.run([sys.executable, os.path.join(SCRIPTS, "preview.py"), *args, "--root", self.root],
                              capture_output=True, text=True, timeout=timeout, cwd=self.root)

    def test_reply_flags(self):
        self.store.add("/docs/plans/retries/BRIEF.md", "Retry with backoff.", "Why?")
        out = self.run_cli("reply", "c1", "Done.", "--done", "--move", "Retry three times.")
        self.assertIn("marked it done (moved to its new text)", out.stdout)
        item = self.store.load()[0]
        self.assertEqual((item["status"], item["quote"]), ("addressed", "Retry three times."))
        self.assertNotEqual(self.run_cli("reply", "c1", "x", "--done", "--defer", "feature-plan").returncode, 0)

    def test_listings(self):
        brief, spec = "/docs/plans/retries/BRIEF.md", "/docs/plans/retries/SPEC.md"
        self.store.add(brief, "Retry with backoff.", "Sent one")
        self.store.send_drafts()
        self.store.add(spec, "Five attempts.", "Unsent one")
        self.assertIn("Sent one", self.run_cli("comments").stdout)
        self.assertNotIn("Unsent one", self.run_cli("comments").stdout)
        self.assertIn("No open comments.", self.run_cli("comments", "--file", os.path.join(self.plan, "SPEC.md")).stdout)
        folder = self.run_cli("comments", "--folder", self.plan).stdout
        self.assertIn("Sent one", folder)
        self.assertIn("written by the reader but not sent yet", folder)
        self.assertIn("Sent one", self.run_cli("comments", "--folder", self.root).stdout)  # the whole worktree

    def test_signoff_commands(self):
        self.assertIn("No sign-off asked for.", self.run_cli("signoff").stdout)
        out = self.run_cli("signoff", "--request", os.path.join(self.plan, "SPEC.md"), os.path.join(self.plan, "BRIEF.md"), "--step", "feature-design")
        self.assertIn("Asked the reviewer to sign off docs/plans/retries/SPEC.md, docs/plans/retries/BRIEF.md.", out.stdout)
        self.assertNotEqual(self.run_cli("signoff", "--request", os.path.join(self.plan, "GONE.md")).returncode, 0)
        signoffs.SignOffs(worktree.state_paths(self.root).signoffs).sign("/docs/plans/retries/SPEC.md", os.path.join(self.plan, "SPEC.md"))
        listing = self.run_cli("signoff").stdout
        self.assertIn("docs/plans/retries/SPEC.md: signed off", listing)
        self.assertIn("docs/plans/retries/BRIEF.md: waiting for the reviewer's sign-off", listing)

    def test_wait_wakes_when_everything_asked_for_is_signed(self):
        store = signoffs.SignOffs(worktree.state_paths(self.root).signoffs)
        store.request(["/docs/plans/retries/SPEC.md"])
        waiter = subprocess.Popen([sys.executable, os.path.join(SCRIPTS, "preview.py"), "wait", "--root", self.root],
                                  stdout=subprocess.PIPE, text=True, cwd=self.root)
        self.addCleanup(lambda: waiter.poll() is None and waiter.kill())
        time.sleep(1.5)
        store.sign("/docs/plans/retries/SPEC.md", os.path.join(self.plan, "SPEC.md"))
        out, _ = waiter.communicate(timeout=20)
        self.assertIn("The reviewer signed off docs/plans/retries/SPEC.md. Everything asked for is signed off.", out)

    def test_wait_returns_the_batch_and_only_one_waits(self):
        script = os.path.join(SCRIPTS, "preview.py")
        waiter = subprocess.Popen([sys.executable, script, "wait", "--root", self.root], stdout=subprocess.PIPE, text=True, cwd=self.root)
        self.addCleanup(lambda: waiter.poll() is None and waiter.kill())
        for _ in range(50):
            if worktree.pid_alive(worktree.state_paths(self.root).helper):
                break
            time.sleep(0.1)
        self.assertIn("Already waiting", self.run_cli("wait").stdout)
        self.store.add("/docs/plans/retries/BRIEF.md", "Retry with backoff.", "Over to you")
        self.store.send_drafts()
        out, _ = waiter.communicate(timeout=20)
        self.assertIn("The reviewer sent 1 comment", out)
        self.assertIn("Over to you", out)
        self.assertEqual(self.store.load()[0]["status"], "working")


class FakeRenderer:
    def render(self, text):
        return "<h1>Drawn</h1><p>" + text[:40] + "</p>"

    def render_many(self, texts):
        return [f"<p>{t}</p>" for t in texts]


class ServerTests(TempRepo):
    def setUp(self):
        super().setUp()
        paths = worktree.state_paths(self.root)
        self.srv = server.PreviewServer(0, root=self.root, css="/* css */", renderer=FakeRenderer(),
                                        comments=self.store, seen=seen.Seen(paths.seen),
                                        signoffs=signoffs.SignOffs(paths.signoffs), user={"login": "someone"},
                                        helper_file=paths.helper)
        threading.Thread(target=self.srv.serve_forever, daemon=True).start()
        self.addCleanup(self.srv.server_close)
        self.addCleanup(self.srv.shutdown)

    def request(self, method, path, body=None):
        conn = http.client.HTTPConnection("127.0.0.1", self.srv.port, timeout=10)
        conn.request(method, path, json.dumps(body) if body is not None else None)
        res = conn.getresponse()
        data = res.read().decode()
        conn.close()
        return res.status, res.getheader("Content-Type"), res.getheader("Location"), data

    def test_a_markdown_file_gets_the_filled_in_page(self):
        status, _, _, page = self.request("GET", "/docs/plans/retries/BRIEF.md")
        self.assertEqual(status, 200)
        self.assertNotRegex(page, r"\{\{\w+\}\}")
        boot = json.loads(re.search(r'<script id="boot" type="application/json">(.*?)</script>', page).group(1))
        self.assertEqual(boot, {"path": "/docs/plans/retries/BRIEF.md", "user": {"login": "someone"}})
        self.assertIn("/* css */", page)

    def test_a_folder_without_its_slash_redirects(self):
        status, _, location, _ = self.request("GET", "/docs/plans/retries")
        self.assertEqual((status, location), (301, "/docs/plans/retries/"))

    def test_page_files_are_served_and_nothing_else(self):
        status, ctype, _, _ = self.request("GET", "/__page/app.js")
        self.assertEqual((status, ctype.split(";")[0]), (200, "text/javascript"))
        for path in ("/__page/../preview.py", "/__page/preview.py", "/__page/missing.js"):
            self.assertEqual(self.request("GET", path)[0], 404, path)

    def test_nothing_outside_the_worktree(self):
        for path in ("/../../etc/passwd", "/%2e%2e/%2e%2e/etc/passwd", "/__render?path=/../../etc/passwd"):
            self.assertEqual(self.request("GET", path)[0], 404, path)

    def test_render_and_comments_round_trip(self):
        brief = "/docs/plans/retries/BRIEF.md"
        self.assertIn("<h1>Drawn</h1>", self.request("GET", "/__render?path=" + urllib.parse.quote(brief))[3])
        self.assertEqual(self.request("POST", "/__comments", {"path": brief, "quote": "Retry with backoff.", "body": "Why?"})[0], 200)
        self.assertEqual(self.request("POST", "/__comments", {"path": "/nope.md", "quote": "x", "body": "x"})[0], 400)
        self.assertEqual(len(json.loads(self.request("GET", "/__comments?drafts=1")[3])), 1)
        self.request("POST", "/__comments/send", {})
        self.assertEqual(self.request("POST", "/__comments/edit", {"id": "c1", "body": "Late"})[0], 400)
        self.assertEqual(len(json.loads(self.request("GET", "/__comments?path=" + urllib.parse.quote(brief))[3])), 1)
        self.assertEqual(self.request("POST", "/__nope", {})[0], 404)

    def test_changes_markers_move_with_the_doc_and_the_comments(self):
        url = "/__changes?path=" + urllib.parse.quote("/docs/plans/retries/BRIEF.md")
        first = json.loads(self.request("GET", url)[3])
        time.sleep(0.01)
        write(os.path.join(self.plan, "BRIEF.md"), "# Edited\n")
        second = json.loads(self.request("GET", url)[3])
        self.store.add("/docs/plans/retries/BRIEF.md", "Edited", "x")
        third = json.loads(self.request("GET", url)[3])
        self.assertNotEqual(first["doc"], second["doc"])
        self.assertEqual(second["doc"], third["doc"])
        self.assertNotEqual(second["comments"], third["comments"])

    def test_an_open_tab_is_reused(self):
        self.assertEqual(self.request("POST", "/__open", {"path": "docs/plans/retries/SPEC.md"})[3], "none")
        self.request("GET", "/__changes?path=" + urllib.parse.quote("/docs/plans/retries/BRIEF.md"))  # a tab checks in
        self.assertEqual(self.request("POST", "/__open", {"path": "docs/plans/retries/SPEC.md"})[3], "reused")
        marks = json.loads(self.request("GET", "/__changes?path=" + urllib.parse.quote("/docs/plans/retries/BRIEF.md"))[3])
        self.assertEqual(marks["navigate"], "/docs/plans/retries/SPEC.md")


    def test_changes_since_comments_were_sent(self):
        brief = "/docs/plans/retries/BRIEF.md"
        url = "/__seen?path=" + urllib.parse.quote(brief)
        marker = "/__changes?path=" + urllib.parse.quote(brief)
        self.assertEqual(json.loads(self.request("GET", url)[3]), {})  # first look: kept as it is
        write(os.path.join(self.plan, "BRIEF.md"), "# Brief, edited\n")
        self.assertIn("<h1>Drawn</h1><p># Brief\n", json.loads(self.request("GET", url)[3])["html"])
        before = json.loads(self.request("GET", marker)[3])["doc"]
        self.request("POST", "/__comments/send", {})  # sending starts afresh, and open pages redraw
        self.assertEqual(json.loads(self.request("GET", url)[3]), {})
        self.assertNotEqual(json.loads(self.request("GET", marker)[3])["doc"], before)

    def test_file_list_marks_changed_docs(self):
        listing = "/__list?path=" + urllib.parse.quote("/docs/plans/retries/")
        self.assertNotIn('class="changed"', self.request("GET", listing)[3])  # seeing the folder keeps copies
        write(os.path.join(self.plan, "SPEC.md"), "# Spec\n\n- Six attempts.\n")
        changed = re.findall(r'</svg>([^<]+)<span class="marks"><span class="changed"', self.request("GET", listing)[3])
        self.assertEqual(changed, ["SPEC.md"])


    def test_sign_off_after_comments_are_resolved(self):
        spec = "/docs/plans/retries/SPEC.md"
        state = lambda: json.loads(self.request("GET", "/__signoff?path=" + urllib.parse.quote(spec))[3])
        self.assertIsNone(state()["state"])
        self.assertEqual(self.request("POST", "/__signoff", {"path": spec})[0], 400)  # nobody asked
        signoffs.SignOffs(worktree.state_paths(self.root).signoffs).request([spec, "/docs/plans/retries/BRIEF.md"], "feature-design")
        self.store.add(spec, "Five attempts.", "Why five?")
        self.assertEqual(state(), {"state": "needed", "at": None, "open": 1})
        self.assertEqual(self.request("POST", "/__signoff", {"path": spec})[0], 400)  # a comment's open
        self.store.resolve("c1")
        self.assertEqual(self.request("POST", "/__signoff", {"path": spec})[0], 200)
        self.assertEqual(state()["state"], "signed")
        listing = self.request("GET", "/__list?path=" + urllib.parse.quote("/docs/plans/retries/"))[3]
        marks = {name: state for state, name in re.findall(r'class="[^"]*so-(\w+)"[^>]*><span class="fileicon">.*?</span></span>([\w.]+)<', listing)}
        self.assertEqual(marks, {"BRIEF.md": "needed", "SPEC.md": "signed"})


    def test_a_folder_with_a_space_in_its_name(self):
        # The page and Claude's commands must name a file the same way, or a comment made on
        # the page never shows in `comments --file`.
        write(os.path.join(self.root, "docs", "my plan", "BRIEF.md"), "# Brief\n\nShip it.\n")
        page = self.request("GET", "/docs/my%20plan/BRIEF.md")[3]
        boot = json.loads(re.search(r'<script id="boot" type="application/json">(.*?)</script>', page).group(1))
        self.assertEqual(boot["path"], "/docs/my plan/BRIEF.md")
        self.assertEqual(self.request("GET", "/docs/my%20plan")[2], "/docs/my%20plan/")
        self.assertEqual(self.request("POST", "/__comments", {"path": boot["path"], "quote": "Ship it.", "body": "When?"})[0], 200)
        self.store.send_drafts()
        listed = subprocess.run([sys.executable, os.path.join(SCRIPTS, "preview.py"), "comments", "--root", self.root,
                                 "--file", os.path.join(self.root, "docs", "my plan", "BRIEF.md")], capture_output=True, text=True).stdout
        self.assertIn("When?", listed)
        listing = self.request("GET", "/__list?path=" + urllib.parse.quote("/docs/my plan/"))[3]
        self.assertIn('href="/docs/my%20plan/BRIEF.md"', listing)
        self.assertIn('<span class="dot" title="Open comments">1</span>', listing)


class SignOffTests(TempRepo):
    def setUp(self):
        super().setUp()
        self.signoffs = signoffs.SignOffs(worktree.state_paths(self.root).signoffs)
        self.spec, self.brief = "/docs/plans/retries/SPEC.md", "/docs/plans/retries/BRIEF.md"

    def state(self, path):
        return self.signoffs.state(path, self.root + path)[0]

    def test_a_sign_off_goes_stale_when_the_doc_changes(self):
        self.signoffs.request([self.spec])
        self.assertEqual(self.state(self.spec), "needed")
        self.signoffs.sign(self.spec, self.root + self.spec)
        self.assertEqual(self.state(self.spec), "signed")
        write(self.root + self.spec, "# Spec\n\n- Six attempts.\n")
        self.assertEqual(self.state(self.spec), "changed")
        self.assertIsNone(self.state(self.brief))
        with self.assertRaises(ValueError):
            self.signoffs.sign(self.brief, self.root + self.brief)

    def test_a_new_ask_replaces_the_last(self):
        self.signoffs.request([self.brief], "feature-explore")
        self.signoffs.sign(self.brief, self.root + self.brief)
        self.signoffs.request([self.spec], "feature-design")
        self.assertIsNone(self.state(self.brief))
        self.assertEqual(self.state(self.spec), "needed")

    def test_claude_hears_once_when_all_are_signed(self):
        self.assertIsNone(self.signoffs.claim_all_signed(self.root))
        self.assertFalse(os.path.exists(self.signoffs.path))  # looking doesn't create the file
        self.signoffs.request([self.spec, self.brief])
        self.signoffs.sign(self.spec, self.root + self.spec)
        self.assertIsNone(self.signoffs.claim_all_signed(self.root))  # one still to go
        self.signoffs.sign(self.brief, self.root + self.brief)
        self.assertEqual(self.signoffs.claim_all_signed(self.root), [self.spec, self.brief])
        self.assertIsNone(self.signoffs.claim_all_signed(self.root))


class SeenTests(TempRepo):
    def test_copies_are_kept_until_comments_are_sent(self):
        store = seen.Seen(worktree.state_paths(self.root).seen)
        spec, url = os.path.join(self.plan, "SPEC.md"), "/docs/plans/retries/SPEC.md"
        self.assertIsNone(store.before(url, spec))  # nothing kept yet
        store.ensure(url, spec)
        write(spec, "# Spec v2\n")
        store.ensure(url, spec)  # doesn't replace the copy
        self.assertEqual(store.before(url, spec), "# Spec\n\n- Five attempts.\n")
        store.mark_all(self.root)
        self.assertIsNone(store.before(url, spec))
        self.assertTrue(store.folder.startswith(os.path.join(self.root, ".git")))


class PageScriptTests(unittest.TestCase):
    page_dir = os.path.join(SCRIPTS, "page")

    def scripts(self):
        return sorted(f for f in os.listdir(self.page_dir) if f.endswith(".js"))

    @unittest.skipUnless(shutil.which("node"), "needs node")
    def test_scripts_parse(self):
        for name in self.scripts():
            with tempfile.NamedTemporaryFile("w", suffix=".mjs", delete=False) as f:
                f.write(read(os.path.join(self.page_dir, name)))
            self.addCleanup(os.remove, f.name)
            result = subprocess.run(["node", "--check", f.name], capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, f"{name}: {result.stderr}")

    def test_every_import_is_exported(self):
        # The page has no build step to catch a renamed or missing export.
        exports = {}
        for name in self.scripts():
            src = read(os.path.join(self.page_dir, name))
            exports[name] = set(re.findall(r"^export (?:async )?(?:function|const|let) ([\w$]+)", src, re.M))
        for name in self.scripts():
            src = read(os.path.join(self.page_dir, name))
            for names, module in re.findall(r"^import \{([^}]+)\} from '\./([\w-]+\.js)';", src, re.M):
                self.assertIn(module, exports, f"{name} imports from missing {module}")
                for wanted in (n.strip() for n in names.split(",")):
                    self.assertIn(wanted, exports[module], f"{name} imports {wanted}, which {module} doesn't export")

    def test_index_loads_files_that_exist(self):
        index = read(os.path.join(self.page_dir, "index.html"))
        for ref in re.findall(r'/__page/([\w.-]+)', index):
            self.assertTrue(os.path.isfile(os.path.join(self.page_dir, ref)), ref)


if __name__ == "__main__":
    unittest.main()
