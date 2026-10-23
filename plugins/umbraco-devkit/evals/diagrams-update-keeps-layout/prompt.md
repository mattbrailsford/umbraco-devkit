---
description: Updating an existing flow diagram for a change marks the added parts with a key and leaves every existing box where it was.
tags: [diagrams, should-trigger]
# covers: []
max_turns: 30
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit]
---

The signed-resend feature is built. Update
`docs/plans/signed-resend/diagrams/delivery-flow.svg` so it shows the delivery flow with
signing and Resend in it, and change the line under it in `ARCHITECTURE.md` to match. The
diagram goes in the PR description for reviewers.
