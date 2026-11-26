"""Approvals: the reader approving a doc, as a PR is approved on GitHub.

A step asks for approval on the docs it owns (feature-design: SPEC.md and ARCHITECTURE.md).
Asks are kept per folder: a new ask replaces the last one for the same folder (the plan
folder) and leaves other folders' asks alone, so two features in review on one worktree each
keep theirs. The reader signs each doc off on the page; only the reader can. An approval holds
for the doc as it was approved: once the doc changes, it's stale and wanted again. When every
doc in an ask is approved, Claude's waiting helper hears it once: the helper of the Claude
session that asked.

Stored as {"asks": [{"folder", "step", "session", "requested": [paths],
"approved": {path: {"hash", "at"}}, "told": bool}]}. A file from before asks were kept per
folder holds one ask at the top level, and reads as that one ask.
"""
import hashlib
import posixpath

from store import JsonStore, now


def file_hash(full):
    with open(full, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def folder_of(paths):
    """The folder an ask covers: the deepest one holding all its docs, ending in "/"."""
    return posixpath.commonpath([posixpath.dirname(p) for p in paths]).rstrip("/") + "/"


def asks(data):
    """Every ask in the stored data, reading the older one-ask file as a list of one. Changes
    to the returned asks change `data`."""
    if "requested" in data:  # the older shape: move it into the list, in place
        old = {k: data.pop(k) for k in list(data)}
        old["folder"] = folder_of(old["requested"]) if old["requested"] else "/"
        data["asks"] = [old] if old["requested"] else []
    return data.setdefault("asks", [])


def ask_for(data, path):
    """The ask that covers this doc, or None."""
    return next((a for a in asks(data) if path in a["requested"]), None)


class Approvals(JsonStore):
    empty = dict

    def request(self, paths, step=None, session=""):
        folder = folder_of(paths)

        def request(data):
            listed = asks(data)
            # Replace the folder's last ask, and take this ask's docs out of any other.
            kept = []
            for a in listed:
                if a["folder"] == folder:
                    continue
                a["requested"] = [p for p in a["requested"] if p not in paths]
                if a["requested"]:
                    kept.append(a)
            kept.append(dict(folder=folder, step=step, session=session, requested=list(paths),
                             approved={}, told=False))
            listed[:] = kept
        self.change(request)

    def approve(self, path, full):
        def approve(data):
            ask = ask_for(data, path)
            if not ask:
                raise ValueError("no approval was asked for on this doc")
            ask["approved"][path] = {"hash": file_hash(full), "at": now()}
        self.change(approve)

    def state(self, path, full, data=None):
        """None if no approval is asked for; else "needed", "approved" or "changed" (approved,
        then changed since), with when it was approved."""
        data = self.load() if data is None else data
        ask = ask_for(data, path)
        if not ask:
            return None, None
        approved = ask["approved"].get(path)
        if not approved:
            return "needed", None
        try:
            same = file_hash(full) == approved["hash"]
        except FileNotFoundError:
            same = False
        return ("approved" if same else "changed"), approved["at"]

    def states(self, root, under="/"):
        """Every doc asked for under a folder, with its state: [(path, state, approved at)]."""
        data = self.load()
        return [(p, *self.state(p, root + p, data))
                for a in asks(data) for p in a["requested"] if p.startswith(under)]

    def claim_all_approved(self, root, session=""):
        """Once every doc in one of this session's asks is approved (and unchanged), tell the
        session, the first time only. Returns that ask's docs."""
        def waiting(data):
            return [a for a in asks(data) if not a.get("told") and a.get("session", "") in ("", session)]

        def claim(data):
            for ask in waiting(data):
                if all(self.state(p, root + p, data)[0] == "approved" for p in ask["requested"]):
                    ask["told"] = True
                    return ask["requested"]
            return None
        if not waiting(self.load()):
            return None  # don't create or rewrite the file just to look
        return self.change(claim)
