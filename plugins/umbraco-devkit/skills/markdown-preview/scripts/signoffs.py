"""Sign-offs: the reader approving a doc, as a PR is approved on GitHub.

A step asks for sign-off on the docs it owns (feature-design: SPEC.md and ARCHITECTURE.md),
replacing whatever the last step asked for. The reader signs each off on the page; only the
reader can. A sign-off holds for the doc as it was signed: once the doc changes, it's stale
and wanted again. When every doc asked for is signed off, Claude's waiting helper hears it
once.

Stored as {"step", "requested": [paths], "signed": {path: {"hash", "at"}}, "told": bool}.
"""
import hashlib

from store import JsonStore, now


def file_hash(full):
    with open(full, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


class SignOffs(JsonStore):
    empty = dict

    def request(self, paths, step=None):
        def request(data):
            data.clear()
            data.update(step=step, requested=list(paths), signed={}, told=False)
        self.change(request)

    def sign(self, path, full):
        def sign(data):
            if path not in data.get("requested", []):
                raise ValueError("no sign-off was asked for on this doc")
            data["signed"][path] = {"hash": file_hash(full), "at": now()}
        self.change(sign)

    def state(self, path, full, data=None):
        """None if no sign-off is asked for; else "needed", "signed" or "changed" (signed, then
        changed since), with when it was signed."""
        data = self.load() if data is None else data
        if path not in data.get("requested", []):
            return None, None
        signed = data["signed"].get(path)
        if not signed:
            return "needed", None
        try:
            same = file_hash(full) == signed["hash"]
        except FileNotFoundError:
            same = False
        return ("signed" if same else "changed"), signed["at"]

    def states(self, root):
        """Every doc asked for, with its state: [(path, state, signed at)]."""
        data = self.load()
        return [(p, *self.state(p, root + p, data)) for p in data.get("requested", [])]

    def claim_all_signed(self, root):
        """Once every doc asked for is signed off (and unchanged), say so, the first time only."""
        def claim(data):
            requested = data.get("requested", [])
            if not requested or data.get("told"):
                return None
            if any(self.state(p, root + p, data)[0] != "signed" for p in requested):
                return None
            data["told"] = True
            return requested
        if not self.load().get("requested"):
            return None  # don't create the file just to look
        return self.change(claim)
