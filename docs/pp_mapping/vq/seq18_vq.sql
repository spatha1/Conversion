-- ============================================================
-- Seq 18 (RISK_Building_PM / Motor) — validation pack (READ-ONLY, AGGNE.DEV)
-- Gaps G-01 … G-14 — same pack as PP_FieldMapping_Seq18_Motor.html
-- Run after a fresh PM_01/02/03 build so counts reflect current SP logic.
-- ============================================================

-- G-01 State: what the template's hardcoded NSW is hiding
-- Manuscript check: VehicleInput.State is free text (no dropdown), but the de facto
-- accepted value convention elsewhere in the manuscript (Fleet excess-calc logic) is
-- the 8 AU state/territory codes. NZ has no case in that logic at all.
SELECT STATE, COUNT(*) AS VEHICLES, COUNT(DISTINCT PUREPOLICYNUMBER) AS POLICIES,
       CASE WHEN STATE IN ('ACT','NSW','QLD','VIC','NT','SA','TAS','WA') THEN 'VALID AU CODE'
            WHEN STATE = 'NZ' THEN 'NZ — NO CASE IN MANUSCRIPT, CONFIRM WITH CLIENT'
            WHEN COALESCE(TRIM(STATE),'') = '' THEN 'BLANK'
            ELSE 'UNEXPECTED VALUE' END AS VALUE_CHECK
FROM AGGNE.DEV.PM_03 GROUP BY STATE ORDER BY 2 DESC;

-- G-02 YMM filter: vehicles the view drops
SELECT COUNT(*) AS DROPPED_VEHICLES, COUNT(DISTINCT PUREPOLICYNUMBER) AS POLICIES_AFFECTED
FROM AGGNE.DEV.PM_03
WHERE NOT (YEAR<>0 AND MAKE<>'' AND MODEL<>'');

-- G-03 BodyType vs DCT's 17 valid codes
SELECT BODYTYPE, COUNT(*) AS CNT,
       CASE WHEN BODYTYPE IN ('Bus','Convertible','Coupe','Hatchback','PrimeMover','Sedan',
                              'Utility','Van','Wagon','TowTruck','Transporter','MobilePlant',
                              'Motorcycle','Trailer','CamperVan','Caravan','Forklift')
            THEN 'VALID' WHEN COALESCE(TRIM(BODYTYPE),'')='' THEN 'BLANK (required!)'
            ELSE 'INVALID CODE' END AS DCT_CHECK
FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;

-- G-04 DriveDescription captions vs codes
SELECT DRIVEDESCRIPTION, COUNT(*) AS CNT,
       CASE WHEN DRIVEDESCRIPTION IN ('4wheeldrive','Frontwheeldrive','Rearwheeldrive','N/A')
            THEN 'VALID' WHEN COALESCE(TRIM(DRIVEDESCRIPTION),'')='' THEN 'BLANK'
            ELSE 'CAPTION SENT — INVALID' END AS DCT_CHECK
FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;

-- G-05 NumberOfCylinders zeros
SELECT NUMBEROFCYLINDERS, COUNT(*) AS CNT,
       CASE WHEN TRY_TO_NUMBER(NUMBEROFCYLINDERS) BETWEEN 1 AND 16 THEN 'VALID'
            ELSE 'INVALID (0/blank/other)' END AS DCT_CHECK
FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;

-- G-06 InductionType unmapped / blanks
SELECT T1.INDUCTIONTYPE AS PM03_VALUE, COUNT(*) AS CNT,
       CASE WHEN T1.INDUCTIONTYPE IN ('Aspirated','Supercharged','Turbocharged') THEN 'MAPS OK'
            WHEN T1.INDUCTIONTYPE = 'Turbo and supercharged' THEN 'UNMAPPED — view blanks it'
            WHEN COALESCE(TRIM(T1.INDUCTIONTYPE),'')='' THEN 'BLANK AT SOURCE'
            ELSE 'UNEXPECTED VALUE' END AS VIEW_CHECK
FROM AGGNE.DEV.PM_03 T1 GROUP BY 1 ORDER BY 2 DESC;

-- G-07 VoluntaryExcess outside PP options
SELECT VOLUNTARYEXCESS, COUNT(*) AS CNT,
       CASE WHEN VOLUNTARYEXCESS IN ('0','250','500','750','1000','1250','1500')
            THEN 'VALID' ELSE 'INVALID PP OPTION' END AS DCT_CHECK
FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;

-- G-08 Rego format violations
SELECT COUNT(*) AS BAD_REGO
FROM AGGNE.DEV.PER_COM_PAYLOAD
WHERE NOT REGEXP_LIKE(COALESCE(REGISTRATIONNUMBER,''), '^[A-Z0-9]*$');

-- G-09 ImportType trailing space / blanks (bracketed for visibility)
SELECT '['||IMPORTFLAG||']' AS VALUE_BRACKETED, COUNT(*) AS CNT
FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;

-- G-10 EngineSize / GVM zero-or-blank (required fields)
SELECT COUNT(*) AS TOTAL,
  SUM(CASE WHEN COALESCE(TRIM(ENGINESIZE),'')='' OR ENGINESIZE='0' THEN 1 ELSE 0 END) AS ENGINESIZE_ZERO_BLANK,
  SUM(CASE WHEN COALESCE(TRIM(GROSSVEHICLEMASS),'')='' OR GROSSVEHICLEMASS='0' THEN 1 ELSE 0 END) AS GVM_ZERO_BLANK,
  SUM(CASE WHEN VEHICLETYPE IN ('Trailer','Caravan','CamperVan','MobileEquipment','Forklift') THEN 1 ELSE 0 END) AS ENGINELESS_TYPES
FROM AGGNE.DEV.PER_COM_PAYLOAD;

-- G-11 AgeOfYoungestRegularDriver blanks
SELECT COUNT(*) AS TOTAL,
  SUM(CASE WHEN COALESCE(TRIM(AGEOFYOUNGESTREGULARDRIVER),'')='' THEN 1 ELSE 0 END) AS AGE_BLANK
FROM AGGNE.DEV.PER_COM_PAYLOAD;

-- G-12 VehicleType off-list + blank defaults
SELECT VEHICLETYPE, COUNT(*) AS CNT,
       CASE WHEN VEHICLETYPE IN ('PassengerVehicle','CamperVan','Caravan','Forklift','Motorcycle',
                                 'MobileEquipment','TowTruck','Tractor','Trailer','Transporter',
                                 'HeavyVehicle','LightCommercial','HeavyCommercial')
            THEN 'VALID' ELSE 'RAW PASSTHROUGH — INVALID' END AS DCT_CHECK
FROM AGGNE.DEV.PER_COM_PAYLOAD GROUP BY 1 ORDER BY 2 DESC;

-- G-13 RedbookCode carried but never emitted
SELECT COUNT(*) AS TOTAL,
  SUM(CASE WHEN COALESCE(TRIM(MVRBVEHICLEKEY),'') <> '' THEN 1 ELSE 0 END) AS HAS_REDBOOK_KEY
FROM AGGNE.DEV.PER_COM_PAYLOAD;

-- G-14 superseded by seq 17 G-38 — see seq17_vq.sql
