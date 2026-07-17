# G-40 — HC Specified Items Away From the Premises: itemized list missing

**Status:** Sent to PMO (client ticket ATP-11107) — no fix can be drafted until DCT confirms the
target node/shape for a repeating item list.

Source data already exists in `AGGNE.DEV.HC_AWAY` (1,278 items / 495 policies) — once PMO confirms
the destination node, build a new view following the `PER_HC_SPECIFIEDCONTENTS` pattern and wire
it into the seq 13 template.
