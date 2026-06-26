create or replace view POLICY_ATTACH_SECONDARYCONTACT(
	CMLNUMBER,
	SECONDARYCONTACT
) as
WITH cte AS (

    -- Secondary Contact Name
    SELECT
        TRIM(a.cmlnumber) AS cmlnumber,
        'secondarycontact_Name' AS TYPE,
        LISTAGG(distinct LEFT(TRIM(a.secondarycontact), 50), ',')
             AS Value
    FROM AGGNE.DEV.T_CML_OTHERCONTACTS_OUT a
    WHERE TRIM(a.secondarycontact) IS NOT NULL
      AND TRIM(a.secondarycontact) <> ''
      AND NOT EXISTS (
          SELECT 1
          FROM AGGNE.DEV.T_CMLMAINDETAILS m
          WHERE TRIM(m.cmlnumber) = TRIM(a.cmlnumber)
            AND UPPER(TRIM(m.maincontact)) = UPPER(TRIM(a.secondarycontact))
      )
    GROUP BY TRIM(a.cmlnumber)

    UNION ALL

    -- Secondary Email
    SELECT
        TRIM(a.cmlnumber) AS cmlnumber,
        'secondarycontact_Email' AS TYPE,
        LISTAGG(distinct TRIM(a.EMAIL), ',') AS Value
    FROM AGGNE.DEV.T_CML_OTHEREMAIL_OUT a
    WHERE TRIM(a.EMAIL) IS NOT NULL
      AND TRIM(a.EMAIL) <> ''
      AND NOT EXISTS (
          SELECT 1
          FROM AGGNE.DEV.T_CML_MAINEMAIL p
          WHERE TRIM(p.cmlnumber) = TRIM(a.cmlnumber)
            AND UPPER(TRIM(p.EMAIL)) = UPPER(TRIM(a.EMAIL))
      )
    GROUP BY TRIM(a.cmlnumber)

    UNION ALL

    -- Secondary Phone
    SELECT
        TRIM(a.cmlnumber) AS cmlnumber,
        'secondarycontact_Phone' AS TYPE,
        LISTAGG(distinct TRIM(a.number), ',')              AS Value
    FROM AGGNE.DEV.T_CML_OTHERPHONE_OUT a
    LEFT JOIN AGGNE.DEV.T_CML_MAINPHONE d
        ON TRIM(a.cmlnumber) = TRIM(d.cmlnumber)
    WHERE TRIM(a.number) IS NOT NULL
      AND TRIM(a.number) <> ''
      AND (d.number IS NULL OR TRIM(a.number) <> TRIM(d.number))
    GROUP BY TRIM(a.cmlnumber)
),

-- ✅ Get only one row per cmlnumber
base AS (
    SELECT DISTINCT cmlnumber
    FROM cte
)

SELECT
    b.cmlnumber,
    '<Contact>
        <AdditionalContactInfo>
            <Name>' || COALESCE(t2.Value, '') || '</Name>
            <Email>' || COALESCE(t3.Value, '') || '</Email>
            <Phone>' || COALESCE(t4.Value, '') || '</Phone>
        </AdditionalContactInfo>
     </Contact>' AS SecondaryContact
FROM base b
LEFT JOIN cte t2
    ON b.cmlnumber = t2.cmlnumber
   AND t2.TYPE = 'secondarycontact_Name'
LEFT JOIN cte t3
    ON b.cmlnumber = t3.cmlnumber
   AND t3.TYPE = 'secondarycontact_Email'
LEFT JOIN cte t4
    ON b.cmlnumber = t4.cmlnumber
   AND t4.TYPE = 'secondarycontact_Phone';