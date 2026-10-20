---
type: llm
weight: 2
focus: trace
---
Context: the real `mc-tier-pill` component (`src/MyCompany.Newsletter.Client/components/tier-pill.element.ts`)
renders a pill with a purple background (`#6a3fd1`), white bold uppercase text, and fully
rounded corners. It's already used this way in the Members list.

PASS if the Topics dashboard mockup's tier/VIP badge for the top subscriber matches this: the
same purple background (that hex or a clearly equivalent purple — not a different hue), white
bold uppercase text, and a pill/fully-rounded shape — showing the real component was read and
reused rather than guessed.

FAIL if the badge uses a different color family (gold, yellow, amber, green, blue, grey,
etc.), a non-pill shape, or if the brief's request for the same tier indicator was dropped or
ignored entirely.
