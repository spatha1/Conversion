-- ============================================================
-- ATP-10963 — Standalone patch for AGGNE.DEV.PM_02
-- Extracted from DEV_SP_POLCIY_CONVERSION_PURE_TO_WRITE_LOAD.sql
-- (the PM_02 CTAS block, lines ~8257-8606), single-quote-unescaped
-- for direct execution — NOT wrapped in the SP's string literal.
--
-- Purpose: run this directly against Snowflake to rebuild PM_02 with
-- the Year/Make/Model/EngineSize/GrossVehicleMass fix, WITHOUT
-- redeploying the entire multi-thousand-line Pure-to-Write SP.
--
-- PREREQUISITE: AGGNE.DEV.PM_01 must already exist and be populated
-- (this script only rebuilds PM_02 from PM_01 — it does not run the
-- earlier steps of the SP that build PM_01).
--
-- Fix location: search "ATP-10963" below — 5 columns changed from
-- key-driven blanking CASE expressions to a straight pass-through.
-- Everything else in this block is byte-identical to the live SP.
-- ============================================================

CREATE OR REPLACE TRANSIENT TABLE AGGNE.DEV.PM_02 AS
SELECT
    PUREPolicyNumber,
	ExpiringID_P,
    insurance_file_cnt,
	CMLNumber,
	ExpiryDate,
	Country,
	Product,
	STATE,
	MotorVehicles_Ind,
	-- Vehicle information
	VehicleID,
	RegistrationNumber,
    --RestrictionOfDriverAge,
	MVRBVehicleKey,
	MVRBGrossVehMass,
	MVRBEngineSize,
	MVCVTypeVeh,

    /* SAS: Clause_Text = UPCASE(CAText); */
    UPPER(CAText) AS Clause_Text,

    /* SAS: Clause_Desc = UPCASE(CADescription); */
    UPPER(CADescription) AS Clause_Desc,

    /* SAS Result_String logic */
    CASE
        WHEN
            POSITION('CM_C06_MODSACCS' IN UPPER(CAText)) > 0
         OR POSITION('ACCESSORIES'     IN UPPER(CAText)) > 0
         OR POSITION('MODIFICATION'    IN UPPER(CAText)) > 0
        THEN
            CASE
                WHEN POSITION('INCLUDES' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(
                        CADescription,
                        POSITION('INCLUDES' IN UPPER(CADescription)) + 8
                    )

                WHEN POSITION('INCLUDE ' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(
                        CADescription,
                        POSITION('INCLUDE ' IN UPPER(CADescription)) + 8
                    )

                WHEN POSITION('INCLUDE:' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(
                        CADescription,
                        POSITION('INCLUDE:' IN UPPER(CADescription)) + 8
                    )

                WHEN POSITION('MODIFICATIONS:' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(
                        CADescription,
                        POSITION('MODIFICATIONS:' IN UPPER(CADescription)) + 14
                    )

                ELSE CADescription
            END
    END AS Result_String,

    /* SAS: IF MVCVProtectionType NE 2 */
    CASE
        WHEN
            (
                POSITION('CM_C06_MODSACCS' IN UPPER(CAText)) > 0
             OR POSITION('ACCESSORIES'     IN UPPER(CAText)) > 0
             OR POSITION('MODIFICATION'    IN UPPER(CAText)) > 0
            )
            AND MVCVProtectionType <> 2
        THEN
            CASE
                WHEN POSITION('INCLUDES' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(CADescription,
                        POSITION('INCLUDES' IN UPPER(CADescription)) + 8)
                WHEN POSITION('INCLUDE ' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(CADescription,
                        POSITION('INCLUDE ' IN UPPER(CADescription)) + 8)
                WHEN POSITION('INCLUDE:' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(CADescription,
                        POSITION('INCLUDE:' IN UPPER(CADescription)) + 8)
                WHEN POSITION('MODIFICATIONS:' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(CADescription,
                        POSITION('MODIFICATIONS:' IN UPPER(CADescription)) + 14)
                ELSE CADescription
            END
    END AS MarketValueDescription,

    CASE
        WHEN
            (
                POSITION('CM_C06_MODSACCS' IN UPPER(CAText)) > 0
             OR POSITION('ACCESSORIES'     IN UPPER(CAText)) > 0
             OR POSITION('MODIFICATION'    IN UPPER(CAText)) > 0
            )
            AND MVCVProtectionType <> 2
        THEN 'Yes'
    END AS MVAddAccOrMods,

    /* SAS: IF MVCVProtectionType = 2 */
    CASE
        WHEN
            (
                POSITION('CM_C06_MODSACCS' IN UPPER(CAText)) > 0
             OR POSITION('ACCESSORIES'     IN UPPER(CAText)) > 0
             OR POSITION('MODIFICATION'    IN UPPER(CAText)) > 0
            )
            AND MVCVProtectionType = 2
        THEN
            CASE
                WHEN POSITION('INCLUDES' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(CADescription,
                        POSITION('INCLUDES' IN UPPER(CADescription)) + 8)
                WHEN POSITION('INCLUDE ' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(CADescription,
                        POSITION('INCLUDE ' IN UPPER(CADescription)) + 8)
                WHEN POSITION('INCLUDE:' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(CADescription,
                        POSITION('INCLUDE:' IN UPPER(CADescription)) + 8)
                WHEN POSITION('MODIFICATIONS:' IN UPPER(CADescription)) > 0
                    THEN SUBSTR(CADescription,
                        POSITION('MODIFICATIONS:' IN UPPER(CADescription)) + 14)
                ELSE CADescription
            END
    END AS AgreedValueDescription,

    CASE
        WHEN
            (
                POSITION('CM_C06_MODSACCS' IN UPPER(CAText)) > 0
             OR POSITION('ACCESSORIES'     IN UPPER(CAText)) > 0
             OR POSITION('MODIFICATION'    IN UPPER(CAText)) > 0
            )
            AND MVCVProtectionType = 2
        THEN 'Yes'
    END AS AVAddAccOrMods,

    /* IF MVRBVehicleKey = '' THEN Override = 'Yes'; */
    CASE
        WHEN MVRBVehicleKey = '' THEN 'Yes'
        ELSE Override
    END AS Override,

    /* IF Override = 'Yes' AND MVCVProtectionType NE 2
       AND MVValueWithoutAccessories = . */
    CASE
        WHEN
            (CASE
                WHEN MVRBVehicleKey = '' THEN 'Yes'
                ELSE Override
             END) = 'Yes'
            AND MVCVProtectionType <> 2
            AND MVValueWithoutAccessories IS NULL
        THEN MVCVMarketValue
        ELSE MVValueWithoutAccessories
    END AS MVValueWithoutAccessories,
    CASE MVRBVehicleKey
        WHEN 'AUVTOYO1994AEGZ' THEN 'Heavy Commercial'
        WHEN 'AUVISUZ2009AEDN' THEN 'Heavy Commercial'
        WHEN 'AUVFORD2009AEIU' THEN 'Light Commercial'
        WHEN 'AUVTOYO2001AEIZ' THEN 'Heavy Commercial'
        WHEN 'AUVISUZ2006AECF' THEN 'Heavy Commercial'
        WHEN 'AUVTOYO2001AEID' THEN 'Light Commercial'
        WHEN 'NZVMERC2002AEEX' THEN 'Light Commercial'
        WHEN 'AUVFUSO2013AEDU' THEN 'Heavy Commercial'
        WHEN 'AUVVOLK2006AEIL' THEN 'Light Commercial'
        WHEN 'AUVTOYO2005AEGO' THEN 'Light Commercial'
        WHEN 'AUVVOLK2008AEHM' THEN 'Light Commercial'
        WHEN 'AUVTOYO2011AECU' THEN 'Light Commercial'
        WHEN 'AUVHOLD1991AECN' THEN 'Passenger Vehicle'
        WHEN 'AUVMERC2017AEKY' THEN 'Passenger Vehicle'
        WHEN 'AUVGWM_2021AEAC' THEN 'Light Commercial'
        WHEN 'AUVFIAT2018AEAR' THEN 'Light Commercial'
        WHEN 'AUVLDV_2020AEAM' THEN 'Light Commercial'
        WHEN 'AUVTOYO2021AEBK' THEN 'Light Commercial'
        WHEN 'AUVTOYO2010AELH' THEN 'Light Commercial'
        WHEN 'AUVNISS2023AEAS' THEN 'Light Commercial'
        ELSE VehicleType  -- preserve existing value if no match
    END AS VehicleType,

    -- Recalculate BodyType if blank after the above assignment
    CASE
        WHEN Override = 'Yes' AND MVCVOverride = 0 AND (MVCVBodyType IS NULL OR MVCVBodyType = '') THEN
            CASE
                WHEN UPPER(Make) = 'FORD'       AND UPPER(Model) = 'RANGER'              THEN 'Utility'
                WHEN UPPER(Make) = 'FORD'       AND UPPER(Model) = 'TERRIRTORY'          THEN 'Wagon'
                WHEN UPPER(Make) = 'LEXUS'      AND UPPER(Model) = 'NX300'               THEN 'Wagon'
                WHEN UPPER(Make) = 'TOYOTA'     AND UPPER(Model) = 'HIACE'               THEN 'Van'
                WHEN UPPER(Make) = 'TOYOTA'     AND UPPER(Model) = 'CAMRY'               THEN 'Sedan'
                WHEN UPPER(Make) = 'TOYOTA'     AND UPPER(Model) = 'LANDCRUISER PRADO'  THEN 'Wagon'
                WHEN UPPER(Make) = 'BMW'        AND UPPER(Model) = 'X5'                  THEN 'Wagon'
                WHEN UPPER(Make) = 'MAZDA'      AND UPPER(Model) = 'BT-50'               THEN 'Utility'
                WHEN UPPER(Make) = 'MAZDA'      AND UPPER(Model) = 'T4000'               THEN 'Transporter'
                WHEN UPPER(Make) = 'MAZDA'      AND UPPER(Model) = '3'                   THEN 'Hatchback'
                WHEN UPPER(Make) = 'MITSUBISHI' AND UPPER(Model) = 'CANTER'              THEN 'Utility'
                WHEN UPPER(Make) = 'MITSUBISHI' AND UPPER(Model) = 'PAJERO'              THEN 'Wagon'
                WHEN UPPER(Make) = 'SUBARU'     AND UPPER(Model) = 'LIBERTY'             THEN 'Wagon'
                WHEN UPPER(Make) = 'HYUNDAI'    AND UPPER(Model) = 'I30'                 THEN 'Hatchback'
                WHEN UPPER(Make) = 'VOLKSWAGEN' AND UPPER(Model) = 'CADDY'               THEN 'Van'
                WHEN UPPER(Make) = 'MERCEDES'   AND UPPER(Model) = 'AMG-C'               THEN 'Sedan'

                WHEN Override = 'Yes' AND UPPER(Make) = 'MITSUBISHI' AND UPPER(Model) = 'ROSA' THEN 'Bus'
                WHEN Override = 'Yes' AND UPPER(Make) = 'LIFTSMART' AND UPPER(Model) = 'LS-RT35' THEN 'Forklift'
                WHEN Override = 'Yes' AND UPPER(Make) IN ('CAN-AM', 'CANNEM', 'CAN AM', 'CAM AM') THEN 'Motorcycle'
                WHEN Override = 'Yes' AND UPPER(Make) = 'HINO' AND UPPER(Model) = 'RANGER' THEN 'Transporter'
                WHEN Override = 'Yes' AND UPPER(Make) = 'CUSTOM' AND UPPER(Model) = 'BOXTOP TRAILER' THEN 'Trailer'
                WHEN Override = 'Yes' AND UPPER(Make) = 'CUSTOM BUILT' AND UPPER(Model) IN ('TANDEM CAR TRAILER','TANDEM TRAILER') THEN 'Trailer'
                WHEN Override = 'Yes' AND UPPER(Make) = 'CUSTOM' AND UPPER(Model) IN ('TANDEM CAR TRAILER','TANDEM TRAILER') THEN 'Trailer'
                WHEN Override = 'Yes' AND UPPER(Make) = 'KINGS' AND UPPER(Model) = 'TANDEM BOX TRAILER' THEN 'Trailer'
                WHEN Override = 'Yes' AND UPPER(Make) = 'JOHN PAPAS' AND UPPER(Model) = 'FLAT TOP TRAILER' THEN 'Trailer'
                WHEN Override = 'Yes' AND UPPER(Make) = 'E-Z-GO' AND UPPER(Model) = '5161703' THEN 'Trailer'
                WHEN Override = 'Yes' AND UPPER(Make) = 'LOTUS' AND UPPER(Model) = 'CARAVAN TROOPER' THEN 'Caravan'

                WHEN UPPER(Make) = 'MERDEDES-BENZ' AND UPPER(Model) = 'CLK320' THEN 'Coupe'
                WHEN UPPER(Make) = 'MERCEDES-BENZ'
                     AND UPPER(Model) IN ('C-CLASS C250D','260SE') THEN 'Sedan'
                WHEN UPPER(Make) = 'MERCEDES BENZ' AND UPPER(Model) = '300 GD WAGON' THEN 'Wagon'
                WHEN UPPER(Make) = 'EMC' AND UPPER(Model) = 'ELECTRIC CART' THEN 'Utility'
                WHEN UPPER(Make) = 'FORD'
                     AND UPPER(Model) IN ('MUSTANG','GALAXIE COUPE') THEN 'Coupe'
                WHEN UPPER(Make) = 'MAZDA' AND UPPER(Model) = 'RX7' THEN 'Coupe'
                WHEN UPPER(Make) = 'BMW' AND UPPER(Model) = '318I' THEN 'Sedan'
                WHEN UPPER(Make) = 'DODGE'
                     AND UPPER(Model) IN ('RAM','RAM DUAL DIESEL XTRA CAB UTILITY','RAM 3500')
                     THEN 'Utility'

                ELSE MVCVBodyType
            END
        ELSE BodyType
        END AS BodyType,

    -- /* RestrictionOfDriverAge */
        CASE
            WHEN MVCVProtectionType IN (1,2,4)
                 AND RestrictionOfDriverAge = ''
            THEN 'No Restriction'
            ELSE RestrictionOfDriverAge
        END
     AS RestrictionOfDriverAge,

    -- /* VehHaveAnInterestedParty */
        CASE
            WHEN MVCVTPFinInterest = 2 THEN 'No'
            ELSE VehHaveAnInterestedParty
        END
        AS VehHaveAnInterestedParty,

    -- /* MVCVAgreedValue - minimum 2000 */
        CASE
            WHEN MVCVProtectionType = 2
                 AND MVCVAgreedValue < 2000
            THEN 2000
            ELSE MVCVAgreedValue
        END
        AS  MVCVAgreedValue,

    -- /* agreedValueDescriptionValue & AVValueWithoutAccessories - 90% rule */
        CASE
            WHEN MVCVProtectionType = 2
                 AND agreedValueDescriptionValue > (MVCVAgreedValue * 0.9)
            THEN (MVCVAgreedValue * 1.1) * 0.8
            ELSE agreedValueDescriptionValue
        END
        AS agreedValueDescriptionValue,

        CASE
            WHEN MVCVProtectionType = 2
                 AND agreedValueDescriptionValue > (MVCVAgreedValue * 0.9)
            THEN (MVCVAgreedValue * 1.1) - ((MVCVAgreedValue * 1.1) * 0.8)
            WHEN MVCVProtectionType = 2
                 AND AVValueWithoutAccessories IS NULL
            THEN MVCVAgreedValue
            ELSE AVValueWithoutAccessories
        END
        AS AVValueWithoutAccessories,

    -- /* MarketValueDescriptionValue */
        CASE
            WHEN MVCVProtectionType <> 2
                 AND MVAddAccOrMods = 'Yes'
                 AND MarketValueDescriptionValue IS NULL
            THEN 0
            WHEN MVCVProtectionType <> 2
                 AND MVAddAccOrMods = 'No'
            THEN NULL
            ELSE MarketValueDescriptionValue
        END
        AS MarketValueDescriptionValue,

    -- /* AgeOfYoungestRegularDriver */
        CASE
            WHEN AgeOfYoungestRegularDriver < 16 THEN NULL
            ELSE AgeOfYoungestRegularDriver
        END
        AS AgeOfYoungestRegularDriver,

    -- /* Vehicle key present */
    -- ATP-10963 (2026-07-06): legacy SAS rule blanked these fields when a Redbook key
    -- exists, assuming the target system resolves them from the key. Policy team confirmed
    -- DCT uses RedbookCode for market value ONLY, and Year/Make/Model are mandatory vehicle
    -- fields — pass the Pure values through unconditionally. STATUS: drafted, not yet
    -- deployed, client confirmation status to be confirmed before running.
    -- Retired logic, kept for reference:
    --   CASE WHEN MVRBVehicleKey <> '' THEN '' ELSE Make END AS Make,   (same for Model;
    --   Year/EngineSize/GrossVehicleMass were forced to 0)
        Make,
        Model,
        Year,
        EngineSize,
        GrossVehicleMass,
        MarketValueWithAccessoriesAmount,
        Description,
        NumberOfCylinders,
        DriveDescription,
        InductionType,
        ImportFlag,
        ProtectionType,
        MVAddAccOrMods  AS WouldYouLikeToAddAccessoriesOrModifications,
        DetForTheParty  AS AddDetailsForTheInterestedParty,
        ChoiceOfRepair,
        HireCarHireAfterIncident,
        agreedvalueamount,
        ExcessWaiverForGlass,
        VOLUNTARYEXCESS,
        ClausesSelection,
       SelectClauseDescription
FROM PM_01
WHERE MotorVehicles_Ind <> 0
ORDER BY PUREPolicyNumber, RegistrationNumber, RestrictionOfDriverAge;

-- ============================================================
-- After running, PM_03 (which reads FROM PM_02) must also be
-- rebuilt to pick up the fix — see lines 8609-8671 of the source SP
-- for that block (dedup by PUREPolicyNumber/EXPIRINGID_P/VEHICLEID,
-- ROW_NUMBER = 1 by RestrictionOfDriverAge DESC). Not extracted here
-- since it has no changes of its own — just re-run it as-is from the
-- live SP if you rebuild PM_02 standalone.
-- ============================================================
