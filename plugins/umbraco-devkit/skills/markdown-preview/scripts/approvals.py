"""Approvals: the reader approving a doc, as a PR is approved on GitHub.

A step asks for approval on the docs it owns (feature-design: SPEC.md and ARCHITECTURE.md),
replacing whatever the last step asked for. The reader signs each off on the page; only the
reader can. An approval holds for the doc as it was approved: once the doc changes, it's stale
and wanted again. When every doc asked for is approved, Claude's waiting helper hears it
once.

Stored as {"step", "requested": [paths], "approved": {path: {"hash", "at"}}, "told": bool}.
"""
import hashlib

from store import JsonStore, now


def file_hash(full):
    with open(full, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


class Approvals(JsonStore):
    empty = dict

    def request(self, paths, step=None):
        def request(data):
            data.clear()
            data.update(step=step, requested=list(paths), approved={}, told=False)
        self.change(request)

    def approve(self, path, full):
        def approve(data):
            if path not in data.get("requested", []):
                raise ValueError("no approval was asked for on this doc")
            data["approved"][path] = {"hash": file_hash(full), "at": now()}
        self.change(approve)

    def state(self, path, full, data=None):
        """None if no approval is asked for; else "needed", "approved" or "changed" (approved,
        then changed since), with when it was approved."""
        data = self.load() if data is None else data
        if path not in data.get("requested", []):
            return None, None
        approved = data["approved"].get(path)
        if not approved:
            return "needed", None
        try:
            same = file_hash(full) == approved["hash"]
        except FileNotFoundError:
            same = False
        return ("approved" if same else "changed"), approved["at"]

    def states(self, root):
        """Every doc asked for, with its state: [(path, state, approved at)]."""
        data = self.load()
        return [(p, *self.state(p, root + p, data)) for p in data.get("requested", [])]

    def claim_all_approved(self, root):
        """Once every doc asked for is approved (and unchanged), say so, the first time only."""
        def claim(data):
            requested = data.get("requested", [])
            if not requested or data.get("told"):
                return None
            if any(self.state(p, root + p, data)[0] != "approved" for p in requested):
                return None
            data["told"] = True
            return requested
        if not self.load().get("requested"):
            return None  # don't create the file just to look
        return self.change(claim)
