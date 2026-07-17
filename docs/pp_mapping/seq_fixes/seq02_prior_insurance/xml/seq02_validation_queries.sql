-- ============================================================
-- Seq 2 (priorinsuranceinfo) — validation queries (READ-ONLY, AGGNE.DEV)
-- Gap: G-17 PriorCarrier value form + off-list values (P2)
-- ============================================================

-- G-17: carrier values vs the 13 DCT option values (code form, no spaces for MotorTradeDirect)
SELECT PRIORCARRIER, COUNT(*) AS CNT,
       CASE WHEN PRIORCARRIER IN ('Allianz','CGU','Elders','GIO','MotorTradeDirect','NRMA',
                                  'Other','QBE','SGIC','SGIO','Unknown','VERO','Wesfarmers')
            THEN 'VALID CODE'
            WHEN PRIORCARRIER = 'Motor Trade Direct' THEN 'SPACED FORM — confirm G-17'
            ELSE 'OFF-LIST VALUE' END AS DCT_CHECK
FROM AGGNE.DEV.PER_VW_CBP_COMPETITOR_INFORMATION
GROUP BY PRIORCARRIER ORDER BY CNT DESC;

-- Price sanity
SELECT COUNT(*) AS TOTAL,
       SUM(CASE WHEN PRICE = '0' THEN 1 ELSE 0 END) AS ZERO_PRICE
FROM AGGNE.DEV.PER_VW_CBP_COMPETITOR_INFORMATION;
