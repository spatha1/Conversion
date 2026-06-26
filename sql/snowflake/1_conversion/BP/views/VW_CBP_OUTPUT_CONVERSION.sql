create or replace view VW_CBP_OUTPUT_CONVERSION(
	ID,
	LEGACYPOLICYNUMBER,
	EXPIRINGID_P,
	CMLNUMBER,
	PUREPOLICYNUMBER,
	ABN_NZBN,
	CMLTRADINGNAME,
	CMLLEGALENTITY,
	COUNTRY,
	SITE_SUBURB,
	STATE,
	SITE_POSTCODE,
	POSTCODE,
	SITE_STATE,
	SUBURB,
	SITE_STREET,
	STREET,
	SITE_COUNTRY,
	PRIMARY_PHONE_TYPE,
	CSL_ZONE,
	PRIMARY_PHONE,
	CSL_REGION,
	CSL_AREA_MANAGER,
	STANDARD_INDUSTRY_CODE,
	PHONE,
	CML_LEGAL_ENTITY,
	PRIMARY_EMAIL,
	EMAIL,
	CML_RISK_ACCOUNT_MANAGER,
	MAINCONTACT,
	CSL_CREDIT_LIMIT,
	CSL_MEMBER_STATUS,
	PROBABILITY_OF_DEFAULT,
	STANDARD_INDUSTRY_CODE_DESCRIPTION,
	STOP_CREDIT,
	QU3CRIMINALCONVICTION,
	QU3INSURANCEREFUSEDCANCELLED,
	CRIMINALCONVICTIONDETAILS,
	REFUSEDINSURANCEDETAILS,
	PRIOR_INFO,
	CSLNUMBER,
	PRIMARYRATINGSTATE,
	LINEOFBUSINESS,
	EFFECTIVEDATE,
	EXPIRATIONDATE,
	MEMBERSHIPSYSTEMDATE,
	CHOOSEPROTECTION,
	TIMEZONE,
	EFFECTIVETIME,
	POLICYINCEPTIONDATE,
	BUSINESSESTABLISHMENTDATE,
	SELECTANZSICLOOKUP_NUMBER,
	SELECTANZSICLOOKUP,
	SECONDARYANZSICLOOKUP,
	TURNOVER_LESS_FUEL,
	ISWEBPAGE,
	WEBSITEADDRESS,
	MANAGEMENTPROPRIETORSANDPARTNERS,
	ENGAGEDSALESORWORKSHOPACTIVITIES,
	ISHIGHPERFORMANCE,
	VEHICLETURNOVERDETAILS_PERF,
	VEHICLETURNOVERDISPLAY_PERF,
	ISANTIQUECLASSICCOLLECTOR,
	VEHICLETURNOVERDETAILS_ACC,
	VEHICLETURNOVERDISPLAY_ACC,
	ISWATERCRAFTREPAIR,
	ISWATERWORKPERFORMED,
	VEHICLETURNOVERDETAILS_WATER,
	VEHICLETURNOVERDISPLAY_WATER,
	ISHEAVYTRANSPORTVEHICLES,
	VEHICLETURNOVERDETAILS_HEAVY,
	VEHICLETURNOVERDISPLAY_HEAVY,
	ISPRODUCTSMANUFACTUREDORIMPORTED,
	VEHICLETURNOVERDETAILS_MANIM,
	VEHICLETURNOVERDISPLAY_MANIM,
	ISGEARBOXESRECONDITION,
	VEHICLETURNOVERDETAILS_RECON,
	VEHICLETURNOVERDISPLAY_RECON,
	ISCONSTRUCTIONSERVICES,
	VEHICLETURNOVERDETAILS_CONST,
	VEHICLETURNOVERDISPLAY_CONST,
	ISMININGEQUIPMENTSERVICES,
	ISUNDERGROUNDMINING,
	VEHICLETURNOVERDETAILS_MINE,
	VEHICLETURNOVERDISPLAY_MINE,
	ISSIDELINEBUSINESSENTITY,
	SIDELINEBUSINESSTYPE,
	VEHICLETURNOVERDETAILS_SIDE,
	VEHICLETURNOVERDISPLAY_SIDE,
	DOYOURETAILORMANUFACTURERTYRES,
	TYRESALESPERCENTAGETURNOVER,
	RETREADINGPERCENTAGETURNOVER,
	IMPORTINGTYRESPERCENTAGETURNOVER,
	MANUFACTURINGTYRESPERCTURNOVER,
	SALESOFSECONDHANDPERCTURNOVER,
	HEAVYTRANSPORTTYRESPERCTURNOVER,
	TYRESALESTURNOVERDISPLAY,
	RETREADINGTURNOVERDISPLAY,
	IMPORTINGTYRESTURNOVERDISPLAY,
	MANUFACTURINGTYRESTURNDISPLAY,
	SALESOFSECONDHANDTURNDISPLAY,
	HEAVYTRANSPORTTYRESTURNDISPLAY,
	ISVEHICLETURNOVERMORETHAN30,
	BUSINESSBUILDINGS,
	BUSINESSCONTENTS,
	BURGLARY,
	MONEY,
	ENGINEERING,
	BUSINESSINTERRUPTION,
	GENERALPROPERTY,
	GOODSINTRANSIT,
	PUBLICANDPRODUCTLIABILITY,
	PROFESSIONALPROTECTION,
	LEGALEXPENSES,
	TAXAUDIT,
	COMMERCIALVEHICLES,
	FLEET,
	CUSTOMERVEHICLE,
	STOCKVEHICLES,
	RISK_BUILDING,
	GP,
	PPL,
	PF,
	GT,
	LE,
	SV,
	CV,
	TA,
	RISK_FLEETVEHICLE_PAYLOAD,
	RISK_CM_PAYLOAD,
	AOI,
	PARTY_CML_NUMBER,
	PARTYID,
	ACC_LOC,
	CLAIMS_PAYLOAD,
	LINE_UW,
	MANUSCRIPT,
	COUNTRYCODE,
	CURRENCY,
	LINETYPE,
	COUNTRYTIMEZONE,
	DESCRIPTION,
	ROADTESTPRIME,
	TESTDRIVEROUTES,
	CUSTPRIMESTOV,
	COURTESYTRAILERSSUPPLY,
	DETAILSCOURTESYVEH,
	PERCTOCONSORMINING,
	PERTOVEHSERVICE,
	FRANCHISE,
	RETREADINGMANUFACTURING,
	SALESECHANDTYRES,
	DETAILSNONPASSVEH,
	DETAILSSECHAND,
	TYREFITTEDNONPASSVEH,
	PPLPPCV_EXCESS,
	GPGTLETA_EXCESS,
	PAYMENT_METHOD,
	ALWAYSREFERATRENEWAL,
	UNDERWRITINGDETAILS,
	HANDLERMAIL,
	HANDLERFULLNAME,
	LOAD_DATE
) as
SELECT
    DISTINCT 
    T1.ID,
    TRIM(T1.LEGACYPOLICYNUMBER) AS LEGACYPOLICYNUMBER,
    T1.EXPIRINGID_P,
    CAST(TRIM(T2.CMLNUMBER) AS VARCHAR) AS CMLNUMBER,
    CAST(T1.ID AS VARCHAR) AS PUREPOLICYNUMBER,
    CAST(T2.ABN_NZBN AS VARCHAR) AS ABN_NZBN,
    REPLACE(T2.CMLTRADINGNAME, '&', '&amp;') AS CMLTRADINGNAME,
    REPLACE(T2.CMLLEGALENTITY, '&', '&amp;') AS CMLLEGALENTITY,
    CASE
        WHEN TRIM(T2.COUNTRY) = 'New Zealand' THEN 'NZ'
        WHEN TRIM(T2.COUNTRY) = 'Australia' THEN 'AU'
        ELSE TRIM(T2.COUNTRY)
    END AS COUNTRY,
    T2.SITE_SUBURB,
    T2.STATE,
    T2.SITE_POSTCODE,
    T2.POSTCODE,
    CASE
        WHEN TRIM(T2.COUNTRY) = 'New Zealand' THEN SITE_STATE
        WHEN TRIM(T2.COUNTRY) = 'Australia' THEN CONCAT(SITE_STATE, 'AU')
        ELSE SITE_STATE
    END AS SITE_STATE,
    T2.SUBURB,
    REPLACE(T2.SITE_STREET, '&', '&amp;') AS SITE_STREET,
    REPLACE(T2.STREET, '&', '&amp;') AS STREET,
    CASE
        WHEN TRIM(SITE_COUNTRY) = 'New Zealand' THEN 'NZ'
        WHEN TRIM(SITE_COUNTRY) = 'Australia' THEN 'AU'
        ELSE TRIM(SITE_COUNTRY)
    END AS SITE_COUNTRY,
    T2.PRIMARY_PHONE_TYPE,
    REPLACE(T2.CSL_ZONE, '&', '&amp;') AS CSL_ZONE,
    T2.PRIMARY_PHONE,
    T2.CSL_REGION,
    T2.CSL_AREA_MANAGER,
    T2.STANDARD_INDUSTRY_CODE,
    T2.PHONE,
    REPLACE(T2.CML_LEGAL_ENTITY, '&', '&amp;') AS CML_LEGAL_ENTITY,
    T2.PRIMARY_EMAIL,
    T2.EMAIL,
    T2.CML_RISK_ACCOUNT_MANAGER,
    REPLACE(T2.MAINCONTACT, '&', '&amp;') AS MAINCONTACT,
    T2.CSL_CREDIT_LIMIT,
    T2.CSL_MEMBER_STATUS,
    T2.PROBABILITY_OF_DEFAULT,
    REPLACE(
        T2.STANDARD_INDUSTRY_CODE_DESCRIPTION,
        '&',
        '&amp;'
    ) AS STANDARD_INDUSTRY_CODE_DESCRIPTION,
    T2.STOP_CREDIT,
    case when CRIMINALCONVICTION is null then 'No' else  CRIMINALCONVICTION end AS QU3CRIMINALCONVICTION,
  case when  REFUSEDINSURANCE is null then 'No' else REFUSEDINSURANCE end AS QU3INSURANCEREFUSEDCANCELLED,
   case when CRIMINALCONVICTIONDETAILS  is null then 'No' else CRIMINALCONVICTIONDETAILS end CRIMINALCONVICTIONDETAILS ,
   case when  REFUSEDINSURANCEDETAILS  is null then 'No' else REFUSEDINSURANCEDETAILS end REFUSEDINSURANCEDETAILS ,

    T5.PAYLOAD AS PRIOR_INFO,
    TRIM(T2.CSLNUMBER) as CSLNUMBER,
    TRIM(PRIMARYRATINGSTATE) AS PRIMARYRATINGSTATE,
    'BusinessPackage' as LINEOFBUSINESS,
    TO_CHAR(T1."EFFECTIVEDATE"::DATE, 'YYYY-MM-DD') AS EFFECTIVEDATE,
    TO_CHAR(T1."EXPIRATIONDATE"::DATE, 'YYYY-MM-DD') AS EXPIRATIONDATE,
    TO_CHAR("MEMBERSHIPSYSTEMDATE"::DATE, 'YYYY-MM-DD') AS MEMBERSHIPSYSTEMDATE,
    'BP' AS CHOOSEPROTECTION,
    TIMEZONE,
    EFFECTIVETIME,
    TO_CHAR("POLICYINCEPTIONDATE"::DATE, 'YYYY-MM-DD') AS POLICYINCEPTIONDATE,
    T10.BUSINESSESTABLISHMENTDATE AS BUSINESSESTABLISHMENTDATE,
    CAST(SELECTANZSICLOOKUP AS VARCHAR) as SELECTANZSICLOOKUP_number,
    CASE
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%111111%' THEN '111111 - Property Owners Only'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%222222%' THEN '222222 - Vehicles Only'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%281901%' THEN '281901 - Automotive Component Manufacturing'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%462301%' THEN '462301 - Motor Vehicle New Part and Accessories Wholesaling'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%524502%' THEN '524502 - Boat Dealers - no Manufacturing - including Servicing'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%531103%' THEN '531103 - Agricultural Machinery Dealers - Including Servicing'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%531107%' THEN '531107 - Motor Vehicle Dealers - New - excluding Servicing'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%531108%' THEN '531108 - Motor Vehicle Dealers - New - including Servicing'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%531109%' THEN '531109 - Motor Vehicle Dealers - Used - excluding Servicing'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%531110%' THEN '531110 - Motor Vehicle Dealers - Used - including Servicing'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%531116%' THEN '531116 - Motor Vehicle Wrecking - Used Parts Reseller'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%531301%' THEN '531301 - Motorcycle Dealers - New and Used - including Servicing'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%531302%' THEN '531302 - Trailer and Caravan Dealers'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%532101%' THEN '532101 - Service Station - excluding Servicing'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%532103%' THEN '532103 - Service Station - including Roadhouse - including Servicing'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%532201%' THEN '532201 - Automotive Electrical Services'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%532301%' THEN '532301 - Body/Smash Repair - Bus, Coach, Trucks and Heavy Machinery'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%532302%' THEN '532302 - Body/Smash Repair - Passenger - excluding Bus, Coach, Trucks and Heavy Machinery'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%532401%' THEN '532401 - Tyre Retailers and Repairers - excluding Retreading and Remoulding'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%532504%' THEN '532504 - Automotive Mechanical Repairs - Mobile Mechanic'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%532505%' THEN '532505 - Automotive Mechanical Repairs - Workshop - excluding Smash Repairs'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%532901%' THEN '532901 - Automotive Engine Re-Conditioners'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%532902%' THEN '532902 - Automotive Exhaust and/or Suspension Specialists'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%532903%' THEN '532903 - Automotive Fuel Injection Services'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%532904%' THEN '532904 - Automotive LPG Fitters'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%532905%' THEN '532905 - Automotive Radiator Repairs'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%532908%' THEN '532908 - Automotive Windscreen Installation/Repair'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%532909%' THEN '532909 - Automotive Windscreen Tinting'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%532912%' THEN '532912 - Motor Vehicle Detailers'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%532913%' THEN '532913 - Tow Truck Operator'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%540000%' THEN '540000 - Automotive Fabrication and Engineering'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%540001%' THEN '540001 - Diesel Mechanic'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%540002%' THEN '540002 - Wrecker – Retailer Only'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%540003%' THEN '540003 - Service Station – excluding Roadhouse'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%600001%' THEN '600001 - Auto Masters'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%600002%' THEN '600002 - Ultra-Tune'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%600003%' THEN '600003 - Tyre Franchise'
        WHEN CAST(SELECTANZSICLOOKUP AS VARCHAR) like '%774101%' THEN '774101 - Motor Vehicle Hiring'
        ELSE NULL
    END AS SELECTANZSICLOOKUP,
    SECONDARYANZSICLOOKUP,
    CASE
        WHEN CAST(
            COALESCE(CAST(TURNOVER_LESS_FUEL AS NUMBER(36, 0)), 0) AS VARCHAR
        ) = 0 THEN CAST(CAST(50000 AS NUMBER(5, 0)) AS VARCHAR)
        ELSE CAST(
            CAST(TURNOVER_LESS_FUEL AS NUMBER(36, 0)) AS VARCHAR
        )
    END AS TURNOVER_LESS_FUEL,
    CASE
        WHEN ISWEBPAGE = 'Yes' THEN 1
        ELSE 0
    END AS ISWEBPAGE,
    COALESCE(WEBSITEADDRESS, '') AS WEBSITEADDRESS,
    COALESCE(MANAGEMENTPROPRIETORSANDPARTNERS, '0') AS MANAGEMENTPROPRIETORSANDPARTNERS,
    COALESCE(ENGAGEDSALESORWORKSHOPACTIVITIES, '0') AS ENGAGEDSALESORWORKSHOPACTIVITIES,
    CAST(COALESCE(0, 0) AS VARCHAR) AS ISHIGHPERFORMANCE,
    CAST(CAST(0 AS NUMBER(36, 0)) AS VARCHAR) AS VEHICLETURNOVERDETAILS_PERF,
    VEHICLETURNOVERDISPLAY_PERF,
    CAST(COALESCE(0, 0) AS VARCHAR) AS ISANTIQUECLASSICCOLLECTOR,
    '' AS VEHICLETURNOVERDETAILS_ACC,
    CAST(CAST(0 AS NUMBER(36, 0)) AS VARCHAR) AS VEHICLETURNOVERDISPLAY_ACC,
    CASE
        WHEN ISWATERCRAFTREPAIR = 'Yes' THEN 1
        ELSE 0
    END AS ISWATERCRAFTREPAIR,
    CASE
        WHEN ISWATERWORKPERFORMED = 'Yes' THEN 1
        ELSE 0
    END AS ISWATERWORKPERFORMED,
    CAST(
        CAST(VEHICLETURNOVERDETAILS_WATER AS NUMBER(36, 0)) AS VARCHAR
    ) AS VEHICLETURNOVERDETAILS_WATER,
    VEHICLETURNOVERDISPLAY_WATER,
    CASE
        WHEN ISHEAVYTRANSPORTVEHICLES = 'Yes' THEN 1
        ELSE 0
    END AS ISHEAVYTRANSPORTVEHICLES,
    CAST(
        CAST(VEHICLETURNOVERDETAILS_HEAVY AS NUMBER(36, 0)) AS VARCHAR
    ) AS VEHICLETURNOVERDETAILS_HEAVY,
    VEHICLETURNOVERDISPLAY_HEAVY,
    CASE
        WHEN ISPRODUCTSMANUFACTUREDORIMPORTED = 'Yes' THEN 1
        ELSE 0
    END AS ISPRODUCTSMANUFACTUREDORIMPORTED,
    CAST(
        CAST(VEHICLETURNOVERDETAILS_MANIM AS NUMBER(36, 0)) AS VARCHAR
    ) AS VEHICLETURNOVERDETAILS_MANIM,
    VEHICLETURNOVERDISPLAY_MANIM,
    CASE
        WHEN ISGEARBOXESRECONDITION = 'Yes' THEN 1
        ELSE 0
    END AS ISGEARBOXESRECONDITION,
    CAST(
        CAST(VEHICLETURNOVERDETAILS_RECON AS NUMBER(36, 0)) AS VARCHAR
    ) AS VEHICLETURNOVERDETAILS_RECON,
    VEHICLETURNOVERDISPLAY_RECON,
    CASE
        WHEN ISCONSTRUCTIONSERVICES = 'Yes' THEN 1
        ELSE 0
    END AS ISCONSTRUCTIONSERVICES,
    CAST(
        CAST(VEHICLETURNOVERDETAILS_CONST AS NUMBER(36, 0)) AS VARCHAR
    ) AS VEHICLETURNOVERDETAILS_CONST,
    VEHICLETURNOVERDISPLAY_CONST,
    CASE
        WHEN ISMININGEQUIPMENTSERVICES = 'Yes' THEN 1
        ELSE 0
    END AS ISMININGEQUIPMENTSERVICES,
    CASE
        WHEN ISUNDERGROUNDMINING = 'Yes' THEN 1
        ELSE 0
    END AS ISUNDERGROUNDMINING,
    CAST(
        CAST(VEHICLETURNOVERDETAILS_MINE AS NUMBER(36, 0)) AS VARCHAR
    ) AS VEHICLETURNOVERDETAILS_MINE,
    VEHICLETURNOVERDISPLAY_MINE,
    CASE
        WHEN ISSIDELINEBUSINESSENTITY = 'Yes' THEN 1
        ELSE 0
    END AS ISSIDELINEBUSINESSENTITY,
    SIDELINEBUSINESSTYPE,
    CAST(CAST(0 AS NUMBER(36, 0)) AS VARCHAR) AS VEHICLETURNOVERDETAILS_SIDE,
    VEHICLETURNOVERDISPLAY_SIDE,
    DOYOURETAILORMANUFACTURERTYRES,
    CAST(
        CAST(TYRESALESPERCENTAGETURNOVER AS NUMBER(36, 0)) AS VARCHAR
    ) AS TYRESALESPERCENTAGETURNOVER,
    CAST(
        CAST(RETREADINGPERCENTAGETURNOVER AS NUMBER(36, 0)) AS VARCHAR
    ) AS RETREADINGPERCENTAGETURNOVER,
    CAST(
        CAST(IMPORTINGTYRESPERCENTAGETURNOVER AS NUMBER(36, 0)) AS VARCHAR
    ) AS IMPORTINGTYRESPERCENTAGETURNOVER,
    CAST(
        CAST(MANUFACTURINGTYRESPERCTURNOVER AS NUMBER(36, 0)) AS VARCHAR
    ) AS MANUFACTURINGTYRESPERCTURNOVER,
    CAST(
        CAST(SALESOFSECONDHANDPERCTURNOVER AS NUMBER(36, 0)) AS VARCHAR
    ) AS SALESOFSECONDHANDPERCTURNOVER,
    CAST(
        CAST(HEAVYTRANSPORTTYRESPERCTURNOVER AS NUMBER(36, 0)) AS VARCHAR
    ) AS HEAVYTRANSPORTTYRESPERCTURNOVER,
    TYRESALESTURNOVERDISPLAY,
    RETREADINGTURNOVERDISPLAY,
    IMPORTINGTYRESTURNOVERDISPLAY,
    MANUFACTURINGTYRESTURNDISPLAY,
    SALESOFSECONDHANDTURNDISPLAY,
    HEAVYTRANSPORTTYRESTURNDISPLAY,
    CASE
        WHEN ISVEHICLETURNOVERMORETHAN30 = 'Yes' THEN 1
        ELSE 0
    END AS ISVEHICLETURNOVERMORETHAN30,
    CASE
        WHEN T12.AOI IS NULL THEN 0
        ELSE 1
    END AS BUSINESSBUILDINGS,
    CASE
        WHEN T12.AOI IS NULL THEN 0
        ELSE 1
    END AS BUSINESSCONTENTS,
    CASE
        WHEN T12.AOI IS NULL THEN 0
        ELSE 1
    END AS BURGLARY,
    CASE
        WHEN T12.AOI IS NULL THEN 0
        ELSE 1
    END AS MONEY,
    CASE
        WHEN T12.AOI IS NULL THEN 0
        ELSE 1
    END AS ENGINEERING,
    CASE
        WHEN T12.AOI IS NULL THEN 0
        ELSE 1
    END AS BUSINESSINTERRUPTION,
    CASE
        WHEN T13.PAYLOAD IS NULL THEN 0
        ELSE 1
    END AS GENERALPROPERTY,
    CASE
        WHEN T16.PAYLOAD IS NULL THEN 0
        ELSE 1
    END AS GOODSINTRANSIT,
    CASE
        WHEN T14.PAYLOAD IS NULL THEN 0
        ELSE 1
    END AS PUBLICANDPRODUCTLIABILITY,
    CASE
        WHEN T15.PAYLOAD IS NULL THEN 0
        ELSE 1
    END AS PROFESSIONALPROTECTION,
    CASE
        WHEN T17.PAYLOAD IS NULL THEN 0
        ELSE 1
    END AS LEGALEXPENSES,
    CASE
        WHEN T20.PAYLOAD IS NULL THEN 0
        ELSE 1
    END AS TAXAUDIT,
    CASE
        WHEN T24.CM IS NOT NULL OR T23.FV IS NOT NULL   THEN 1       
        ELSE 0
    END AS COMMERCIALVEHICLES,
    CASE
        WHEN T23.FV IS NULL THEN 0
        ELSE 1
    END AS FLEET,
    CASE
        WHEN T19.PAYLOAD IS NULL THEN 0
        ELSE 1
    END AS CUSTOMERVEHICLE,
    CASE
        WHEN T18.PAYLOAD IS NULL THEN 0
        ELSE 1
    END AS STOCKVEHICLES,
    T12.AOI AS RISK_BUILDING,
    case
        WHEN T13.PAYLOAD IS NULL THEN '<coverage>
	<Type>GeneralProperty</Type>
	<Description>General Property</Description>
	<coverage>
		<Type>FLD_SD</Type>
		<Indicator>0</Indicator>
		<Code>GPFLD_SD</Code>
		<Description>Flood</Description>
		<limit>
			<Type>FLD_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Premium>0</Premium>
	</coverage>
	<Excess>
		<Standard/>
		<Voluntary>0</Voluntary>
		<Imposed/>
	</Excess>
	<coverage>
		<Type>UNT_SD</Type>
		<limit>
			<Type>UNT_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Indicator>0</Indicator>
		<Code>GPUNT_SD</Code>
		<Description>Unspecified Tools</Description>
		<Premium>0</Premium>
	</coverage>
	<coverage>
		<Type>UNS_SD</Type>
		<limit>
			<Type>UNS_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Indicator>0</Indicator>
		<Code>GPUNS_SD</Code>
		<Description>Unspecified Stock</Description>
		<Premium>0</Premium>
	</coverage>
	<coverage>
		<Type>SPT_SD</Type>
		<sValue>NotTaken</sValue>
		<Indicator>0</Indicator>
		<Code>GPSPT_SD</Code>
		<Description>Specified Tools</Description>
		<limit>
			<Type>SPT_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Premium>0</Premium>
	</coverage>
	<Code>GP</Code>
	<Indicator>0</Indicator>
	<SpecifiedTools>
		<Value>0</Value>
		<Description>Apple Mac Laptop</Description>
	</SpecifiedTools>
	<CurrentActiveSpecifiedTools/>
	<ClaimsIncurred>0</ClaimsIncurred>
	<NumberOfClaims>0</NumberOfClaims>
	<Premium>0</Premium>
	<ClassCode>
		<APRA>FISR</APRA>
		<Business>BSP</Business>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>
<Excess>
	<Type>GPGTLETA</Type>
	<Voluntary>0</Voluntary>
	<Imposed/>
	<Standard/>
</Excess>
'
        ELSE T13.PAYLOAD
    END AS GP,
    case
        WHEN T14.PAYLOAD IS NULL THEN '<coverage>
	<Type>PublicProductLiability</Type>
	<Description>Products and Public Liability</Description>
	<Excess>
		<Amount/>
		<Imposed/>
		<Standard>0</Standard>
		<Voluntary/>
	</Excess>
	<SumInsured/>
	<SumInsuredAmountInput>0</SumInsuredAmountInput>
	<coverage>
		<Type>LHA_SD</Type>
		<Indicator>0</Indicator>
		<limit>
			<Type>LHA_SD</Type>
			<iValue>2000</iValue>
		</limit>
		<Code>PPLHA_SD</Code>
		<Description>Assumed Liability Under Hire Agreement</Description>
		<Premium>0</Premium>
	</coverage>
	<coverage>
		<Type>CCA_SD</Type>
		<Indicator>0</Indicator>
		<limit>
			<Type>CCA_SD</Type>
			<iValue/>
		</limit>
		<Code>PPCCA_SD</Code>
		<Description>Consultants, Contractors and Agents</Description>
		<Premium>0</Premium>
	</coverage>
	<coverage>
		<Type>DFW_SD</Type>
		<sValue>Taken</sValue>
		<Indicator>0</Indicator>
		<limit>
			<Type>DFW_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Code>PPDFW_SD</Code>
		<Description>Damage from Faulty Workmanship</Description>
		<Premium>0.010</Premium>
	</coverage>
	<coverage>
		<Type>GHO_SD</Type>
		<Indicator>0</Indicator>
		<limit>
			<Type>GHO_SD</Type>
			<iValue/>
		</limit>
		<Code>PPGHO_SD</Code>
		<Description>Equipment or Goods Hired to Others</Description>
		<Premium>0</Premium>
	</coverage>
	<limit>
		<Type>ProductsandPublicLiabilityLimit</Type>
		<iValue>0</iValue>
	</limit>
	<Code>PP</Code>
	<coverage>
		<Indicator>0</Indicator>
		<Type>POO_SD</Type>
		<Code>PPPOO_SD</Code>
		<Description>Property Owners Only</Description>
		<limit>
			<Type>POO_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Premium>0</Premium>
	</coverage>
	<coverage>
		<Indicator>0</Indicator>
		<sValue>Taken</sValue>
		<Type>RFW_SD</Type>
		<Code>PPRFW_SD</Code>
		<Description>Rectification of Faulty Workmanship</Description>
		<limit>
			<Type>RFW_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Premium>0</Premium>
	</coverage>
	<coverage>
		<Indicator>0</Indicator>
		<Type>RUF_SD</Type>
		<Code>PPRUF_SD</Code>
		<Description>Runoff Liability</Description>
		<limit>
			<Type>RUF_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Premium>0</Premium>
	</coverage>
	<coverage>
		<Indicator>0</Indicator>
		<Type>STB_SD</Type>
		<Code>PPSTB_SD</Code>
		<Description>Public Liability Standard</Description>
		<limit>
			<Type>STB_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Premium>0</Premium>
	</coverage>
	<coverage>
		<Indicator>0</Indicator>
		<Type>STD_SD</Type>
		<Code>PPSTD_SD</Code>
		<Description>Products Liability Standard</Description>
		<limit>
			<Type>STD_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Premium>0</Premium>
	</coverage>
	<coverage>
		<Indicator>0</Indicator>
		<Type>CCC_SD</Type>
		<Code>PPCCC_SD</Code>
		<Description>Property in Your Care Custody or Control</Description>
		<limit>
			<Type>CCC_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Premium>0</Premium>
	</coverage>
	<ProtectionTypeRunoff>0</ProtectionTypeRunoff>
	<ProtectionTypePropertyOwners>0</ProtectionTypePropertyOwners>
	<Indicator>0</Indicator>
	<CoverageLevel>Per Occurrence</CoverageLevel>
	<ProtectionTypeStandard>0</ProtectionTypeStandard>
	<ContractandAgreementUnderwriter>No</ContractandAgreementUnderwriter>
	<Details/>
	<EquipmentGoodsDetails/>
	<ClaimsIncurred>0</ClaimsIncurred>
	<NumberOfClaims>0</NumberOfClaims>
	<Premium>0</Premium>
	<ClassCode>
		<APRA>PPL</APRA>
		<Business>PPL</Business>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>
<Excess>
	<Type>PPLPPCV</Type>
	<Imposed/>
	<Voluntary>0</Voluntary>
	<Standard/>
</Excess>
'
        ELSE T14.PAYLOAD
    END AS PPL,
    case
        WHEN T15.PAYLOAD IS NULL THEN '<coverage>
	<Type>ProfessionalProtection</Type>
	<Description>Professional Protection</Description>
	<coverage>
		<Type>VHB_SD</Type>
		<sValue>NotTaken</sValue>
		<Indicator>0</Indicator>
		<Code>PFVHB_SD</Code>
		<Description>Vehicle Breakdown</Description>
		<limit>
			<Type>VHB_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Premium>0</Premium>
	</coverage>
	<coverage>
		<Type>ROL_SD</Type>
		<sValue>NotTaken</sValue>
		<Indicator>0</Indicator>
		<Code>PFROL_SD</Code>
		<Description>Retroactive Protection</Description>
		<limit>
			<Type>ROL_SD</Type>
			<iValue/>
		</limit>
		<Premium>0</Premium>
	</coverage>
	<Excess>
		<Imposed/>
		<Standard/>
		<Voluntary>0</Voluntary>
	</Excess>
	<Indicator>0</Indicator>
	<coverage>
		<Type>CCA_SD</Type>
		<Indicator>0</Indicator>
		<sValue>NotTaken</sValue>
		<Code>PFCCA_SD</Code>
		<Description>Consultants, Contractors and Agents</Description>
		<limit>
			<Type>CCA_SD</Type>
			<iValue/>
		</limit>
		<Premium>0</Premium>
	</coverage>
	<coverage>
		<Type>CSL_SD</Type>
		<sValue>NotTaken</sValue>
		<Indicator>0</Indicator>
		<Code>PFCSL_SD</Code>
		<Description>Certifications and Slips</Description>
		<limit>
			<Type>CSL_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Premium>0</Premium>
	</coverage>
	<Code>PF</Code>
	<coverage>
		<Indicator>0</Indicator>
		<Type>STD_SD</Type>
		<Code>PFSTD_SD</Code>
		<Description>Standard</Description>
		<limit>
			<Type>STD_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Premium>0</Premium>
	</coverage>
	<limit>
		<Type>VehicleAssessmentLimit</Type>
		<iValue>0</iValue>
	</limit>
	<VehicleAssessmentsAnnualTurnover>0</VehicleAssessmentsAnnualTurnover>
	<VehicleBreakdownAnnualTurnover>0</VehicleBreakdownAnnualTurnover>
	<Details/>
	<Date/>
	<PreviousProfessionalProtection>No</PreviousProfessionalProtection>
	<PreviousEvent>No</PreviousEvent>
	<ClaimsIncurred>0</ClaimsIncurred>
	<NumberOfClaims>0</NumberOfClaims>
	<Premium>0</Premium>
	<ClassCode>
		<APRA>PI</APRA>
		<Business>PI</Business>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage> 
'
        ELSE T15.PAYLOAD
    END AS PF,
    case
        WHEN T16.PAYLOAD IS NULL THEN '<coverage>
	<Type>GoodsInTransit</Type>
	<Description>Goods In Transit</Description>
	<Excess>
		<Standard/>
		<Voluntary>0</Voluntary>
		<Imposed/>
	</Excess>
	<coverage>
		<Type>STD_SD</Type>
		<limit>
			<Type>STD_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Indicator>0</Indicator>
		<Code>GTSTD_SD</Code>
		<Description>Standard</Description>
		<Premium>0</Premium>
	</coverage>
	<EstimatedAnnualValue>0</EstimatedAnnualValue>
	<HazardousGoods>No</HazardousGoods>
	<HazardousGoodsbeingTransported>0</HazardousGoodsbeingTransported>
	<ContentsandStocktransported>0</ContentsandStocktransported>
	<Code>GT</Code>
	<Indicator>0</Indicator>
	<ClaimsIncurred>0</ClaimsIncurred>
	<NumberOfClaims>0</NumberOfClaims>
	<Premium>0</Premium>
	<ClassCode>
		<APRA>MAR</APRA>
		<Business>BSP</Business>
	</ClassCode>
	<ExpirinGTurePremium/>
	<ExpirinGTremium/>
</coverage>
'
        ELSE T16.PAYLOAD
    END AS GT,
    case
        WHEN T17.PAYLOAD IS NULL THEN '<coverage>
	<Type>LegalExpenses</Type>
	<Description>Legal Expenses</Description>
	<Excess>
		<Standard/>
		<Voluntary>0</Voluntary>
		<Imposed/>
	</Excess>
	<coverage>
		<Type>STD_SD</Type>
		<limit>
			<Type>STD_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Indicator>0</Indicator>
		<Code>LESTD_SD</Code>
		<Description>Standard</Description>
		<Premium>0</Premium>
	</coverage>
	<LegalDisputeActions>No</LegalDisputeActions>
	<Redundancies>No</Redundancies>
	<LegalDisputeActionsDetails>0</LegalDisputeActionsDetails>
	<RedundanciesDetails>0</RedundanciesDetails>
	<Code>LE</Code>
	<Indicator>0</Indicator>
	<ClaimsIncurred>0</ClaimsIncurred>
	<NumberOfClaims>0</NumberOfClaims>
	<Premium>0</Premium>
	<ClassCode>
		<APRA>PI</APRA>
		<Business>PROF</Business>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>
'
        ELSE T17.PAYLOAD
    END AS LE,
    case
        WHEN T18.PAYLOAD IS NULL THEN '<coverage>
	<Type>StockVehicles</Type>
	<Description>Stock Vehicles</Description>
	<ProtectionType>FullComprehensive</ProtectionType>
	<limit>
		<Type>LossOrDamageLimit</Type>
		<iValue>0</iValue>
	</limit>
	<Excess>
		<Imposed/>
		<Voluntary>0</Voluntary>
		<Standard/>
		<HailAndMaliciousDamage/>
		<WindscreenAndWindowGlass/>
		<StockVehiclesStolenKeys/>
	</Excess>
	<coverage>
		<Type>GLS_SD</Type>
		<sValue>NotTaken</sValue>
		<Indicator>0</Indicator>
		<Code>SVGLS_SD</Code>
		<Description>Windscreen / Glass</Description>
		<limit>
			<Type>GLS_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Premium>0</Premium>
	</coverage>
	<NumberOfVehiclesWatercraftsHeldAsStockByYou>0</NumberOfVehiclesWatercraftsHeldAsStockByYou>
	<WhatIsTheAverageValueOfTheVehiclesHeldInStock>0</WhatIsTheAverageValueOfTheVehiclesHeldInStock>
	<WhatIsTheMaximumEstimatedValueOfAnySingleVehicle>0</WhatIsTheMaximumEstimatedValueOfAnySingleVehicle>
	<coverage>
		<Type>LIA_SD</Type>
		<limit>
			<Type>LIA_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Indicator>0</Indicator>
		<Code>SVLIA_SD</Code>
		<Description>Comprehensive Liability</Description>
		<Premium>0</Premium>
	</coverage>
	<Code>SV</Code>
	<coverage>
		<Indicator>0</Indicator>
		<Type>STD_SD</Type>
		<Code>SVSTD_SD</Code>
		<Description>Comprehensive Property</Description>
		<limit>
			<Type>STD_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Premium>0</Premium>
	</coverage>
	<coverage>
		<Indicator>0</Indicator>
		<Type>TPO_SD</Type>
		<Code>SVTPO_SD</Code>
		<Description>Third Party Only</Description>
		<limit>
			<Type>TPO_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Premium>0</Premium>
	</coverage>
	<coverage>
		<Indicator>0</Indicator>
		<Type>STD_ST</Type>
		<Code>SVSTD_ST</Code>
		<Description>Storm</Description>
		<limit>
			<Type>STD_ST</Type>
			<iValue>0</iValue>
		</limit>
		<Premium>0</Premium>
	</coverage>
	<Indicator>0</Indicator>
	<DoYouHaveADealersLicense>No</DoYouHaveADealersLicense>
	<UnderwritingAdjustment>
		<Type>StockVehicles</Type>
		<AdjustmentSelection>0</AdjustmentSelection>
		<AdjustmentDollarAndPercent>0</AdjustmentDollarAndPercent>
		<AdjustmentAmount/>
		<Recurring>
			<Indicator>0</Indicator>
		</Recurring>
		<UnderwritingDescription></UnderwritingDescription>
	</UnderwritingAdjustment>
	<UnderwritingAdjustment>
		<Type>StockVehicles</Type>
		<AdjustmentSelection>0</AdjustmentSelection>
		<AdjustmentDollarAndPercent>1963</AdjustmentDollarAndPercent>
		<AdjustmentAmount/>
		<Recurring>
			<Indicator>0</Indicator>
		</Recurring>
		<UnderwritingDescription></UnderwritingDescription>
	</UnderwritingAdjustment>
	<UnderwritingAdjustment>
		<Type>StockVehicles</Type>
		<AdjustmentSelection>0</AdjustmentSelection>
		<AdjustmentDollarAndPercent>0</AdjustmentDollarAndPercent>
		<AdjustmentAmount/>
		<Recurring>
			<Indicator>0</Indicator>
		</Recurring>
		<UnderwritingDescription></UnderwritingDescription>
	</UnderwritingAdjustment>
	<ClaimsIncurred>0</ClaimsIncurred>
	<NumberOfClaims>0</NumberOfClaims>
	<Premium>0</Premium>
	<ClassCode>
		<APRA>DMV</APRA>
		<Business>CMV</Business>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>'
        ELSE T18.PAYLOAD
    END AS SV,
    case
        WHEN T19.PAYLOAD IS NULL THEN '<coverage>
	<Type>CustomerVehicles</Type>
	<Description>Customer Vehicles</Description>
	<Excess>
		<Standard/>
		<Voluntary>0</Voluntary>
		<Imposed/>
		<HailandMaliciousDamage/>
	</Excess>
	<limit>
		<Type>LegalLiability</Type>
		<iValue>0</iValue>
	</limit>
	<coverage>
		<Type>STD_SD</Type>
		<limit>
			<Type>LossorDamageLimit</Type>
			<iValue>0</iValue>
		</limit>
		<Indicator>0</Indicator>
		<Code>CVSTD_SD</Code>
		<Premium>0</Premium>
	</coverage>
	<Code>CV</Code>
	<Indicator>0</Indicator>
	<ClaimsIncurred>0</ClaimsIncurred>
	<NumberOfClaims>0</NumberOfClaims>
	<Premium>0</Premium>
	<ClassCode>
		<APRA>DMV</APRA>
		<Business>CMV</Business>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>'
        ELSE T19.PAYLOAD
    END AS CV,
    case
        WHEN T20.PAYLOAD IS NULL THEN '<coverage>
	<Type>TaxAudit</Type>
	<Description>Tax Audit</Description>
	<ListOfDirector/>
	<PreviousTaxAudit/>
	<SumInsured/>
	<Excess>
		<Standard/>
		<Voluntary>0</Voluntary>
		<Imposed/>
	</Excess>
	<coverage>
		<Type>STD_SD</Type>
		<limit>
			<Type>STD_SD</Type>
			<iValue>0</iValue>
		</limit>
		<Indicator>0</Indicator>
		<Code>TASTD_SD</Code>
		<Description>Standard</Description>
		<Premium>0</Premium>
	</coverage>
	<CoverageLevel>Per Occurrence</CoverageLevel>
	<Code>TA</Code>
	<Indicator>0</Indicator>
	<AustraliaTaxOfficeHasBeenInvestigated>No</AustraliaTaxOfficeHasBeenInvestigated>
	<AustraliaTaxOfficeNotification>No</AustraliaTaxOfficeNotification>
	<Details/>
	<AustraliaTaxOfficeNotificationDetails/>
	<ClaimsIncurred>0</ClaimsIncurred>
	<NumberOfClaims>0</NumberOfClaims>
	<Premium>0</Premium>
	<ClassCode>
		<APRA>OTH</APRA>
		<Business>OACC</Business>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>'
        ELSE T20.PAYLOAD
    END AS TA,
    REPLACE(T23.FV, '&', '&amp;') AS RISK_FLEETVEHICLE_PAYLOAD,
    REPLACE(T24.CM, '&', '&amp;') AS RISK_CM_PAYLOAD,
    REPLACE(T22.AOI, '&', '&amp;') AS AOI,
    T21.CML_NUMBER AS PARTY_CML_NUMBER,
    T21.PARTYID,
    REPLACE(T9.AOI, '&', '&amp;') AS ACC_LOC,
    T4.PAYLOAD AS CLAIMS_PAYLOAD,
    T25.UW AS LINE_UW,
    CASE
        WHEN TRIM(T2.COUNTRY) = 'New Zealand' THEN 'Carrier_BusinessProtection_VM_NZ_1_0_0_0'
        WHEN TRIM(T2.COUNTRY) = 'Australia' THEN 'Carrier_BusinessProtection_VM_AU_1_0_0_0'
        ELSE NULL
    END AS MANUSCRIPT,
    CASE
        WHEN TRIM(T2.COUNTRY) = 'New Zealand' THEN 'NZD'
        WHEN TRIM(T2.COUNTRY) = 'Australia' THEN 'AUD'
        ELSE NULL
    END AS COUNTRYCODE,
    CASE
        WHEN TRIM(T2.COUNTRY) = 'New Zealand' THEN 'en-NZ'
        WHEN TRIM(T2.COUNTRY) = 'Australia' THEN 'en-AU'
        ELSE NULL
    END AS CURRENCY,
    CASE
        WHEN TRIM(T2.COUNTRY) = 'New Zealand' THEN 'SMENZ'
        WHEN TRIM(T2.COUNTRY) = 'Australia' THEN 'SMEAU'
        ELSE NULL
    END AS LINETYPE,
    CASE
        WHEN TRIM(T2.COUNTRY) = 'New Zealand' THEN 'NEWZEASTA'
        WHEN TRIM(T2.COUNTRY) = 'Australia' THEN 'WAUSSTATI'
        ELSE NULL
    END AS COUNTRYTIMEZONE,
    CASE
        WHEN TRIM(T2.COUNTRY) = 'New Zealand' THEN 'Business Protection (NZ)'
        WHEN TRIM(T2.COUNTRY) = 'Australia' THEN 'Business Protection (AUS)'
        ELSE NULL
    END AS DESCRIPTION,
    CASE
        WHEN ROADTESTPRIME = 'TRUE' THEN CAST(CAST(1 AS NUMBER(36, 0)) AS VARCHAR)
        ELSE CAST(CAST(0 AS NUMBER(36, 0)) AS VARCHAR)
    END as ROADTESTPRIME,
    CASE
        WHEN TESTDRIVEROUTES = 'TRUE' THEN CAST(CAST(1 AS NUMBER(36, 0)) AS VARCHAR)
        ELSE CAST(CAST(0 AS NUMBER(36, 0)) AS VARCHAR)
    END as TESTDRIVEROUTES,
    CASE
        WHEN CUSTPRIMESTOV = 'TRUE' THEN CAST(CAST(1 AS NUMBER(36, 0)) AS VARCHAR)
        ELSE CAST(CAST(0 AS NUMBER(36, 0)) AS VARCHAR)
    END as CUSTPRIMESTOV,
    CASE
        WHEN COURTESYTRAILERSSUPPLY = 'TRUE' THEN CAST(CAST(1 AS NUMBER(36, 0)) AS VARCHAR)
        ELSE CAST(CAST(0 AS NUMBER(36, 0)) AS VARCHAR)
    END as COURTESYTRAILERSSUPPLY,
    DETAILSCOURTESYVEH,
    CAST(
        CAST(
            REPLACE(TRIM(PERCTOCONSORMINING), '%', '') AS NUMBER(5, 0)
        ) AS VARCHAR
    ) AS PERCTOCONSORMINING,
    CAST(
        CAST(
            REPLACE(TRIM(PERTOVEHSERVICE), '%', '') AS NUMBER(5, 0)
        ) AS VARCHAR
    ) AS PERTOVEHSERVICE,
    CASE
        WHEN FRANCHISE = 'TRUE' THEN CAST(CAST(1 AS NUMBER(36, 0)) AS VARCHAR)
        ELSE CAST(CAST(0 AS NUMBER(36, 0)) AS VARCHAR)
    END as FRANCHISE,
    CASE
        WHEN RETREADINGMANUFACTURING = 'TRUE' THEN CAST(CAST(1 AS NUMBER(36, 0)) AS VARCHAR)
        ELSE CAST(CAST(0 AS NUMBER(36, 0)) AS VARCHAR)
    END as RETREADINGMANUFACTURING,
    CASE
        WHEN SALESECHANDTYRES = 'TRUE' THEN CAST(CAST(1 AS NUMBER(36, 0)) AS VARCHAR)
        ELSE CAST(CAST(0 AS NUMBER(36, 0)) AS VARCHAR)
    END as SALESECHANDTYRES,
    REPLACE(DETAILSNONPASSVEH, '&', '&amp;') AS DETAILSNONPASSVEH,
    REPLACE(DETAILSSECHAND, '&', '&amp;') AS DETAILSSECHAND,
    CASE
        WHEN TYREFITTEDNONPASSVEH = 'TRUE' THEN CAST(CAST(1 AS NUMBER(36, 0)) AS VARCHAR)
        ELSE CAST(CAST(0 AS NUMBER(36, 0)) AS VARCHAR)
    END as TYREFITTEDNONPASSVEH,
    CAST(
        CAST(
            COALESCE(T26.COMMON_OR_SINGLE_EXCESS, 0) AS NUMBER(5, 0)
        ) AS VARCHAR
    ) AS PPLPPCV_EXCESS,
    CAST(
        CAST(
            COALESCE(T27.COMMON_OR_SINGLE_EXCESS, 0) AS NUMBER(5, 0)
        ) AS VARCHAR
    ) AS GPGTLETA_EXCESS,
    PAYMENT_METHOD,
    case when ALWAYSREFERATRENEWAL= 'Yes' then '1' else '0' end as ALWAYSREFERATRENEWAL, ---yes no
UNDERWRITINGDETAILS, ---
coalesce(trim(T31.ACCOUNTHANDLEREMAIL),'aaron.pang@capricorn.coop') as HANDLERMAIL ,
coalesce(trim(T31.FULLNAME),'Aaron Pang') as HANDLERFULLNAME ,

    GETDATE() AS LOAD_DATE
FROM
    AGGNE.DEV.VW_SAMPLE_FINAL T1
    LEFT JOIN AGGNE.DEV.DIM_PARTY_SNAPSHOT_ACTIVE_INACTIVE_MEMBERS_SCD2 T2 ON TRIM(T1.CMLNUMBER) = TRIM(T2.CMLNUMBER)
    LEFT JOIN AGGNE.DEV.VW_CBP_DUTY_DISCLOSURE T3 ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(PUREPOLICYNUMBER)
    LEFT JOIN AGGNE.DEV.VW_CLAIM_HISTORY_AGG T4 ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T4.ID), '|', 1)
    AND CAST(T4.LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
    LEFT JOIN AGGNE.DEV.VW_COMP_INFO_AGG T5 ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T5.ID)
    AND T5.ITR_TYPE = 'Prior_INFO'
    AND CAST(T5.LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
    LEFT JOIN AGGNE.DEV.ACCOUNT_LOC_AGG T9 ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T9.PUREPOLICYNUMBER)
    AND CAST(T9.LOAD_DATE AS DATE) = CAST(GETDATE() AS DATE)
    LEFT JOIN AGGNE.DEV.VW_BUSINESS_FINAL T10 --SELECT * FROM AGGNE.DEV.VW_BUSINESS_FINAL;
    ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T10.PUREPOLICYNUMBER)
    LEFT JOIN AGGNE.DEV.BUILDING_FINAL_AGG T12 ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T12.PUREPOLICYNUMBER)
    LEFT JOIN AGGNE.DEV.LINE_GP_Target T13 ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T13.ID), '|', 1)
    AND T13.ITR_TYPE = 'BP_LINE_GP'
    LEFT JOIN AGGNE.DEV.LINE_PPL_Target T14 ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T14.ID), '|', 1)     AND T14.ITR_TYPE = 'BP_LINE_PPL'
    LEFT JOIN AGGNE.DEV.LINE_PF_Target T15 ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T15.ID), '|', 1)
    AND T15.ITR_TYPE = 'BP_LINE_PF'
    LEFT JOIN AGGNE.DEV.LINE_GT_Target T16 ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T16.ID), '|', 1)
    AND T16.ITR_TYPE = 'BP_LINE_GT'
    LEFT JOIN AGGNE.DEV.LINE_LE_Target T17 ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T17.ID), '|', 1)
    AND T17.ITR_TYPE = 'BP_LINE_LE'
    LEFT JOIN AGGNE.DEV.LINE_SV_Target T18 ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T18.ID), '|', 1)
    AND T18.ITR_TYPE = 'BP_LINE_SV'
    LEFT JOIN AGGNE.DEV.LINE_CV_Target T19 ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T19.ID), '|', 1)
    AND T19.ITR_TYPE = 'BP_LINE_CV'
    LEFT JOIN AGGNE.DEV.LINE_TA_Target T20 ON TRIM(T1.LEGACYPOLICYNUMBER) = SPLIT_PART(TRIM(T20.ID), '|', 1)
    AND T20.ITR_TYPE = 'BP_LINE_TA'
    LEFT JOIN AGGNE.DEV.VW_MAX_PARTYDET T21 ON T2.CMLNUMBER = T21.CML_NUMBER
    LEFT JOIN AGGNE.DEV.AOI_FINAL_AGG T22 ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T22.PUREPOLICYNUMBER)
    LEFT JOIN AGGNE.DEV.VW_FV T23 ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T23.PUREPOLICYNUMBER)
    LEFT JOIN AGGNE.DEV.VW_CM T24 ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T24.PUREPOLICYNUMBER)
    LEFT JOIN AGGNE.DEV.VW_LINE_UW_COMBINED T25 ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T25.LEGACYPOLICYNUMBER)
    LEFT JOIN AGGNE.DEV.COMMON_EXCESS_PPLPPCV T26 ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T26.PUREPOLICYNUMBER)
    LEFT JOIN AGGNE.DEV.COMMON_EXCESS_GPGTLETA T27 ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T27.PUREPOLICYNUMBER)
    LEFT JOIN AGGNE.DEV.POLICYCONVERSION_PAYMENT_METHOD T28 ON TRIM(T1.EXPIRINGID_P)=TRIM(T28.POLICY_BINDER_ID)
    left join AGGNE.DEV.ManualRef_BSP t29 on trim(t1.LEGACYPOLICYNUMBER)=TRIM(T29.PUREPOLICYNUMBER) and t1.EXPIRINGID_P=t29.EXPIRINGID_P
     LEFT JOIN AGGNE.DEV.ACCOUNT_HANDLER T30 ON TRIM(T1.LEGACYPOLICYNUMBER) = TRIM(T30.PUREPOLICYNUMBER)
    AND T30._IS_CURRENT=TRUE
     LEFT JOIN AGGNE.DEV.VW_ACCOUNT_HANDLER_POLICYTEAM T31 on  trim(lower(t31.ACCOUNTHANDLEREMAIL))  =trim(lower(T30.EMAIL))
-- where

--     TRIM(T1.LEGACYPOLICYNUMBER) in (
--    -- 'P00008691'
--  select  TRIM(LEGACYPOLICYNUMBER)  from AGGNE.UAT.VW_TEST_POLICYCONVERSION_LIST
--     )
-- create view AGGNE.DEV.VW_MAX_PARTYDET as
--     select * from AGGNE.DEV.VW_PARTYDET where (CML_NUMBER,PARTY_DIM_ID) in(
--         select CML_NUMBER ,MAX(PARTY_DIM_ID) from AGGNE.DEV.VW_PARTYDET group by CML_NUMBER
--     )
    ;