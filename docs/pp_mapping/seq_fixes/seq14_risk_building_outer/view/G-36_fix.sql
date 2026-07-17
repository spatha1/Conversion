-- ============================================================
-- G-36 fix — Unmapped construction/security dropdown values pass through raw (seq 14, P2)
-- VIEW: AGGNE.DEV.PER_RISK_BUILDING_FINAL — NO VIEW CHANGE. Validation-report rule only.
-- ============================================================
--
-- LIVE-VERIFIED (2026-07-09): ran the full per-field validity check (Roof/MainWall/Floor/Alarm/
-- Deadlocks/Grills) against AGGNE.DEV.PER_RISK_BUILDING_FINAL — 0 of 1,392 rows currently fall into
-- any ELSE-passthrough branch across all 6 dropdown fields. Every value in today's data is a
-- confirmed-valid DCT code. This is hardening against a FUTURE unmapped value, not a live defect —
-- the view's own comments already correctly flag each ELSE branch as "no DCT PP equivalent, client
-- to confirm" and there's nothing to change in the mapping logic itself.
--
-- ACTION: no view code change. Add this query to the standing validation report (PR-01) so that if
-- Pure ever sends a genuinely new/unmapped value for any of these 6 fields, it's caught and flagged
-- rather than silently forwarded as an invalid DCT code.

SELECT 'ROOF' AS FIELD, ROOFCONSTRUCTION_FINAL AS VALUE, COUNT(*) AS CNT,
       CASE WHEN ROOFCONSTRUCTION_FINAL IN ('Asbestos','Colourbond','Concrete','IronSteelTin','Tile','Wood')
            THEN 'VALID' WHEN COALESCE(TRIM(ROOFCONSTRUCTION_FINAL),'')='' THEN 'BLANK' ELSE 'INVALID' END AS DCT_CHECK
FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL GROUP BY 2

UNION ALL
SELECT 'MAINWALL', MAINWALLCONSTRUCTION_FINAL, COUNT(*),
       CASE WHEN MAINWALLCONSTRUCTION_FINAL IN ('Asbestos','BrickVeneer','Concrete','DoubleBrick','FibroHardiplank','IronSteel','Wood')
            THEN 'VALID' WHEN COALESCE(TRIM(MAINWALLCONSTRUCTION_FINAL),'')='' THEN 'BLANK' ELSE 'INVALID' END
FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL GROUP BY 2

UNION ALL
SELECT 'FLOOR', FLOORCONSTRUCTION_FINAL, COUNT(*),
       CASE WHEN FLOORCONSTRUCTION_FINAL IN ('Concrete','Other','WoodConcretefootings','WoodStilts','WoodStumps')
            THEN 'VALID' WHEN COALESCE(TRIM(FLOORCONSTRUCTION_FINAL),'')='' THEN 'BLANK' ELSE 'INVALID' END
FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL GROUP BY 2

UNION ALL
SELECT 'ALARM', ALARMSYSTEMINSTALLED_FINAL, COUNT(*),
       CASE WHEN ALARMSYSTEMINSTALLED_FINAL IN ('LocalAudibleOnly','MonitoredBacktobase','MonitoredSecurity','MonitoredToMobilePhone','None')
            THEN 'VALID' WHEN COALESCE(TRIM(ALARMSYSTEMINSTALLED_FINAL),'')='' THEN 'BLANK' ELSE 'INVALID' END
FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL GROUP BY 2

UNION ALL
SELECT 'DEADLOCKS', DEADLOCKSINSTALLED_FINAL, COUNT(*),
       CASE WHEN DEADLOCKSINSTALLED_FINAL IN ('AllDoors','SomeDoors','None')
            THEN 'VALID' WHEN COALESCE(TRIM(DEADLOCKSINSTALLED_FINAL),'')='' THEN 'BLANK' ELSE 'INVALID' END
FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL GROUP BY 2

UNION ALL
SELECT 'GRILLS', GRILLKEYLOCKINSTALLED_FINAL, COUNT(*),
       CASE WHEN GRILLKEYLOCKINSTALLED_FINAL IN ('AllWindows','SomeWindows','None')
            THEN 'VALID' WHEN COALESCE(TRIM(GRILLKEYLOCKINSTALLED_FINAL),'')='' THEN 'BLANK' ELSE 'INVALID' END
FROM AGGNE.DEV.PER_RISK_BUILDING_FINAL GROUP BY 2
ORDER BY 1, 3 DESC;

-- Target (2026-07-09 confirmed): 0 'INVALID' rows across all 6 fields. Wire this query (or
-- seq14_vq.sql's equivalent) into the recurring validation report so any future INVALID row gets
-- flagged for a mapping-decision review before it silently reaches DCT.
-- ============================================================
