"""Review comments for one worktree, and every change a comment can go through.

A comment is pinned by the text it's on (plus a little either side), since GitHub's HTML
carries no source line numbers. Its status says whose move it is:

    draft      written on the page, not sent yet
    sent       sent to Claude, not picked up yet
    working    Claude has it
    replied    Claude asked something; waiting on the reader
    addressed  Claude made the change; waiting on the reader's check
    deferred   another step owns the file; left for that step (`owner`)
    resolved   the reader closed it. Only the reader resolves.

The page server and Claude's commands both change the file (see store.py).
"""
from store import JsonStore, now

OPEN = ("draft", "sent", "working", "replied", "addressed", "deferred")


class Comments(JsonStore):
    def update(self, comment_id, fn):
        def update(items):
            for c in items:
                if c["id"] == comment_id:
                    fn(c)
                    return c
            raise KeyError(comment_id)
        return self.change(update)

    # ---------- the reader, on the page ----------

    def add(self, path, quote, body, prefix="", suffix="", section=""):
        def add(items):
            item = {"id": f"c{max([int(c['id'][1:]) for c in items] + [0]) + 1}", "path": path,
                    "quote": quote, "prefix": prefix, "suffix": suffix, "section": section, "body": body,
                    "status": "draft", "replies": [], "created": now()}
            items.append(item)
            return item
        return self.change(add)

    def edit(self, comment_id, body):
        """Change a comment's pending text: the comment itself, or the reply that reopened it."""
        def edit(c):
            if c["status"] != "draft":
                raise ValueError("only a pending comment can be edited")
            if c["replies"] and c["replies"][-1]["author"] == "you":
                c["replies"][-1]["body"] = body
            else:
                c["body"] = body
        return self.update(comment_id, edit)

    def reader_reply(self, comment_id, body):
        """Replying reopens the thread; the reply goes out with the next batch."""
        def reply(c):
            c["replies"].append({"author": "you", "body": body, "created": now()})
            c["status"] = "draft"
        return self.update(comment_id, reply)

    def delete(self, comment_id):
        """Delete a pending comment, or withdraw just a pending reply, keeping the thread before it."""
        def delete(items):
            for i, c in enumerate(items):
                if c["id"] != comment_id:
                    continue
                if c["replies"] and c["replies"][-1]["author"] == "you":
                    c["replies"].pop()
                    c["status"] = "replied"
                else:
                    del items[i]
                return
            raise KeyError(comment_id)
        self.change(delete)

    def resolve(self, comment_id):
        return self.update(comment_id, lambda c: c.update(status="resolved"))

    def send_drafts(self):
        def send(items):
            for c in items:
                if c["status"] == "draft":
                    c["status"] = "sent"
        self.change(send)

    # ---------- Claude, through the commands ----------

    def claim_sent(self):
        """Take the sent batch: mark it as being worked on, and return it."""
        def claim(items):
            batch = [c for c in items if c["status"] == "sent"]
            for c in batch:
                c["status"] = "working"
            return batch
        return self.change(claim)

    def claude_reply(self, comment_id, body, done=False, defer=None, move=None):
        """Claude's answer. `done` hands it to the reader to check; `defer` leaves it for the step
        that owns the file; neither leaves it waiting on the reader's answer. `move` re-pins it to
        the text that replaced what it was on, keeping the first text it was made on."""
        def reply(c):
            c["replies"].append({"author": "claude", "body": body, "created": now()})
            c["status"] = "addressed" if done else "deferred" if defer else "replied"
            c["owner"] = defer
            if move:
                c.setdefault("original", c["quote"])
                c["quote"], c["prefix"], c["suffix"] = move, "", ""
        return self.update(comment_id, reply)

    # ---------- reading ----------

    def on_file(self, path):
        return [c for c in self.load() if c["path"] == path]

    def drafts(self):
        return [c for c in self.load() if c["status"] == "draft"]

    def unresolved(self, under="/"):
        return [c for c in self.load() if c["status"] != "resolved" and c["path"].startswith(under)]

    def open_counts(self):
        counts = {}
        for c in self.unresolved():
            counts[c["path"]] = counts.get(c["path"], 0) + 1
        return counts


# How each status reads to Claude in a listing: whose move it is.
STATUS_NOTE = {
    "draft": "written by the reader but not sent yet",
    "sent": "new, for you", "working": "new, for you", "deferred": "left for {owner}",
    "replied": "waiting on the reader's answer", "addressed": "done, waiting on the reader's check",
}


def describe(items):
    """The listing Claude reads: each comment, where it is, what it says, and the thread so far."""
    lines = []
    for c in items:
        lines.append(f"[{c['id']}] {c['path'].lstrip('/')} ({STATUS_NOTE[c['status']].format(owner=c.get('owner'))})")
        lines.append(f"  on: \"{c['quote']}\"")
        if c.get("original"):
            lines.append(f"  originally on: \"{c['original']}\"")
        if c.get("section"):
            lines.append(f"  in section: {c['section']}")
        lines.append(f"  context: ...{c['prefix']}[{c['quote']}]{c['suffix']}...")
        lines.append(f"  says: {c['body']}")
        if "```suggestion" in c["body"]:
            lines.append("  (has a suggested change: use its wording exactly, keeping the line's own formatting)")
        for r in c["replies"]:
            lines.append(f"  {'Reviewer' if r['author'] == 'you' else 'Claude'} replied: {r['body']}")
    return "\n".join(lines)
