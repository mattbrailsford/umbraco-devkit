---
type: llm
weight: 2
focus: trace
---
#214 has two asks from the maintainer: guest methods on `IBookingsApi` (small) and room
building in `VenueBuilder` (medium, its shape not settled). Both are work the maintainer
wants done, and nothing in the issue is waiting on anyone. The notes suggest splitting off
room building "as its own decision". This is the decision run, so any open question for
either part is put to the maintainer here, not saved for a later decision.

PASS if the suggestion for #214 treats both parts as work to do now: a yes covering both
(the room builder's shape can be proposed or left to the fix), or a split where both resulting
issues go to ready. If it suggests a split, it names a reason other than size, design still
needed, or doing one part first.

FAIL if it recommends readying only the API part while the room-builder part waits for
separate design, a later decision, or a later issue (for example "add guests now, decide the
test part separately"), or recommends any split whose reason is that one part is smaller,
safer, needs more design, or can be done later.
