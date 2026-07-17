# G-46 — PURE Motor-Only protections migrating with Location sections selected

**Status:** Needs investigation before a fix can be drafted (client ticket ATP-10965).

260 of 4,076 policies (6.4%) show both MOTOR_INDICATOR=1 and HB_HC_INDICATOR=1 in PER_FINAL —
suggestive of the complaint but not proof (a policy can legitimately have both Motor and Home
cover). Needs a PURE-side comparison (RLMotorVehicles/RLHomeBuildingsContents risk-selection flags)
against the converted indicators before a root cause is confirmed.
