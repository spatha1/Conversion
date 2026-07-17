/****** Object:  Table [dbo].[ConversionConfig]    Script Date: 5/15/2026 5:38:24 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ConversionConfig](
	[ConversionConfigId] [int] IDENTITY(1,1) NOT NULL,
	[SequenceID] [int] NOT NULL,
	[ScriptName] [varchar](255) NULL,
	[ConversionSourceTable] [varchar](500) NOT NULL,
	[ConversionTargetTable] [varchar](500) NOT NULL,
	[AttachSourceTable] [varchar](500) NULL,
	[AttachTargetTable] [varchar](500) NULL,
	[ConversionScript] [nvarchar](max) NULL,
	[AttachScript] [nvarchar](max) NULL,
	[IsActive] [bit] NOT NULL,
	[CreatedBy] [sysname] NOT NULL,
	[CreatedOn] [datetime2](3) NOT NULL,
	[ModifiedBy] [sysname] NULL,
	[ModifiedOn] [datetime2](3) NULL,
	[RowVer] [timestamp] NOT NULL,
 CONSTRAINT [PK_ConversionConfig] PRIMARY KEY CLUSTERED 
(
	[ConversionConfigId] ASC
)WITH (STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[ConversionConfig] ON 
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (3, 1, N'BP_ACC_LOC', N'AGGNE.DEV.ACCOUNT_LOC', N'AGGNE.DEV.ACCOUNT_LOC_TARGET', N'AGGNE.DEV.ACCOUNT_LOC_POLICYATTACH', N'AGGNE.DEV.PA_ACCOUNT_LOC_TARGET', N'<location>
	<Number>{RISKNUMBER}</Number>
	<address>
		<State>{STATE}</State>
		<Address1>{ADDRESS1}</Address1>
		<Address2/>
		<City>{SUBURB}</City>
		<ZipCode>{POSTCODE}</ZipCode>
		<Country>{LOC_COUNTRY}</Country>
		<GNAFID>{GNAFPID}</GNAFID>
	</address>
	<Latitude/>
	<Longitude/>
	<PropertyRiskProfile>
		<FloodExtremeRisk/>
		<BushfireExtremeRisk/>
		<CycloneExtremeRisk/>
		<EarthquakeExtremeRisk/>
		<BushfireRate/>
		<CycloneRate/>
		<EarthquakeRate/>
		<StormRate/>
		<BurglaryRate/>
	</PropertyRiskProfile>
	<BusinessType>{LOCATIONANZSICCODE}</BusinessType>
	<LocationType/>
	<AddressOverride>1</AddressOverride>
</location>', N'<location>
	<Number>{RISKNUMBER}</Number>
	<address>
		<State>{STATE}</State>
		<Address1>{ADDRESS1}</Address1>
		<Address2/>
		<City>{SUBURB}</City>
		<ZipCode>{POSTCODE}</ZipCode>
		<Country>{LOC_COUNTRY}</Country>
		<GNAFID>{GNAFPID}</GNAFID>
	</address>
	<Latitude/>
	<Longitude/>
	<PropertyRiskProfile>
		<FloodExtremeRisk/>
		<BushfireExtremeRisk/>
		<CycloneExtremeRisk/>
		<EarthquakeExtremeRisk/>
		<BushfireRate/>
		<CycloneRate/>
		<EarthquakeRate/>
		<StormRate/>
		<BurglaryRate/>
	</PropertyRiskProfile>
	<BusinessType>{LOCATIONANZSICCODE}</BusinessType>
	<LocationType/>
	<AddressOverride>1</AddressOverride>
</location>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-18T07:02:14.5300000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (4, 2, N'BP_Policy_AOI', N'AGGNE.DEV.AOI_FINAL', N'AGGNE.DEV.AOI_Target', N'AGGNE.DEV.PA_AOI_FINAL', N'AGGNE.DEV.PA_AOI_Target', N'<additionalinterestsme>
	<Type>M</Type>
	<TypeDetails>{ADDITIONALINTDETS}</TypeDetails>
	<LocationNumber>{RISKNUMBER}</LocationNumber>
	<AddLocationProperty>{ADDITIONALINTERESTLOC}</AddLocationProperty>
	<LocationProtectionSection>{LOC_VALUE}</LocationProtectionSection>
	<AddLineProtection>{ADDITIONALINTERESTLINE}</AddLineProtection>
	<LineProtectionSection>{LINE_VALUE}</LineProtectionSection>
</additionalinterestsme>', N'<additionalinterestsme>
		<Type>M</Type>
		<TypeDetails>{ADDITIONALINTDETS}</TypeDetails>
		<LocationNumber>{RISKNUMBER}</LocationNumber>
		<AddLocationProperty>{RISKNUMBER}</AddLocationProperty>
		<LocationProtectionSection>{LOC_VALUE}</LocationProtectionSection>
		<AddLineProtection>{ADDITIONALINTERESTLINE}</AddLineProtection>
		<LineProtectionSection>{LINE_VALUE}</LineProtectionSection>
	 </additionalinterestsme>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-18T07:05:53.3550000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (5, 3, N'BP_account_info_claim_history', N'AGGNE.DEV.VW_CLAIM_HISTORY', N'AGGNE.DEV.CLAIM_HISTORY_TARGET', N'AGGNE.DEV.VW_CLAIM_HISTORY_POLICYATTACH', N'AGGNE.DEV.PA_CLAIM_HISTORY_TARGET', N'<losshistory>
<DateOfClaim>{DATEOFCLAIM}</DateOfClaim>
<AmmountPaid>{AMOUNTPAID}</AmmountPaid>
<Line>{LINE}</Line>
<Cause>{CAUSE}</Cause>
<Source>Perf</Source>
</losshistory>', N'<losshistory>
<DateOfClaim>{DATEOFCLAIM}</DateOfClaim>
<AmmountPaid>{AMOUNTPAID}</AmmountPaid>
<Line>{LINE}</Line>
<Cause>{CAUSE}</Cause>
<Source>Perf</Source>
</losshistory>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-18T07:08:40.4720000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (6, 4, N'BP_Prior_INFO', N'AGGNE.DEV.VW_CBP_COMPETITOR_INFORMATION', N'AGGNE.DEV.COMPETITOR_INFORMATION_TARGET', N'AGGNE.DEV.VW_CBP_COMPETITOR_INFORMATION_POLICYATTACH', N'AGGNE.DEV.PA_COMPETITOR_INFORMATION_TARGET', N'<priorinsuranceinfo>
			<PriorCarrier>{PRIORCARRIER}</PriorCarrier>
			<Price>{PRICE}</Price>
		</priorinsuranceinfo>', N'<priorinsuranceinfo>
			<PriorCarrier>{PRIORCARRIER}</PriorCarrier>
			<Price>{PRICE}</Price>
		</priorinsuranceinfo>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-18T07:10:38.2300000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (7, 5, N'BP_Line_GP_1_SpecifiedTools', N'AGGNE.DEV.LINE_GP_SPECIFIEDTOOLS', N'AGGNE.DEV.LINE_GP_Target', N'AGGNE.DEV.PA_LINE_GP_SPECIFIEDTOOLS', N'AGGNE.DEV.PA_LINE_GP_Target', N'<SpecifiedTools>
		<Value>{VALUE}</Value>
		<Description>{DESCRIPTION}</Description>
	</SpecifiedTools>', N'<SpecifiedTools>
		<Value>{VALUE}</Value>
		<Description>{DESCRIPTION}</Description>
	</SpecifiedTools>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-18T07:44:05.4630000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (8, 6, N'BP_Line_GP_2_UW', N'AGGNE.DEV.LINE_GP_UW', N'AGGNE.DEV.LINE_GP_Target', N'AGGNE.DEV.PA_LINE_GP_UW', N'AGGNE.DEV.PA_LINE_GP_Target', N'<UnderwritingAdjustment>
		<Type>GeneralProperty</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	   </Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', N'<UnderwritingAdjustment>
		<Type>GeneralProperty</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	    </Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-18T07:45:48.4640000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (9, 7, N'BP_Line_GP_3_CLAUSE', N'AGGNE.DEV.LINE_GP_CLAUSE', N'AGGNE.DEV.LINE_GP_Target', N'AGGNE.DEV.PA_LINE_GP_CLAUSE', N'AGGNE.DEV.PA_LINE_GP_Target', N'<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	</Clause>', N'<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	 </Clause>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-18T07:47:11.0470000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (10, 8, N'BP_LINE_GP', N'AGGNE.DEV.LINE_GP_PAYLOAD', N'AGGNE.DEV.LINE_GP_Target', N'AGGNE.DEV.PA_LINE_GP_PAYLOAD', N'AGGNE.DEV.PA_LINE_GP_Target', N' 
<coverage>
	<Type>GeneralProperty</Type>
	<Description>General Property</Description>
	<coverage>
		<Type>FLD_SD</Type>
		<Indicator>{FLOODDAMAGE}</Indicator>
		<Code>GPFLD_SD</Code>
		<Description>Flood</Description>
		<limit>
			<Type>FLD_SD</Type>
			<iValue>{GPFLOODPROTECTION}</iValue>
		</limit>
		<Premium>{EXP_PREM_GPFLD_SD}</Premium>
	</coverage>
	<Excess>
		<Standard/>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
		<Imposed/>
	</Excess>
	<coverage>
		<Type>UNT_SD</Type>
		<limit>
			<Type>UNT_SD</Type>
			<iValue>{UNSPECIFIEDTOOLSLIMIT}</iValue>
		</limit>
		<Indicator>1</Indicator>
		<Code>GPUNT_SD</Code>
		<Description>Unspecified Tools</Description>
		<Premium>{EXP_PREM_GPUNT_SD}</Premium>
	</coverage>
	<coverage>
		<Type>UNS_SD</Type>
		<limit>
			<Type>UNS_SD</Type>
			<iValue>{UNSPECIFIEDSTOCKLIMIT}</iValue>
		</limit>
		<Indicator>1</Indicator>
		<Code>GPUNS_SD</Code>
		<Description>Unspecified Stock</Description>
		<Premium>{EXP_PREM_GPUNS_SD}</Premium>
	</coverage>
	<coverage>
		<Type>SPT_SD</Type>
		<sValue>{SPECIFIEDTOOL}</sValue>
		<Indicator>1</Indicator>
		<Code>GPSPT_SD</Code>
		<Description>Specified Tools</Description>
		<limit>
			<Type>SPT_SD</Type>
			<iValue>{GPSPECIFIEDTOOLS}</iValue>
		</limit>
		<Premium>{EXP_PREM_GPSPT_SD}</Premium>
	</coverage>
	<Code>GP</Code>
	<Indicator>{GENERALPROPERTY_IND}</Indicator>    {LINE_GP_CLAUSE}   {LINE_GP_SPECIFIEDTOOLS}   <CurrentActiveSpecifiedTools/>   {LINE_GP_UW}      <ClaimsIncurred>{GPCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{GPCLMCNT}</NumberOfClaims>
	<Premium>{GPEXPPREM}</Premium>
	<ClassCode>
		<APRA>FISR</APRA>
		<Business>BSP</Business>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>
<Excess>
	<Type>GPGTLETA</Type>
	<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
	<Imposed/>
	<Standard/>
</Excess>
', N'<coverage>
	<Type>GeneralProperty</Type>
	<Description>General Property</Description>
	<coverage>
		<Type>FLD_SD</Type>
		<Indicator>{FLOODDAMAGE}</Indicator>
		<Code>GPFLD_SD</Code>
		<Description>Flood</Description>
		<limit>
			<Type>FLD_SD</Type>
			<iValue>{GPFLOODPROTECTION}</iValue>
		</limit>
		<Premium>{EXP_PREM_GPFLD_SD}</Premium>
	</coverage>
	<Excess>
		<Standard>{STANDARDEXCESS}</Standard>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
		<Imposed>{IMPOSEDEXCESS}</Imposed>
	</Excess>
	<coverage>
		<Type>UNT_SD</Type>
		<limit>
			<Type>UNT_SD</Type>
			<iValue>{UNSPECIFIEDTOOLSLIMIT}</iValue>
		</limit>
		<Indicator>{UNSPECIFIEDTOOLSLIMIT_INDICATOR}</Indicator>
		<Code>GPUNT_SD</Code>
		<Description>Unspecified Tools</Description>
		<Premium>{EXP_PREM_GPUNT_SD}</Premium>
	</coverage>
	<coverage>
		<Type>UNS_SD</Type>
		<limit>
			<Type>UNS_SD</Type>
			<iValue>{UNSPECIFIEDSTOCKLIMIT}</iValue>
		</limit>
		<Indicator>{UNSPECIFIEDSTOCKLIMIT_INDICATOR}</Indicator>
		<Code>GPUNS_SD</Code>
		<Description>Unspecified Stock</Description>
		<Premium>{EXP_PREM_GPUNS_SD}</Premium>
	</coverage>
	<coverage>
		<Type>SPT_SD</Type>
		<sValue>{SPECIFIEDTOOL}</sValue>
		<Indicator>{SPECIFIEDTOOL_INDICATOR}</Indicator>
		<Code>GPSPT_SD</Code>
		<Description>Specified Tools</Description>
		<limit>
			<Type>SPT_SD</Type>
			<iValue>{GPSPECIFIEDTOOLS}</iValue>
		</limit>
		<Premium>{EXP_PREM_GPSPT_SD}</Premium>
	</coverage>
	<Code>GP</Code>
	<Indicator>{GENERALPROPERTY_IND}</Indicator>    {LINE_GP_CLAUSE}   {LINE_GP_SPECIFIEDTOOLS}   <CurrentActiveSpecifiedTools/>   {LINE_GP_UW}      <ClaimsIncurred>{GPCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{GPCLMCNT}</NumberOfClaims>
	<Premium>{GPEXPPREM}</Premium>
	<ClassCode>
		<APRA/>
		<Business/>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>
<Excess>
	<Type>GPGTLETA</Type>
	<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
	<Imposed/>
	<Standard/>
</Excess>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-18T07:49:10.9600000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (11, 9, N'BP_Line_PPL_1_UW', N'AGGNE.DEV.LINE_PPL_UW', N'AGGNE.DEV.LINE_PPL_Target', N'AGGNE.DEV.PA_LINE_PPL_UW', N'AGGNE.DEV.PA_LINE_PPL_Target', N'<UnderwritingAdjustment>
		<Type>PublicProductLiability</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	   </Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', N'<UnderwritingAdjustment>
		<Type>PublicProductLiability</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	    </Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-18T07:51:18.0450000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (12, 10, N'BP_Line_PPL_2_CLAUSE', N'AGGNE.DEV.LINE_PPL_CLAUSE', N'AGGNE.DEV.LINE_PPL_Target', N'AGGNE.DEV.PA_LINE_PPL_CLAUSE', N'AGGNE.DEV.PA_LINE_PPL_Target', N'<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	</Clause>', N'<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	 </Clause>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-18T12:11:07.4320000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (13, 11, N'BP_LINE_PPL', N'AGGNE.DEV.LINE_PPL_PAYLOAD', N'AGGNE.DEV.LINE_PPL_Target', N'AGGNE.DEV.PA_LINE_PPL_PAYLOAD', N'AGGNE.DEV.PA_LINE_PPL_Target', N'<coverage>
	<Type>PublicProductLiability</Type>
	<Description>Products and Public Liability</Description>
	<Excess>
		<Amount/>
		<Imposed/>
		<Standard>{VOLUNTARYEXCESS}</Standard>
		<Voluntary/>
	</Excess>
	<SumInsured/>
	<SumInsuredAmountInput>0</SumInsuredAmountInput>
	<coverage>
		<Type>LHA_SD</Type>
		<Indicator>{ASSUMEDLIABILITY}</Indicator>
		<limit>
			<Type>LHA_SD</Type>
			<iValue>{ASSUMEDLIABILITYLIMIT}</iValue>
		</limit>
		<Code>PPLHA_SD</Code>
		<Description>Assumed Liability Under Hire Agreement</Description>
		<Premium>{EXP_PREM_PPLHA_SD}</Premium>
	</coverage>
	<coverage>
		<Type>CCA_SD</Type>
		<Indicator>{CONTRACTANDSUBCON}</Indicator>
		<limit>
			<Type>CCA_SD</Type>
			<iValue>{CONTRACTANDSUBCONLIMIT}</iValue>
		</limit>
		<Code>PPCCA_SD</Code>
		<Description>Consultants, Contractors and Agents</Description>
		<Premium>{EXP_PREM_PPCCA_SD}</Premium>
	</coverage>
	<coverage>
		<Type>DFW_SD</Type>
		<sValue>Taken</sValue>
		<Indicator>1</Indicator>
		<limit>
			<Type>DFW_SD</Type>
			<iValue>{PRODUCTSANDPUBLICLIABILITYLIMIT}</iValue>
		</limit>
		<Code>PPDFW_SD</Code>
		<Description>Damage from Faulty Workmanship</Description>
		<Premium>{EXP_PREM_PPDFW_SD}</Premium>
	</coverage>
	<coverage>
		<Type>GHO_SD</Type>
		<Indicator>{EQUIPMENTGOODS}</Indicator>
		<limit>
			<Type>GHO_SD</Type>
			<iValue>{EQUIPMENTGOODSLIMIT}</iValue>
		</limit>
		<Code>PPGHO_SD</Code>
		<Description>Equipment or Goods Hired to Others</Description>
		<Premium>{EXP_PREM_PPGHO_SD}</Premium>
	</coverage>
	<limit>
		<Type>ProductsandPublicLiabilityLimit</Type>
		<iValue>{PRODUCTSANDPUBLICLIABILITYLIMIT}</iValue>
	</limit>
	<Code>PP</Code>
	<coverage>
		<Indicator>{PROPERTYOWNER}</Indicator>
		<Type>POO_SD</Type>
		<Code>PPPOO_SD</Code>
		<Description>Property Owners Only</Description>
		<limit>
			<Type>POO_SD</Type>
			<iValue>{PROPERTYOWNERSLIABILITYLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_PPPOO_SD}</Premium>
	</coverage>
	<coverage>
		<Indicator>{RECTIFYINGFAULTY}</Indicator>
		<sValue>{RECTIFYINGFAULTY_IND}</sValue>
		<Type>RFW_SD</Type>
		<Code>PPRFW_SD</Code>
		<Description>Rectification of Faulty Workmanship</Description>
		<limit>
			<Type>RFW_SD</Type>
			<iValue>{COSTOFRECTIFYINGLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_PPRFW_SD}</Premium>
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
		<Premium>{EXP_PREM_PPRUF_SD}</Premium>
	</coverage>
	<coverage>
		<Indicator>1</Indicator>
		<Type>STB_SD</Type>
		<Code>PPSTB_SD</Code>
		<Description>Public Liability Standard</Description>
		<limit>
			<Type>STB_SD</Type>
			<iValue>{PRODUCTSANDPUBLICLIABILITYLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_PPSTB_SD}</Premium>
	</coverage>
	<coverage>
		<Indicator>1</Indicator>
		<Type>STD_SD</Type>
		<Code>PPSTD_SD</Code>
		<Description>Products Liability Standard</Description>
		<limit>
			<Type>STD_SD</Type>
			<iValue>{PRODUCTSANDPUBLICLIABILITYLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_PPSTD_SD}</Premium>
	</coverage>
	<coverage>
		<Indicator>1</Indicator>
		<Type>CCC_SD</Type>
		<Code>PPCCC_SD</Code>
		<Description>Property in Your Care Custody or Control</Description>
		<limit>
			<Type>CCC_SD</Type>
			<iValue>{PRODUCTSANDPUBLICLIABILITYLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_PPCCC_SD}</Premium>
	</coverage>
	<ProtectionTypeRunoff>0</ProtectionTypeRunoff>
	<ProtectionTypePropertyOwners>{PROPERTYOWNER}</ProtectionTypePropertyOwners>
	<Indicator>{PRODUCTANDPUBLIC_IND}</Indicator>
	<CoverageLevel>Per Occurrence</CoverageLevel>   {LINE_PPL_CLAUSE}   <ProtectionTypeStandard>1</ProtectionTypeStandard>
	<ContractandAgreementUnderwriter>{CONTRACTANDAGREEMENTUNDERWRITER}</ContractandAgreementUnderwriter>
	<Details>{CONTRACTANDAGREEMENTUNDERWRITER_DETAILS}</Details>
	<EquipmentGoodsDetails>{EQUIPMENTGOODSDETAILS}</EquipmentGoodsDetails>   {LINE_PPL_UW}     <ClaimsIncurred>{PPCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{PPCLMCNT}</NumberOfClaims>
	<Premium>{PPEXPPREM}</Premium>
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
	<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
	<Standard/>
</Excess>
', N'<coverage>
	<Type>PublicProductLiability</Type>
	<Description>Products and Public Liability</Description>
	<Excess>
		<Amount/>
		<Standard>{STANDARDEXCESS}</Standard>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
		<Imposed>{IMPOSEDEXCESS}</Imposed>
	</Excess>
	<SumInsured/>
	<SumInsuredAmountInput>0</SumInsuredAmountInput>
	<coverage>
		<Type>LHA_SD</Type>
		<Indicator>{ASSUMEDLIABILITY}</Indicator>
		<limit>
			<Type>LHA_SD</Type>
			<iValue>{ASSUMEDLIABILITYLIMIT}</iValue>
		</limit>
		<Code>PPLHA_SD</Code>
		<Description>Assumed Liability Under Hire Agreement</Description>
		<Premium>{EXP_PREM_PPLHA_SD}</Premium>
	</coverage>
	<coverage>
		<Type>CCA_SD</Type>
		<Indicator>{CONTRACTANDSUBCON}</Indicator>
		<limit>
			<Type>CCA_SD</Type>
			<iValue>{CONTRACTANDSUBCONLIMIT}</iValue>
		</limit>
		<Code>PPCCA_SD</Code>
		<Description>Consultants, Contractors and Agents</Description>
		<Premium>{EXP_PREM_PPCCA_SD}</Premium>
	</coverage>
	<coverage>
		<Type>DFW_SD</Type>
		<sValue>Taken</sValue>
		<Indicator>1</Indicator>
		<limit>
			<Type>DFW_SD</Type>
			<iValue>{PRODUCTSANDPUBLICLIABILITYLIMIT}</iValue>
		</limit>
		<Code>PPDFW_SD</Code>
		<Description>Damage from Faulty Workmanship</Description>
		<Premium>{EXP_PREM_PPDFW_SD}</Premium>
	</coverage>
	<coverage>
		<Type>GHO_SD</Type>
		<Indicator>{EQUIPMENTGOODS}</Indicator>
		<limit>
			<Type>GHO_SD</Type>
			<iValue>{EQUIPMENTGOODSLIMIT}</iValue>
		</limit>
		<Code>PPGHO_SD</Code>
		<Description>Equipment or Goods Hired to Others</Description>
		<Premium>{EXP_PREM_PPGHO_SD}</Premium>
	</coverage>
	<limit>
		<Type>ProductsandPublicLiabilityLimit</Type>
		<iValue>{PRODUCTSANDPUBLICLIABILITYLIMIT}</iValue>
	</limit>
	<Code>PP</Code>
	<coverage>
		<Indicator>{PROPERTYOWNER}</Indicator>
		<Type>POO_SD</Type>
		<Code>PPPOO_SD</Code>
		<Description>Property Owners Only</Description>
		<limit>
			<Type>POO_SD</Type>
			<iValue>{PROPERTYOWNERSLIABILITYLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_PPPOO_SD}</Premium>
	</coverage>
	<coverage>
		<Indicator>{RECTIFYINGFAULTY}</Indicator>
		<sValue>{RECTIFYINGFAULTY_IND}</sValue>
		<Type>RFW_SD</Type>
		<Code>PPRFW_SD</Code>
		<Description>Rectification of Faulty Workmanship</Description>
		<limit>
			<Type>RFW_SD</Type>
			<iValue>{COSTOFRECTIFYINGLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_PPRFW_SD}</Premium>
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
		<Premium>{EXP_PREM_PPRUF_SD}</Premium>
	</coverage>
	<coverage>
		<Indicator>1</Indicator>
		<Type>STB_SD</Type>
		<Code>PPSTB_SD</Code>
		<Description>Public Liability Standard</Description>
		<limit>
			<Type>STB_SD</Type>
			<iValue>{PRODUCTSANDPUBLICLIABILITYLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_PPSTB_SD}</Premium>
	</coverage>
	<coverage>
		<Indicator>1</Indicator>
		<Type>STD_SD</Type>
		<Code>PPSTD_SD</Code>
		<Description>Products Liability Standard</Description>
		<limit>
			<Type>STD_SD</Type>
			<iValue>{PRODUCTSANDPUBLICLIABILITYLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_PPSTD_SD}</Premium>
	</coverage>
	<coverage>
		<Indicator>1</Indicator>
		<Type>CCC_SD</Type>
		<Code>PPCCC_SD</Code>
		<Description>Property in Your Care Custody or Control</Description>
		<limit>
			<Type>CCC_SD</Type>
			<iValue>{PRODUCTSANDPUBLICLIABILITYLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_PPCCC_SD}</Premium>
	</coverage>
	<ProtectionTypeRunoff>0</ProtectionTypeRunoff>
	<ProtectionTypePropertyOwners>{PROPERTYOWNER}</ProtectionTypePropertyOwners>
	<Indicator>{PRODUCTANDPUBLIC_IND}</Indicator>
	<CoverageLevel>Per Occurrence</CoverageLevel>   {LINE_PPL_CLAUSE}   <ProtectionTypeStandard>1</ProtectionTypeStandard>
	<ContractandAgreementUnderwriter>{CONTRACTANDAGREEMENTUNDERWRITER}</ContractandAgreementUnderwriter>
	<Details>{CONTRACTANDAGREEMENTUNDERWRITER_DETAILS}</Details>
	<EquipmentGoodsDetails>{EQUIPMENTGOODSDETAILS}</EquipmentGoodsDetails>   {LINE_PPL_UW}      <ClaimsIncurred>{PPCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{PPCLMCNT}</NumberOfClaims>
	<Premium>{PPEXPPREM}</Premium>
	<ClassCode>
		<APRA/>
		<Business/>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>
<Excess>
	<Type>PPLPPCV</Type>
	<Imposed/>
	<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
	<Standard/>
</Excess>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T06:12:48.8920000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (14, 12, N'BP_LINE_PF_UW', N'AGGNE.DEV.LINE_PF_UW', N'AGGNE.DEV.LINE_PF_Target', N'AGGNE.DEV.PA_LINE_PF_UW', N'AGGNE.DEV.PA_LINE_PF_Target', N'
   <UnderwritingAdjustment>
		<Type>ProfessionalProtection</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	</Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', N'
   <UnderwritingAdjustment>
		<Type>ProfessionalProtection</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	</Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T06:16:04.7630000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (15, 13, N'BP_LINE_PF_CLAUSE', N'AGGNE.DEV.LINE_PF_CLAUSE', N'AGGNE.DEV.LINE_PF_Target', N'AGGNE.DEV.PA_LINE_PF_CLAUSE', N'AGGNE.DEV.PA_LINE_PF_Target', N'
  <Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	</Clause>', N'
    <Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	 </Clause>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T06:18:20.0910000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (16, 14, N'BP_LINE_PF', N'AGGNE.DEV.LINE_PF_PAYLOAD', N'AGGNE.DEV.LINE_PF_Target', N'AGGNE.DEV.PA_LINE_PF_PAYLOAD', N'AGGNE.DEV.PA_LINE_PF_Target', N'<coverage>
	<Type>ProfessionalProtection</Type>
	<Description>Professional Protection</Description>
	<coverage>
		<Type>VHB_SD</Type>
		<sValue>{VEHBREAK_IND}</sValue>
		<Indicator>{VEHBREAK_INDICATOR}</Indicator>
		<Code>PFVHB_SD</Code>
		<Description>Vehicle Breakdown</Description>
		<limit>
			<Type>VHB_SD</Type>
			<iValue>{PIBREAKDOWNLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_PFVHB_SD}</Premium>
	</coverage>
	<coverage>
		<Type>ROL_SD</Type>
		<sValue>{RETROACTIVE_IND}</sValue>
		<Indicator>{RETROACTIVE_INDICATOR}</Indicator>
		<Code>PFROL_SD</Code>
		<Description>Retroactive Protection</Description>
		<limit>
			<Type>ROL_SD</Type>
			<iValue>{RETROACTIVELIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_PFROL_SD}</Premium>
	</coverage>
	<Excess>
		<Imposed/>
		<Standard/>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
	</Excess>
	<Indicator>1</Indicator>
	<coverage>
		<Type>CCA_SD</Type>
		<Indicator>{CONTRACTORSANDSUBCONTRACTORS_INDICATOR}</Indicator>
		<sValue>{CONTRACTORSANDSUBCONTRACTORS_IND}</sValue>
		<Code>PFCCA_SD</Code>
		<Description>Consultants, Contractors and Agents</Description>
		<limit>
			<Type>CCA_SD</Type>
			<iValue>{CONTRACTORSANDSUBCONTRACTORSLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_PFCCA_SD}</Premium>
	</coverage>
	<coverage>
		<Type>CSL_SD</Type>
		<sValue>{VEHASS_IND}</sValue>
		<Indicator>{VEHASS_INDICATOR}</Indicator>
		<Code>PFCSL_SD</Code>
		<Description>Certifications and Slips</Description>
		<limit>
			<Type>CSL_SD</Type>
			<iValue>{PIASSESSMENTLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_PFCSL_SD}</Premium>
	</coverage>
	<Code>PF</Code>
	<coverage>
		<Indicator>1</Indicator>
		<Type>STD_SD</Type>
		<Code>PFSTD_SD</Code>
		<Description>Standard</Description>
		<limit>
			<Type>STD_SD</Type>
			<iValue>{PROFESSIONALPROTECTIONLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_PFSTD_SD}</Premium>
	</coverage>   {LINE_PF_CLAUSE}    <limit>
		<Type>VehicleAssessmentLimit</Type>
		<iValue>{PROFESSIONALPROTECTIONLIMIT}</iValue>
	</limit>
	<VehicleAssessmentsAnnualTurnover>{VEHICLEASSESSMENTSANNUALTURNOVER}</VehicleAssessmentsAnnualTurnover>
	<VehicleBreakdownAnnualTurnover>{VEHICLEBREAKDOWNANNUALTURNOVER}</VehicleBreakdownAnnualTurnover>
	<Details>{DETAILS}</Details>
	<Date>{PIDATE}</Date>
	<PreviousProfessionalProtection>{PREVIOUSPROFESSIONALPROTECTION}</PreviousProfessionalProtection>
	<PreviousEvent>{PREVIOUSEVENT}</PreviousEvent>    {LINE_PF_UW}         <ClaimsIncurred>{PICLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{PICLMCNT}</NumberOfClaims>
	<Premium>{PIEXPPREM}</Premium>
	<ClassCode>
		<APRA>PI</APRA>
		<Business>PI</Business>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage> 

', N'<coverage>
	<Type>ProfessionalProtection</Type>
	<Description>Professional Protection</Description>
	<coverage>
		<Type>VHB_SD</Type>
		<sValue>{VEHBREAK_IND}</sValue>
		<Indicator>{VEHBREAK_INDICATOR}</Indicator>
		<Code>PFVHB_SD</Code>
		<Description>Vehicle Breakdown</Description>
		<limit>
			<Type>VHB_SD</Type>
			<iValue>{PIBREAKDOWNLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_PFVHB_SD}</Premium>
	</coverage>
	<coverage>
		<Type>ROL_SD</Type>
		<sValue>{RETROACTIVE_IND}</sValue>
		<Indicator>{RETROACTIVE_INDICATOR}</Indicator>
		<Code>PFROL_SD</Code>
		<Description>Retroactive Protection</Description>
		<limit>
			<Type>ROL_SD</Type>
			<iValue>{RETROACTIVELIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_PFROL_SD}</Premium>
	</coverage>
	<Excess>
		<Imposed>{IMPOSEDEXCESS}</Imposed>
		<Standard>{STANDARDEXCESS}</Standard>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
	</Excess>
	<Indicator>1</Indicator>
	<coverage>
		<Type>CCA_SD</Type>
		<Indicator>{CONTRACTORSANDSUBCONTRACTORS_INDICATOR}</Indicator>
		<sValue>{CONTRACTORSANDSUBCONTRACTORS_IND}</sValue>
		<Code>PFCCA_SD</Code>
		<Description>Consultants, Contractors and Agents</Description>
		<limit>
			<Type>CCA_SD</Type>
			<iValue>{CONTRACTORSANDSUBCONTRACTORSLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_PFCCA_SD}</Premium>
	</coverage>
	<coverage>
		<Type>CSL_SD</Type>
		<sValue>{VEHASS_IND}</sValue>
		<Indicator>{VEHASS_INDICATOR}</Indicator>
		<Code>PFCSL_SD</Code>
		<Description>Certifications and Slips</Description>
		<limit>
			<Type>CSL_SD</Type>
			<iValue>{PIASSESSMENTLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_PFCSL_SD}</Premium>
	</coverage>
	<Code>PF</Code>
	<coverage>
		<Indicator>1</Indicator>
		<Type>STD_SD</Type>
		<Code>PFSTD_SD</Code>
		<Description>Standard</Description>
		<limit>
			<Type>STD_SD</Type>
			<iValue>{PROFESSIONALPROTECTIONLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_PFSTD_SD}</Premium>
	</coverage>   {PA_LINE_PF_CLAUSE}    <limit>
		<Type>VehicleAssessmentLimit</Type>
		<iValue>{PROFESSIONALPROTECTIONLIMIT}</iValue>
	</limit>
	<VehicleAssessmentsAnnualTurnover>{VEHICLEASSESSMENTSANNUALTURNOVER}</VehicleAssessmentsAnnualTurnover>
	<VehicleBreakdownAnnualTurnover>{VEHICLEBREAKDOWNANNUALTURNOVER}</VehicleBreakdownAnnualTurnover>
	<Details>{DETAILS}</Details>
	<Date>{PIDATE}</Date>
	<PreviousProfessionalProtection>{PREVIOUSPROFESSIONALPROTECTION}</PreviousProfessionalProtection>
	<PreviousEvent>{PREVIOUSEVENT}</PreviousEvent>    {PA_LINE_PF_UW}          <ClaimsIncurred>{PICLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{PICLMCNT}</NumberOfClaims>
	<Premium>{PIEXPPREM}</Premium>
	<ClassCode>
		<APRA/>
		<Business/>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T06:25:47.5740000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (17, 15, N'BP_LINE_GT_UW', N'AGGNE.DEV.LINE_GT_UW', N'AGGNE.DEV.LINE_GT_Target', N'AGGNE.DEV.PA_LINE_GT_UW', N'AGGNE.DEV.PA_LINE_GT_Target', N'
  <UnderwritingAdjustment>
		<Type>GoodsInTransit</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	   </Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', N'
    <UnderwritingAdjustment>
		<Type>GoodsInTransit</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	    </Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T06:41:14.9490000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (18, 16, N'BP_LINE_GT_CLAUSE', N'AGGNE.DEV.LINE_GT_CLAUSE', N'AGGNE.DEV.LINE_GT_Target', N'AGGNE.DEV.PA_LINE_GT_CLAUSE', N'AGGNE.DEV.PA_LINE_GT_Target', N'
  <Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	</Clause>', N'
    <Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	 </Clause>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T06:48:32.5350000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (19, 17, N'BP_LINE_GT', N'AGGNE.DEV.LINE_GT_PAYLOAD', N'AGGNE.DEV.LINE_GT_Target', N'AGGNE.DEV.PA_LINE_GT_PAYLOAD', N'AGGNE.DEV.PA_LINE_GT_Target', N'<coverage>
	<Type>GoodsInTransit</Type>
	<Description>Goods In Transit</Description>
	<Excess>
		<Standard/>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
		<Imposed/>
	</Excess>
	<coverage>
		<Type>STD_SD</Type>
		<limit>
			<Type>STD_SD</Type>
			<iValue>{BUSINESSCONTENTANDSTOCK}</iValue>
		</limit>
		<Indicator>1</Indicator>
		<Code>GTSTD_SD</Code>
		<Description>Standard</Description>
		<Premium>{EXP_PREM_GTSTD_SD}</Premium>
	</coverage>
	<EstimatedAnnualValue>{ESTIMATEDANNUALVALUE}</EstimatedAnnualValue>
	<HazardousGoods>{HAZARDOUSGOODS}</HazardousGoods>
	<HazardousGoodsbeingTransported>{HAZARDOUSGOODSTRANSPORTED}</HazardousGoodsbeingTransported>
	<ContentsandStocktransported>{CONTENTSANDSTOCKTRANSPORTED}</ContentsandStocktransported>
	<Code>GT</Code>
	<Indicator>1</Indicator>   {LINE_GT_CLAUSE}   {LINE_GT_UW}     <ClaimsIncurred>{GTCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{GTCLMCNT}</NumberOfClaims>
	<Premium>{GTEXPPREM}</Premium>
	<ClassCode>
		<APRA>MAR</APRA>
		<Business>BSP</Business>
	</ClassCode>
	<ExpirinGTurePremium/>
	<ExpirinGTremium/>
</coverage>
', N'<coverage>
	<Type>GoodsInTransit</Type>
	<Description>Goods In Transit</Description>
	<Excess>
		<Imposed>{IMPOSEDEXCESS}</Imposed>
		<Standard>{STANDARDEXCESS}</Standard>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
	</Excess>
	<coverage>
		<Type>STD_SD</Type>
		<limit>
			<Type>STD_SD</Type>
			<iValue>{GTINLANDSHIPLIMIT}</iValue>
		</limit>
		<Indicator>1</Indicator>
		<Code>GTSTD_SD</Code>
		<Description>Standard</Description>
		<Premium>{EXP_PREM_GTSTD_SD}</Premium>
	</coverage>
	<EstimatedAnnualValue>{ESTIMATEDANNUALVALUE}</EstimatedAnnualValue>
	<HazardousGoods>{HAZARDOUSGOODS}</HazardousGoods>
	<HazardousGoodsbeingTransported>{HAZARDOUSGOODSTRANSPORTED}</HazardousGoodsbeingTransported>
	<ContentsandStocktransported>{CONTENTSANDSTOCKTRANSPORTED}</ContentsandStocktransported>
	<Code>GT</Code>
	<Indicator>1</Indicator>   {LINE_GT_CLAUSE}   {LINE_GT_UW}      <ClaimsIncurred>{GTCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{GTCLMCNT}</NumberOfClaims>
	<Premium>{GTEXPPREM}</Premium>
	<ClassCode>
		<APRA/>
		<Business/>
	</ClassCode>
	<ExpirinGTurePremium/>
	<ExpirinGTremium/>
</coverage>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T06:51:55.9090000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (20, 18, N'BP_LINE_LE_UW', N'AGGNE.DEV.LINE_LE_UW', N'AGGNE.DEV.LINE_LE_Target', N'AGGNE.DEV.PA_LINE_LE_UW', N'AGGNE.DEV.PA_LINE_LE_Target', N'
  <UnderwritingAdjustment>
		<Type>LegalExpenses</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	   </Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', N'
   <UnderwritingAdjustment>
		<Type>LegalExpenses</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	    </Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T06:54:54.6140000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (21, 19, N'BP_LINE_LE_CLAUSE', N'AGGNE.DEV.LINE_LE_CLAUSE', N'AGGNE.DEV.LINE_LE_Target', N'AGGNE.DEV.PA_LINE_LE_CLAUSE', N'AGGNE.DEV.PA_LINE_LE_Target', N'
  <Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	</Clause>', N'
  <Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	 </Clause>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T08:45:49.3920000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (22, 20, N'BP_LINE_LE', N'AGGNE.DEV.LINE_LE_PAYLOAD', N'AGGNE.DEV.LINE_LE_Target', N'AGGNE.DEV.PA_LINE_LE_PAYLOAD', N'AGGNE.DEV.PA_LINE_LE_Target', N'<coverage>
	<Type>LegalExpenses</Type>
	<Description>Legal Expenses</Description>
	<Excess>
		<Standard/>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
		<Imposed/>
	</Excess>
	<coverage>
		<Type>STD_SD</Type>
		<limit>
			<Type>STD_SD</Type>
			<iValue>{LEGALEXPENSESLIMIT}</iValue>
		</limit>
		<Indicator>{LEGALEXPENSES_IND}</Indicator>
		<Code>LESTD_SD</Code>
		<Description>Standard</Description>
		<Premium>{EXP_PREM_LESTD_SD}</Premium>
	</coverage>
	<LegalDisputeActions>{LEGALDISPUTEACTIONS}</LegalDisputeActions>
	<Redundancies>{REDUNDANCIES}</Redundancies>
	<LegalDisputeActionsDetails>{LEGALDISPUTEACTIONSDETAILS}</LegalDisputeActionsDetails>
	<RedundanciesDetails>{REDUNDANCIESDETAILS}</RedundanciesDetails>
	<Code>LE</Code>
	<Indicator>1</Indicator>   {LINE_LE_CLAUSE}   {LINE_LE_UW}     <ClaimsIncurred>{LECLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{LECLMCNT}</NumberOfClaims>
	<Premium>{LEEXPPREM}</Premium>
	<ClassCode>
		<APRA>PI</APRA>
		<Business>PROF</Business>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>
', N'
 <coverage>
	<Type>LegalExpenses</Type>
    <Description>Legal Expenses</Description>
	<Excess>
		<Imposed>{IMPOSEDEXCESS}</Imposed>
		<Standard>{STANDARDEXCESS}</Standard>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
	</Excess>
	<coverage>
		<Type>STD_SD</Type>
		<limit>
			<Type>STD_SD</Type>
			<iValue>{LEGALEXPENSESLIMIT}</iValue>
		</limit>
		<Indicator>{LEGALEXPENSES_IND}</Indicator>
		<Code>LESTD_SD</Code>
		<Description>Standard</Description>
        <Premium>{EXP_PREM_LESTD_SD}</Premium>
	</coverage>
	<LegalDisputeActions>{LEGALDISPUTEACTIONS}</LegalDisputeActions>
	<Redundancies>{REDUNDANCIES}</Redundancies>
	<LegalDisputeActionsDetails>{LEGALDISPUTEACTIONSDETAILS}</LegalDisputeActionsDetails>
	<RedundanciesDetails>{REDUNDANCIESDETAILS}</RedundanciesDetails>
	<Code>LE</Code>
	<Indicator>1</Indicator>
	{LINE_LE_CLAUSE}
	{LINE_LE_UW}
    <ClaimsIncurred>{LECLMINCD}</ClaimsIncurred>
    <NumberOfClaims>{LECLMCNT}</NumberOfClaims>
    <Premium>{LEEXPPREM}</Premium>
	<ClassCode>
		<APRA/>
		<Business/>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T08:48:25.4570000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (23, 21, N'BP_LINE_SV_UW', N'AGGNE.DEV.LINE_SV_UW', N'AGGNE.DEV.LINE_SV_Target', N'AGGNE.DEV.PA_LINE_SV_UW', N'AGGNE.DEV.PA_LINE_SV_Target', N'
  <UnderwritingAdjustment>
		<Type>StockVehicles</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	   </Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', N'
 <UnderwritingAdjustment>
		<Type>StockVehicles</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	    </Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T08:51:21.0450000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (24, 22, N'BP_LINE_SV_CLAUSE', N'AGGNE.DEV.LINE_SV_CLAUSE', N'AGGNE.DEV.LINE_SV_Target', N'AGGNE.DEV.PA_LINE_SV_CLAUSE', N'AGGNE.DEV.PA_LINE_SV_Target', N'
  <Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	</Clause>', N'
 <Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	 </Clause>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T08:52:32.1900000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (25, 23, N'BP_LINE_SV', N'AGGNE.DEV.LINE_SV_PAYLOAD', N'AGGNE.DEV.LINE_SV_Target', N'AGGNE.DEV.PA_LINE_SV_PAYLOAD', N'AGGNE.DEV.PA_LINE_SV_Target', N'<coverage>
	<Type>StockVehicles</Type>
	<Description>Stock Vehicles</Description>
	<ProtectionType>{PROTECTIONTYPE}</ProtectionType>
	<limit>
		<Type>LossOrDamageLimit</Type>
		<iValue>{LOSSDAMAGELIMIT}</iValue>
	</limit>
	<Excess>
		<Imposed/>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
		<Standard/>
		<HailAndMaliciousDamage/>
		<WindscreenAndWindowGlass/>
		<StockVehiclesStolenKeys/>
	</Excess>
	<coverage>
		<Type>GLS_SD</Type>
		<sValue>{EXCESSWAIVERFORWINDSCREEN}</sValue>
		<Indicator>{UVGLASSREMOVAL_IND}</Indicator>
		<Code>SVGLS_SD</Code>
		<Description>Windscreen / Glass</Description>
		<limit>
			<Type>GLS_SD</Type>
			<iValue/>
		</limit>
		<Premium>{EXP_PREM_SVGLS_SD}</Premium>
	</coverage>
	<NumberOfVehiclesWatercraftsHeldAsStockByYou>{NOFVEHWATERCRAFTSHELD}</NumberOfVehiclesWatercraftsHeldAsStockByYou>
	<WhatIsTheAverageValueOfTheVehiclesHeldInStock>{AVERAGEVALUEOFTHEVEH}</WhatIsTheAverageValueOfTheVehiclesHeldInStock>
	<WhatIsTheMaximumEstimatedValueOfAnySingleVehicle>{MAXIMUMESTIMATEDVALUE}</WhatIsTheMaximumEstimatedValueOfAnySingleVehicle>
	<coverage>
		<Type>LIA_SD</Type>
		<limit>
			<Type>LIA_SD</Type>
			<iValue>{LOSSDAMAGELIMIT}</iValue>
		</limit>
		<Indicator>1</Indicator>
		<Code>SVLIA_SD</Code>
		<Description>Comprehensive Liability</Description>
		<Premium>{EXP_PREM_SVLIA_SD}</Premium>
	</coverage>
	<Code>SV</Code>
	<coverage>
		<Indicator>1</Indicator>
		<Type>STD_SD</Type>
		<Code>SVSTD_SD</Code>
		<Description>Comprehensive Property</Description>
		<limit>
			<Type>STD_SD</Type>
			<iValue>{LOSSDAMAGELIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_SVSTD_SD}</Premium>
	</coverage>
	<coverage>
		<Indicator>1</Indicator>
		<Type>TPO_SD</Type>
		<Code>SVTPO_SD</Code>
		<Description>Third Party Only</Description>
		<limit>
			<Type>TPO_SD</Type>
			<iValue>{LOSSDAMAGELIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_SVTPO_SD}</Premium>
	</coverage>
	<coverage>
		<Indicator>1</Indicator>
		<Type>STD_ST</Type>
		<Code>SVSTD_ST</Code>
		<Description>Storm</Description>
		<limit>
			<Type>STD_ST</Type>
			<iValue>{LOSSDAMAGELIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_SVSTD_ST}</Premium>
	</coverage>
	<Indicator>{STOCKVEHICLES_IND}</Indicator>   {LINE_SV_CLAUSE}   <DoYouHaveADealersLicense>{DOYOUHAVEADEALERSLICENSE}</DoYouHaveADealersLicense>   {LINE_SV_UW}     <ClaimsIncurred>{SVCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{SVCLMCNT}</NumberOfClaims>
	<Premium>{SVEXPPREM}</Premium>
	<ClassCode>
		<APRA>DMV</APRA>
		<Business>CMV</Business>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>', N'<coverage>
	<Type>StockVehicles</Type>
	<Description>Stock Vehicles</Description>
	<ProtectionType>{PROTECTIONTYPE}</ProtectionType>
	<limit>
		<Type>LossOrDamageLimit</Type>
		<iValue>{LOSSDAMAGELIMIT}</iValue>
	</limit>
	<limit>
		<Type>LegalLiability</Type>
		<iValue>20000000</iValue>
	</limit>
	<Excess>
		<Imposed>{IMPOSEDEXCESS}</Imposed>
		<Standard>{STANDARDEXCESS}</Standard>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
		<HailAndMaliciousDamage/>
		<WindscreenAndWindowGlass/>
		<StockVehiclesStolenKeys/>
	</Excess>
	<coverage>
		<Type>GLS_SD</Type>
		<sValue>{EXCESSWAIVERFORWINDSCREEN}</sValue>
		<Indicator>{UVGLASSREMOVAL_IND}</Indicator>
		<Code>SVGLS_SD</Code>
		<Description>Windscreen / Glass</Description>
		<limit>
			<Type>GLS_SD</Type>
			<iValue/>
		</limit>
		<Premium>{EXP_PREM_SVGLS_SD}</Premium>
	</coverage>
	<NumberOfVehiclesWatercraftsHeldAsStockByYou>{NOFVEHWATERCRAFTSHELD}</NumberOfVehiclesWatercraftsHeldAsStockByYou>
	<WhatIsTheAverageValueOfTheVehiclesHeldInStock>{AVERAGEVALUEOFTHEVEH}</WhatIsTheAverageValueOfTheVehiclesHeldInStock>
	<WhatIsTheMaximumEstimatedValueOfAnySingleVehicle>{MAXIMUMESTIMATEDVALUE}</WhatIsTheMaximumEstimatedValueOfAnySingleVehicle>
	<coverage>
		<Type>LIA_SD</Type>
		<limit>
			<Type>LIA_SD</Type>
			<iValue>{LOSSDAMAGELIMIT}</iValue>
		</limit>
		<Indicator>1</Indicator>
		<Code>SVLIA_SD</Code>
		<Description>Comprehensive Liability</Description>
		<Premium>{EXP_PREM_SVLIA_SD}</Premium>
	</coverage>
	<Code>SV</Code>
	<coverage>
		<Indicator>{COM_INDICATOR}</Indicator>
		<Type>STD_SD</Type>
		<Code>SVSTD_SD</Code>
		<Description>Comprehensive Property</Description>
		<limit>
			<Type>STD_SD</Type>
			<iValue>{LOSSDAMAGELIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_SVSTD_SD}</Premium>
	</coverage>
	<coverage>
		<Indicator>{TPO_INDICATOR}</Indicator>
		<Type>TPO_SD</Type>
		<Code>SVTPO_SD</Code>
		<Description>Third Party Only</Description>
		<limit>
			<Type>TPO_SD</Type>
			<iValue>{LOSSDAMAGELIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_SVTPO_SD}</Premium>
	</coverage>
	<coverage>
		<Indicator>1</Indicator>
		<Type>STD_ST</Type>
		<Code>SVSTD_ST</Code>
		<Description>Storm</Description>
		<limit>
			<Type>STD_ST</Type>
			<iValue>{LOSSDAMAGELIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_SVSTD_ST}</Premium>
	</coverage>
	<Indicator>{STOCKVEHICLES_IND}</Indicator>   {LINE_SV_CLAUSE}   <DoYouHaveADealersLicense>{DOYOUHAVEADEALERSLICENSE}</DoYouHaveADealersLicense>   {LINE_SV_UW}      <ClaimsIncurred>{SVCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{SVCLMCNT}</NumberOfClaims>
	<Premium>{SVEXPPREM}</Premium>
	<ClassCode>
		<APRA/>
		<Business/>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T08:55:17.5500000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (26, 24, N'BP_LINE_CV_UW', N'AGGNE.DEV.LINE_CV_UW', N'AGGNE.DEV.LINE_CV_Target', N'AGGNE.DEV.PA_LINE_CV_UW', N'AGGNE.DEV.PA_LINE_CV_Target', N'
 <UnderwritingAdjustment>
		<Type>CustomerVehicles</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	   </Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', N'
 <UnderwritingAdjustment>
		<Type>CustomerVehicles</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	    </Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T08:56:54.2250000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (27, 25, N'BP_LINE_CV_CLAUSE', N'AGGNE.DEV.LINE_CV_CLAUSE', N'AGGNE.DEV.LINE_CV_Target', N'AGGNE.DEV.PA_LINE_CV_CLAUSE', N'AGGNE.DEV.PA_LINE_CV_Target', N'
 <Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	</Clause>', N'
<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	 </Clause>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T08:57:46.7200000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (28, 26, N'BP_LINE_CV', N'AGGNE.DEV.LINE_CV_PAYLOAD', N'AGGNE.DEV.LINE_CV_Target', N'AGGNE.DEV.PA_LINE_CV_PAYLOAD', N'AGGNE.DEV.PA_LINE_CV_Target', N'<coverage>
	<Type>CustomerVehicles</Type>
	<Description>Customer Vehicles</Description>
	<Excess>
		<Standard/>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
		<Imposed/>
		<HailandMaliciousDamage/>
	</Excess>
	<limit>
		<Type>LegalLiability</Type>
		<iValue/>
	</limit>
	<coverage>
		<Type>STD_SD</Type>
		<limit>
			<Type>LossorDamageLimit</Type>
			<iValue>{LOSSDAMAGELIMIT}</iValue>
		</limit>
		<Indicator>{CUSTOMERVEHICLES_IND}</Indicator>
		<Code>CVSTD_SD</Code>
		<Premium>{EXP_PREM_CVSTD_SD}</Premium>
	</coverage>
	<Code>CV</Code>
	<Indicator>1</Indicator>   {LINE_CV_CLAUSE}   {LINE_CV_UW}     <ClaimsIncurred>{CVCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{CVCLMCNT}</NumberOfClaims>
	<Premium>{CVEXPPREM}</Premium>
	<ClassCode>
		<APRA>DMV</APRA>
		<Business>CMV</Business>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>

', N'<coverage>
	<Type>CustomerVehicles</Type>
	<Description>Customer Vehicles</Description>
	<Excess>
		<Imposed>{IMPOSEDEXCESS}</Imposed>
		<Standard>{STANDARDEXCESS}</Standard>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
		<StockVehiclesStolenKeys>{STOLENKEYSEXCESS}</StockVehiclesStolenKeys>
		<HailandMaliciousDamage/>
	</Excess>
	<limit>
		<Type>LegalLiability</Type>
		<iValue/>
	</limit>
	<coverage>
		<Type>STD_SD</Type>
		<limit>
			<Type>LossorDamageLimit</Type>
			<iValue>{LOSSDAMAGELIMIT}</iValue>
		</limit>
		<Indicator>{CUSTOMERVEHICLES_IND}</Indicator>
		<Code>CVSTD_SD</Code>
		<Premium>{EXP_PREM_CVSTD_SD}</Premium>
	</coverage>
	<Code>CV</Code>
	<Indicator>1</Indicator>   {LINE_CV_CLAUSE}   {LINE_CV_UW}      <ClaimsIncurred>{CVCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{CVCLMCNT}</NumberOfClaims>
	<Premium>{CVEXPPREM}</Premium>
	<ClassCode>
		<APRA/>
		<Business/>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T09:08:50.8650000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (29, 27, N'BP_LINE_TA_UW', N'AGGNE.DEV.LINE_TA_UW', N'AGGNE.DEV.LINE_TA_Target', N'AGGNE.DEV.PA_LINE_TA_UW', N'AGGNE.DEV.PA_LINE_TA_Target', N'
 <UnderwritingAdjustment>
		<Type>TaxAudit</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	   </Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', N'
<UnderwritingAdjustment>
		<Type>TaxAudit</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	    </Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	 </UnderwritingAdjustment>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T09:16:10.3860000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (30, 28, N'BP_LINE_TA_CLAUSE', N'AGGNE.DEV.LINE_TA_CLAUSE', N'AGGNE.DEV.LINE_TA_Target', N'AGGNE.DEV.PA_LINE_TA_CLAUSE', N'AGGNE.DEV.PA_LINE_TA_Target', N'
 <Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	</Clause>', N'
<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	 </Clause>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T09:18:09.6140000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (31, 29, N'BP_LINE_TA', N'AGGNE.DEV.LINE_TA_PAYLOAD', N'AGGNE.DEV.LINE_TA_Target', N'AGGNE.DEV.PA_LINE_TA_PAYLOAD', N'AGGNE.DEV.PA_LINE_TA_Target', N'<coverage>
	<Type>TaxAudit</Type>
	<Description>Tax Audit</Description>
	<ListOfDirector/>
	<PreviousTaxAudit/>
	<SumInsured/>
	<Excess>
		<Standard/>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
		<Imposed/>
	</Excess>
	<coverage>
		<Type>STD_SD</Type>
		<limit>
			<Type>STD_SD</Type>
			<iValue>{TAXAUDITLIMIT}</iValue>
		</limit>
		<Indicator>1</Indicator>
		<Code>TASTD_SD</Code>
		<Description>Standard</Description>
		<Premium>{EXP_PREM_TASTD_SD}</Premium>
	</coverage>
	<CoverageLevel>Per Occurrence</CoverageLevel>
	<Code>TA</Code>
	<Indicator>1</Indicator>   {LINE_TA_CLAUSE}   <AustraliaTaxOfficeHasBeenInvestigated>{AUSTAXOFFICEHASBEENINVESTIGATED}</AustraliaTaxOfficeHasBeenInvestigated>
	<AustraliaTaxOfficeNotification>{AUSTRALIATAXOFFICENOTIFICATION}</AustraliaTaxOfficeNotification>
	<Details>{DETAILS}</Details>
	<AustraliaTaxOfficeNotificationDetails>{AUSTAXOFFICENOTIFICATIONDETAILS}</AustraliaTaxOfficeNotificationDetails>   {LINE_TA_UW}     <ClaimsIncurred>{TACLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{TACLMCNT}</NumberOfClaims>
	<Premium>{TAEXPPREM}</Premium>
	<ClassCode>
		<APRA>OTH</APRA>
		<Business>OACC</Business>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>', N'
<coverage>
	<Type>TaxAudit</Type>
    <Description>Tax Audit</Description>
	<ListOfDirector/>
	<PreviousTaxAudit/>
	<SumInsured/>
	<Excess>
		<Imposed>{IMPOSEDEXCESS}</Imposed>
		<Standard>{STANDARDEXCESS}</Standard>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
	</Excess>
	<coverage>
		<Type>STD_SD</Type>
		<limit>
			<Type>STD_SD</Type>
			<iValue>{TAXAUDITLIMIT}</iValue>
		</limit>
		<Indicator>1</Indicator>
		<Code>TASTD_SD</Code>
		<Description>Standard</Description>
        <Premium>{EXP_PREM_TASTD_SD}</Premium>
	</coverage>
	<CoverageLevel>Per Occurrence</CoverageLevel>
	<Code>TA</Code>
	<Indicator>1</Indicator>
	{LINE_TA_CLAUSE}
	<AustraliaTaxOfficeHasBeenInvestigated>{AUSTAXOFFICEHASBEENINVESTIGATED}</AustraliaTaxOfficeHasBeenInvestigated>
	<AustraliaTaxOfficeNotification>{AUSTRALIATAXOFFICENOTIFICATION}</AustraliaTaxOfficeNotification>
	<Details>{DETAILS}</Details>
	<AustraliaTaxOfficeNotificationDetails>{AUSTAXOFFICENOTIFICATIONDETAILS}</AustraliaTaxOfficeNotificationDetails>
	{LINE_TA_UW}
    <ClaimsIncurred>{TACLMINCD}</ClaimsIncurred>
    <NumberOfClaims>{TACLMCNT}</NumberOfClaims>
    <Premium>{TAEXPPREM}</Premium>
	<ClassCode>
		<APRA/>
		<Business/>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T09:21:39.1620000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (32, 30, N'BP_Building_SubCov', N'AGGNE.DEV.BUILDING_SUBCOVERAGES', N'AGGNE.DEV.BUILDING_Target', N'AGGNE.DEV.PA_BUILDING_SUBCOVERAGES', N'AGGNE.DEV.PA_RISK_BUILDING_TARGET', N'
 <coverage>
<Type>{TYPE}</Type>
{SVALUE}
<Indicator>{INDICATOR}</Indicator>
<Code>{CODE}</Code>
<Description>{DESCRIPTION}</Description>
<limit>
<Type>{TYPE}</Type>
<iValue>{IVALUE}</iValue>
</limit>
<Premium>{EXP_PREM}</Premium>
</coverage>', N'  <coverage>  <Type>{TYPE}</Type>  {SVALUE}  <Indicator>1</Indicator>  <Code>{CODE}</Code>  <Description>{DESCRIPTION}</Description>  <limit>  <Type>{TYPE}</Type>  <iValue>{IVALUE}</iValue>  </limit>  <Premium>{EXP_PREM}</Premium>  </coverage>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T09:24:51.6130000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (33, 31, N'BP_BUILDING_UW', N'AGGNE.DEV.BUILDING_UW', N'AGGNE.DEV.BUILDING_Target', N'AGGNE.DEV.PA_BUILDING_UW', N'AGGNE.DEV.PA_RISK_BUILDING_TARGET', N'
<UnderwritingAdjustment>
<Type>{COVERAGE}</Type>
<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
<AdjustmentAmount></AdjustmentAmount>
<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
</Recurring>
<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
</UnderwritingAdjustment>', N'
<UnderwritingAdjustment>
<Type>{COVERAGE}</Type>
<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
<AdjustmentAmount></AdjustmentAmount>
<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
</Recurring>
<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
</UnderwritingAdjustment>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T09:27:47.7810000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (34, 32, N'BP_LOC_BB_CLAUSE', N'AGGNE.DEV.LOC_BB_CLAUSE', N'AGGNE.DEV.BUILDING_Target', N'AGGNE.DEV.PA_LOC_BB_CLAUSE', N'AGGNE.DEV.PA_RISK_BUILDING_TARGET', N'
<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	</Clause>', N'
<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	 </Clause>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T09:29:39.1330000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (35, 33, N'BP_RISK_Building_Cov_Building', N'AGGNE.DEV.BUILDING_PAYLOAD', N'AGGNE.DEV.BUILDING_Target', N'AGGNE.DEV.PA_BUILDING_PAYLOAD', N'AGGNE.DEV.PA_RISK_BUILDING_TARGET', N' 
<coverage>   <Type>Building</Type>     <Description>Business Buildings</Description>   <Excess>    <Amount></Amount>    <Imposed></Imposed>    <Flood></Flood>    <Voluntary>{VOLUNTARYEXCESS}</Voluntary>    <Earthquake></Earthquake>    <Standard></Standard>    <Glass></Glass>   </Excess>   <SetExcessAmount>0</SetExcessAmount>   <Indicator>1</Indicator>   <CoverageLevel>Per Occurrence</CoverageLevel>   {SUBCOV}   <Code>BB</Code>   {UW}     <ClaimsIncurred>{BBCLMINCD}</ClaimsIncurred>     <NumberOfClaims>{BBCLMCNT}</NumberOfClaims>     <Premium>{BBEXPPREM}</Premium>      {LOC_BB_CLAUSE}   <ClassCode>    <APRA>FISR</APRA>    <Business>BSP</Business>   </ClassCode>   <ExpiringPurePremium></ExpiringPurePremium>   <ExpiringPremium></ExpiringPremium>  </coverage>', N'<coverage>   <Type>Building</Type>      <Description>Business Buildings</Description>   <Excess>    <Amount></Amount>    <Imposed>{IMPOSEDEXCESS}</Imposed>  
  <Flood>{FLOODEXCESS}</Flood>    <Voluntary>{VOLUNTARYEXCESS}</Voluntary>    <Earthquake>{EARTHQUAKEEXCESS}</Earthquake>    <Standard>{STANDARDEXCESS}</Standard> 
  <Glass>{GLASSEXCESS}</Glass>   </Excess>   <SetExcessAmount>0</SetExcessAmount>   <Indicator>1</Indicator>   <CoverageLevel>Per Occurrence</CoverageLevel>   {SUBCOV}   <Code>BB</Code>   {UW}      <ClaimsIncurred>{BBCLMINCD}</ClaimsIncurred>      <NumberOfClaims>{BBCLMCNT}</NumberOfClaims>      <Premium>{BBEXPPREM}</Premium>      {LOC_BB_CLAUSE}   <ClassCode> 
  <APRA></APRA>    <Business></Business>   </ClassCode>   <ExpiringPurePremium></ExpiringPurePremium>   <ExpiringPremium></ExpiringPremium>  </coverage>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T09:40:58.5140000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (36, 34, N'BP_Risk_Building_BI_Subcov', N'AGGNE.DEV.RISK_BUILDING_BI_COVERAGES', N'AGGNE.DEV.RISK_BUILDING_BI_TARGET', N'AGGNE.DEV.PA_RISK_BUILDING_BI_COVERAGES', N'AGGNE.DEV.PA_RISK_BUILDING_BI_TARGET', N'
<coverage>
		<Type>{TYPE}</Type>
		<limit>
			<Type>{TYPE}</Type>
			<iValue>{IVALUE}</iValue>
		</limit>
		<Indicator>1</Indicator>
		<Code>{CODE}</Code>
		<Description>{DESCRIPTION}</Description>
       <Premium>{EXP_PREM}</Premium>
	</coverage>', N'
<coverage>
		<Type>{TYPE}</Type>
		<limit>
			<Type>{TYPE}</Type>
			<iValue>{IVALUE}</iValue>
		</limit>
		<Indicator>1</Indicator>
		<Code>{CODE}</Code>
		<Description>{DESCRIPTION}</Description>
        <Premium>{EXP_PREM}</Premium>
	</coverage>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T09:45:48.2980000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (37, 35, N'BP_Risk_Building_BI_UW', N'AGGNE.DEV.RISK_BUILDING_BI_UW', N'AGGNE.DEV.RISK_BUILDING_BI_TARGET', N'AGGNE.DEV.PA_RISK_BUILDING_BI_UW', N'AGGNE.DEV.PA_RISK_BUILDING_BI_TARGET', N'
<UnderwritingAdjustment>
		<Type>{COVERAGE}</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount/>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	</Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', N'
<UnderwritingAdjustment>
		<Type>{COVERAGE}</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount/>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	</Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T09:47:11.0620000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (38, 36, N'BP_LOC_BI_CLAUSE', N'AGGNE.DEV.LOC_BI_CLAUSE', N'AGGNE.DEV.RISK_BUILDING_BI_TARGET', N'AGGNE.DEV.PA_LOC_BI_CLAUSE', N'AGGNE.DEV.PA_RISK_BUILDING_BI_TARGET', N'
<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	</Clause>', N'
<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	 </Clause>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T09:51:14.3370000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (39, 37, N'BP_RISK_Building_BI', N'AGGNE.DEV.BUILDING_BI_PAYLOAD', N'AGGNE.DEV.RISK_BUILDING_BI_TARGET', N'AGGNE.DEV.PA_BUILDING_BI_PAYLOAD', N'AGGNE.DEV.PA_RISK_BUILDING_BI_TARGET', N'<coverage>
	<Type>BusinessInterruption</Type>
	<Description>Business Interruption</Description>
	<Indicator>1</Indicator>
	<coverage>
		<Type>GRP_SD</Type>
		<limit>
			<Type>GRP_SD</Type>
			<iValue>{ANNUALGROSSPROFIT}</iValue>
		</limit>
		<Indicator>1</Indicator>
		<Code>BIGRP_SD</Code>
		<Description>Standard</Description>
		<Premium>{EXP_PREM_BIGRP_SD}</Premium>
	</coverage>
	<IndemnityPeriod>{INDEMNITYPERIOD}</IndemnityPeriod>   {SUBCOV}   <Excess>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
		<Standard/>
		<Imposed/>
	</Excess>
	<Code>BI</Code>
	<coverage>
		<Indicator>1</Indicator>
		<Type>GRP_CY</Type>
		<Code>BIGRP_CY</Code>
		<Description>Cyclone</Description>
		<limit>
			<Type>GRP_CY</Type>
			<iValue>{ANNUALGROSSPROFIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_BIGRP_CY}</Premium>
	</coverage>
	<coverage>
		<Indicator>1</Indicator>
		<Type>GRP_EQ</Type>
		<Code>BIGRP_EQ</Code>
		<Description>Earthquake</Description>
		<limit>
			<Type>GRP_EQ</Type>
			<iValue>{ANNUALGROSSPROFIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_BIGRP_EQ}</Premium>
	</coverage>
	<coverage>
		<Indicator>1</Indicator>
		<Type>GRP_ST</Type>
		<Code>BIGRP_ST</Code>
		<Description>Storm</Description>
		<limit>
			<Type>GRP_ST</Type>
			<iValue>{ANNUALGROSSPROFIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_BIGRP_ST}</Premium>
	</coverage>
	<coverage>
		<Indicator>1</Indicator>
		<Type>GRP_BF</Type>
		<Code>BIGRP_BF</Code>
		<Description>Bushfire</Description>
		<limit>
			<Type>GRP_BF</Type>
			<iValue>{ANNUALGROSSPROFIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_BIGRP_BF}</Premium>
	</coverage>   {UW}     <ClaimsIncurred>{BICLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{BICLMCNT}</NumberOfClaims>
	<Premium>{BIEXPPREM}</Premium>   {LOC_BI_CLAUSE}   <ClassCode>
		<APRA>FISR</APRA>
		<Business>BSP</Business>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage> ', N'<coverage>   <Type>BusinessInterruption</Type>      <Description>Business Interruption</Description>   <Indicator>1</Indicator>  
<coverage>    <Type>GRP_SD</Type>    <limit>     <Type>GRP_SD</Type>     <iValue>{ANNUALGROSSPROFIT}</iValue>    </limit>    <Indicator>1</Indicator>    <Code>BIGRP_SD</Code>  
<Description>Standard</Description>          <Premium>{EXP_PREM_BIGRP_SD}</Premium>   </coverage>   <IndemnityPeriod>{INDEMNITYPERIOD}</IndemnityPeriod>   {SUBCOV} 
<Excess>    <Voluntary>{VOLUNTARYEXCESS}</Voluntary>    <Standard>{STANDARDEXCESS}</Standard>    <Imposed>{IMPOSEDEXCESS}</Imposed>   </Excess>   <Code>BI</Code>   
<coverage>    <Indicator>1</Indicator>    <Type>GRP_CY</Type>    <Code>BIGRP_CY</Code>    <Description>Cyclone</Description>    
<limit>     <Type>GRP_CY</Type>     <iValue>{ANNUALGROSSPROFIT}</iValue>    </limit>          <Premium>{EXP_PREM_BIGRP_CY}</Premium> 
</coverage>   <coverage>    <Indicator>1</Indicator>    <Type>GRP_EQ</Type>    <Code>BIGRP_EQ</Code>    <Description>Earthquake</Description>    <limit>     <Type>GRP_EQ</Type>   
<iValue>{ANNUALGROSSPROFIT}</iValue>    </limit>          <Premium>{EXP_PREM_BIGRP_EQ}</Premium>   </coverage>  
<coverage>    <Indicator>1</Indicator>    <Type>GRP_ST</Type>    <Code>BIGRP_ST</Code>    <Description>Storm</Description>    <limit>     <Type>GRP_ST</Type>   
<iValue>{ANNUALGROSSPROFIT}</iValue>    </limit>          <Premium>{EXP_PREM_BIGRP_ST}</Premium>   </coverage>   <coverage>    <Indicator>1</Indicator>    <Type>GRP_BF</Type>  
<Code>BIGRP_BF</Code>    <Description>Bushfire</Description>    <limit>     <Type>GRP_BF</Type>     <iValue>{ANNUALGROSSPROFIT}</iValue>    </limit>          <Premium>{EXP_PREM_BIGRP_BF}</Premium>   </coverage> 
{UW}      <ClaimsIncurred>{BICLMINCD}</ClaimsIncurred>      <NumberOfClaims>{BICLMCNT}</NumberOfClaims>      <Premium>{BIEXPPREM}</Premium>  
{LOC_BI_CLAUSE}   <ClassCode>    <APRA/>    <Business/>   </ClassCode>   <ExpiringPurePremium></ExpiringPurePremium>   <ExpiringPremium></ExpiringPremium>  </coverage>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T09:53:33.2930000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (40, 38, N'BP_Risk_Building_BG_Subcov', N'AGGNE.DEV.RISK_BUILDING_BG_COVERAGES', N'AGGNE.DEV.RISK_BUILDING_BG_TARGET', N'AGGNE.DEV.PA_RISK_BUILDING_BG_COVERAGES', N'AGGNE.DEV.PA_RISK_BUILDING_BG_TARGET', N'
<coverage>
		<Type>{TYPE}</Type>
		<limit>
			<Type>{TYPE}</Type>
			<iValue>{IVALUE}</iValue>
		</limit>
		<Indicator>1</Indicator>
		<Code>{CODE}</Code>
		<Description>{DESCRIPTION}</Description>
       <Premium>{EXP_PREM}</Premium>
	</coverage> 
    {EXCESSINFO}
    {EXTRAINFO}', N'
<coverage>
		<Type>{TYPE}</Type>
		<limit>
			<Type>{TYPE}</Type>
			<iValue>{IVALUE}</iValue>
		</limit>
		<Indicator>1</Indicator>
		<Code>{CODE}</Code>
		<Description>{DESCRIPTION}</Description>
        <Premium>{EXP_PREM}</Premium>
	</coverage> 
    {EXCESSINFO}
    {EXTRAINFO}', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T09:57:20.2220000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (41, 39, N'BP_RISK_BUILDING_BG_UW', N'AGGNE.DEV.RISK_BUILDING_BG_UW', N'AGGNE.DEV.RISK_BUILDING_BG_TARGET', N'AGGNE.DEV.PA_RISK_BUILDING_BG_UW', N'AGGNE.DEV.PA_RISK_BUILDING_BG_TARGET', N'
<UnderwritingAdjustment>
		<Type>{COVERAGE}</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	</Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', N'
<UnderwritingAdjustment>
		<Type>{COVERAGE}</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	</Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T10:04:36.2500000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (42, 40, N'BP_LOC_BG_CLAUSE', N'AGGNE.DEV.LOC_BG_CLAUSE', N'AGGNE.DEV.RISK_BUILDING_BG_TARGET', N'AGGNE.DEV.PA_LOC_BG_CLAUSE', N'AGGNE.DEV.PA_RISK_BUILDING_BG_TARGET', N'
<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	</Clause>', N'
<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	 </Clause>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T10:06:05.1120000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (43, 41, N'BP_RISK_Building_BG', N'AGGNE.DEV.BUILDING_BG_PAYLOAD', N'AGGNE.DEV.RISK_BUILDING_BG_TARGET', N'AGGNE.DEV.PA_BUILDING_BG_PAYLOAD', N'AGGNE.DEV.PA_RISK_BUILDING_BG_TARGET', N'<coverage>
	<Type>{COVERAGE}</Type>
	<Description>Burglary</Description>   {SUBCOV}   <Indicator>{BURGLARY_IND}</Indicator>
	<CoverageLevel>Per Occurrence</CoverageLevel>   {UW}     <ClaimsIncurred>{BBCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{BGCLMCNT}</NumberOfClaims>
	<Premium>{BGEXPPREM}</Premium>   {LOC_BG_CLAUSE}   <ClassCode>
		<APRA>OACC</APRA>
		<Business>OACC</Business>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>', N'<coverage>
	<Type>{COVERAGE}</Type>
	<Description>Burglary</Description>
	<Excess>
		<Imposed>{IMPOSEDEXCESS}</Imposed>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
		<Standard>{STANDARDEXCESS}</Standard>
	</Excess>
	{SUBCOV}   <Indicator>{BURGLARY_IND}</Indicator>
	<CoverageLevel>Per Occurrence</CoverageLevel>   {UW}      <ClaimsIncurred>{BBCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{BGCLMCNT}</NumberOfClaims>
	<Premium>{BGEXPPREM}</Premium>   {LOC_BG_CLAUSE}   <ClassCode>
		<APRA/>
		<Business/>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T10:08:23.6150000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (44, 42, N'BP_Risk_Building_Money_Subcov', N'AGGNE.DEV.RISK_BUILDING_MONEY_COVERAGES', N'AGGNE.DEV.RISK_BUILDING_Money_TARGET', N'AGGNE.DEV.PA_RISK_BUILDING_MONEY_COVERAGES', N'AGGNE.DEV.PA_RISK_BUILDING_Money_TARGET', N'
<coverage>
		<Indicator>{INDICATOR}</Indicator>
		<Type>{TYPE}</Type>
		<Code>{CODE}</Code>
		<Description>{DESCRIPTION}</Description>
		<limit>
			<Type>{TYPE}</Type>
			<iValue>{IVALUE}</iValue>
		</limit>
       <Premium>{EXP_PREM}</Premium>
	</coverage>
    {EXCESSINFO}', N'
<coverage>
		<Indicator>{INDICATOR}</Indicator>
		<Type>{TYPE}</Type>
		<Code>{CODE}</Code>
		<Description>{DESCRIPTION}</Description>
		<limit>
			<Type>{TYPE}</Type>
			<iValue>{IVALUE}</iValue>
		</limit>
        <Premium>{EXP_PREM}</Premium>
	</coverage>
    {EXCESSINFO}', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T10:20:08.9880000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (45, 43, N'BP_RISK_BUILDING_MY_UW', N'AGGNE.DEV.RISK_BUILDING_MY_UW', N'AGGNE.DEV.RISK_BUILDING_Money_TARGET', N'AGGNE.DEV.PA_RISK_BUILDING_MY_UW', N'AGGNE.DEV.PA_RISK_BUILDING_Money_TARGET', N'
<UnderwritingAdjustment>
		<Type>{COVERAGE}</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	</Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', N'
<UnderwritingAdjustment>
		<Type>{COVERAGE}</Type>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	</Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T10:21:43.9950000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (46, 44, N'BP_LOC_MY_CLAUSE', N'AGGNE.DEV.LOC_MY_CLAUSE', N'AGGNE.DEV.RISK_BUILDING_Money_TARGET', N'AGGNE.DEV.PA_LOC_MY_CLAUSE', N'AGGNE.DEV.PA_RISK_BUILDING_Money_TARGET', N'
<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	</Clause>', N'
<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	 </Clause>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T10:23:14.5650000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (47, 45, N'BP_RISK_Building_Money', N'AGGNE.DEV.BUILDING_MONEY_PAYLOAD', N'AGGNE.DEV.RISK_BUILDING_Money_TARGET', N'AGGNE.DEV.PA_BUILDING_MONEY_PAYLOAD', N'AGGNE.DEV.PA_RISK_BUILDING_Money_TARGET', N'<coverage>
	<Type>{COVERAGE}</Type>
	<Description>Money</Description>   {SUBCOV}   <Indicator>{MONEY_IND}</Indicator>
	<CoverageLevel>Per Occurrence</CoverageLevel>
	<IsMoneyStoredInALockedSafe>{ISMONEYSTOREDINALOCKEDSAFE}</IsMoneyStoredInALockedSafe>
	<LocationOMoneyOutsideBusinessHours>{LOCATIONOUTSIDEBUSINESSHOURS}</LocationOMoneyOutsideBusinessHours>   {UW}     <ClaimsIncurred>{MYCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{MYCLMCNT}</NumberOfClaims>
	<Premium>{MYEXPPREM}</Premium>   {LOC_MY_CLAUSE}   <ClassCode>
		<APRA>OACC</APRA>
		<Business>OACC</Business>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>
', N'<coverage>
	<Type>{COVERAGE}</Type>
	<Description>Money</Description>   {SUBCOV}   <Indicator>{MONEY_IND}</Indicator>
	<CoverageLevel>Per Occurrence</CoverageLevel>
	<IsMoneyStoredInALockedSafe>{ISMONEYSTOREDINALOCKEDSAFE}</IsMoneyStoredInALockedSafe>
	<LocationOMoneyOutsideBusinessHours>{LOCATIONOUTSIDEBUSINESSHOURS}</LocationOMoneyOutsideBusinessHours>   {UW}     <ClaimsIncurred>{MYCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{MYCLMCNT}</NumberOfClaims>
	<Premium>{MYEXPPREM}</Premium>   {LOC_MY_CLAUSE}   <ClassCode>
		<APRA/>
		<Business/>
	</ClassCode>
	<Excess>
			<Standard>{STANDARDEXCESS}</Standard>
			<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
			<Imposed>{IMPOSEDEXCESS}</Imposed>
			<Amount/>
	</Excess>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T10:26:53.8570000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (48, 46, N'BP_Risk_Building_EN_Subcov', N'AGGNE.DEV.RISK_BUILDING_EN_COVERAGES', N'AGGNE.DEV.RISK_BUILDING_EN_TARGET', N'AGGNE.DEV.PA_RISK_BUILDING_EN_COVERAGES', N'AGGNE.DEV.PA_RISK_BUILDING_EN_TARGET', N'
<coverage>
		<Indicator>{INDICATOR}</Indicator>
		<Type>{TYPE}</Type>
		<Code>{CODE}</Code>
		<Description>{DESCRIPTION}</Description>
		<limit>
			<Type>{TYPE}</Type>
			<iValue>{IVALUE}</iValue>
		</limit>
       <Premium>{EXP_PREM}</Premium>
	</coverage>
    {EXCESSINFO}', N'
<coverage>
		<Indicator>{INDICATOR}</Indicator>
		<Type>{TYPE}</Type>
		<Code>{CODE}</Code>
		<Description>{DESCRIPTION}</Description>
		<limit>
			<Type>{TYPE}</Type>
			<iValue>{IVALUE}</iValue>
		</limit>
        <Premium>{EXP_PREM}</Premium>
	</coverage>
    {EXCESSINFO}', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T10:30:38.9380000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (49, 47, N'BP_RISK_BUILDING_EN_UW', N'AGGNE.DEV.RISK_BUILDING_EN_UW', N'AGGNE.DEV.RISK_BUILDING_EN_TARGET', N'AGGNE.DEV.PA_RISK_BUILDING_EN_UW', N'AGGNE.DEV.PA_RISK_BUILDING_EN_TARGET', N'
<UnderwritingAdjustment>
		<Type>{COVERAGE}</Type>
		<IsUWAdjReadOnly/>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	</Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', N'
<UnderwritingAdjustment>
		<Type>{COVERAGE}</Type>
		<IsUWAdjReadOnly/>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	</Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T10:34:07.2530000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (50, 48, N'BP_LOC_EN_CLAUSE', N'AGGNE.DEV.LOC_EN_CLAUSE', N'AGGNE.DEV.RISK_BUILDING_EN_TARGET', N'AGGNE.DEV.PA_LOC_EN_CLAUSE', N'AGGNE.DEV.PA_RISK_BUILDING_EN_TARGET', N'
<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	</Clause>', N'
<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	 </Clause>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T10:36:46.7210000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (51, 49, N'BP_RISK_Building_EN', N'AGGNE.DEV.BUILDING_EN_PAYLOAD', N'AGGNE.DEV.RISK_BUILDING_EN_TARGET', N'AGGNE.DEV.PA_BUILDING_EN_PAYLOAD', N'AGGNE.DEV.PA_RISK_BUILDING_EN_TARGET', N'<coverage>
	<Type>{COVERAGE}</Type>
	<Description>Engineering</Description>   {SUBCOV}   <Indicator>{ENGINEERING_IND}</Indicator>
	<EquipmentRegularlyMaintainedAndMaintenanceRecordsKept>{EQUIPMENTREGULAR}</EquipmentRegularlyMaintainedAndMaintenanceRecordsKept>
	<AverageAgeOfEquipment>{AVERAGEAGEOFEQUIPMENT}</AverageAgeOfEquipment>
	<AgeOfTheOldestPieceOfEquipmentWorthMorethan5000>{AGEOFTHEOLDEST}</AgeOfTheOldestPieceOfEquipmentWorthMorethan5000>   {UW}     <ClaimsIncurred>{ENCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{ENCLMCNT}</NumberOfClaims>
	<Premium>{ENEXPPREM}</Premium>  {LOC_EN_CLAUSE}  <ClassCode>
		<APRA>OACC</APRA>
		<Business>OACC</Business>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>
', N'<coverage>
	<Type>{COVERAGE}</Type>
	<Description>Engineering</Description>   {SUBCOV}   <Indicator>{ENGINEERING_IND}</Indicator>
	<EquipmentRegularlyMaintainedAndMaintenanceRecordsKept>{EQUIPMENTREGULAR}</EquipmentRegularlyMaintainedAndMaintenanceRecordsKept>
	<AverageAgeOfEquipment>{AVERAGEAGEOFEQUIPMENT}</AverageAgeOfEquipment>
	<AgeOfTheOldestPieceOfEquipmentWorthMorethan5000>{AGEOFTHEOLDEST}</AgeOfTheOldestPieceOfEquipmentWorthMorethan5000>   {UW}     <ClaimsIncurred>{ENCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{ENCLMCNT}</NumberOfClaims>
	<Premium>{ENEXPPREM}</Premium>  {LOC_EN_CLAUSE}  <ClassCode>
		<Code>EN</Code>
		<APRA/>
		<Business/>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
	<Excess>
		<Standard>{STANDARDEXCESS}</Standard>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
		<Imposed>{IMPOSEDEXCESS}</Imposed>
		<Amount/>
	</Excess>
</coverage>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T10:40:44.5350000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (52, 50, N'BP_Risk_Building_BC_Subcov', N'AGGNE.DEV.RISK_BUILDING_BC_COVERAGES', N'AGGNE.DEV.RISK_Building_BC_TARGET', N'AGGNE.DEV.PA_RISK_BUILDING_BC_COVERAGES', N'AGGNE.DEV.PA_RISK_Building_BC_TARGET', N'
<coverage>
		<Type>{TYPE}</Type>
		{SVALUE}
		<Indicator>{INDICATOR}</Indicator>
		<Code>{CODE}</Code>
		<Description>{DESCRIPTION}</Description>
		<limit>
			<Type>{TYPE}</Type>
			<iValue>{IVALUE}</iValue>
		</limit>
       <Premium>{EXP_PREM}</Premium>
	</coverage>', N'
<coverage>
		<Type>{TYPE}</Type>
		{SVALUE}
		<Indicator>{INDICATOR}</Indicator>
		<Code>{CODE}</Code>
		<Description>{DESCRIPTION}</Description>
		<limit>
			<Type>{TYPE}</Type>
			<iValue>{IVALUE}</iValue>
		</limit>
        <Premium>{EXP_PREM}</Premium>
	</coverage>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T10:43:27.3250000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (53, 51, N'BP_RISK_BUILDING_BC_UW', N'AGGNE.DEV.RISK_BUILDING_BC_UW', N'AGGNE.DEV.RISK_Building_BC_TARGET', N'AGGNE.DEV.PA_RISK_BUILDING_BC_UW', N'AGGNE.DEV.PA_RISK_Building_BC_TARGET', N'
<UnderwritingAdjustment>
		<Type>{COVERAGE}</Type>
		<IsUWAdjReadOnly/>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	</Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>;', N'
<UnderwritingAdjustment>
		<Type>{COVERAGE}</Type>
		<IsUWAdjReadOnly/>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	</Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T10:46:07.5810000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (54, 52, N'BP_LOC_BC_CLAUSE', N'AGGNE.DEV.LOC_BC_CLAUSE', N'AGGNE.DEV.RISK_Building_BC_TARGET', N'AGGNE.DEV.PA_LOC_BC_CLAUSE', N'AGGNE.DEV.PA_RISK_Building_BC_TARGET', N'
<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	</Clause>', N'
<Clause>
			<Type>{DCCLAUSETYPE}</Type>
			<Indicator>1</Indicator>
			<Description>{DCINPUT}</Description>
			<DisableFlag>1</DisableFlag>
	 </Clause>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T10:48:34.0520000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (55, 53, N'BP_RISK_Building_BC', N'AGGNE.DEV.BUILDING_BC_PAYLOAD', N'AGGNE.DEV.RISK_Building_BC_TARGET', N'AGGNE.DEV.PA_BUILDING_BC_PAYLOAD', N'AGGNE.DEV.PA_RISK_Building_BC_TARGET', N'<coverage>
	<Type>{COVERAGE}</Type>
	<Description>Business Contents</Description>
	<Indicator>{BUSINESSCONTENTS_IND}</Indicator>
	<CoverageLevel>Per Occurrence</CoverageLevel>
	<Excess>
		<Flood/>
		<Earthquake/>
		<Imposed/>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
		<Hail/>
		<Standard/>
		<Amount/>
	</Excess>   {SUBCOV}   <MaliciousDamagetoStockCustomerVehiclesWatercraft/>
	<Code>BC</Code>
	<contentsd/>
	<coverage>
		<Indicator>1</Indicator>
		<Type>STD_BF</Type>
		<Code>BCSTD_BF</Code>
		<Description>Bushfire</Description>
		<limit>
			<Type>STD_BF</Type>
			<iValue>{CONTENTSLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_BCSTD_BF}</Premium>
	</coverage>
	<coverage>
		<Indicator>1</Indicator>
		<Type>STD_CY</Type>
		<Code>BCSTD_CY</Code>
		<Description>Cyclone</Description>
		<limit>
			<Type>STD_CY</Type>
			<iValue>{CONTENTSLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_BCSTD_CY}</Premium>
	</coverage>
	<coverage>
		<Indicator>1</Indicator>
		<Type>STD_EQ</Type>
		<Code>BCSTD_EQ</Code>
		<Description>Earthquake</Description>
		<limit>
			<Type>STD_EQ</Type>
			<iValue>{CONTENTSLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_BCSTD_EQ}</Premium>
	</coverage>
	<coverage>
		<Indicator>1</Indicator>
		<Type>STD_ST</Type>
		<Code>BCSTD_ST</Code>
		<Description>Storm</Description>
		<limit>
			<Type>STD_ST</Type>
			<iValue>{CONTENTSLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_BCSTD_ST}</Premium>
	</coverage>
	<coverage>
		<Indicator>1</Indicator>
		<Type>HAL_SD</Type>
		<Code>BCHAL_SD</Code>
		<Description>Hail</Description>
		<limit>
			<Type>HAL_SD</Type>
			<iValue>{HAILDAMAGE}</iValue>
		</limit>
		<Premium>{EXP_PREM_BCHAL_SD}</Premium>
	</coverage>
	<coverage>
		<Type>LND_SD</Type>
		<limit>
			<Type>LND_SD</Type>
			<iValue>{LANDSLIDELIMIT}</iValue>
		</limit>
		<Indicator>{LND_SD_INDICATOR}</Indicator>
		<Code>BCLND_SD</Code>
		<Description>Landslide</Description>
	</coverage>
	<WhatProportionOfTheLotIsCoveredByHailNetting>{PROPORTIONOFHAILNETTING}</WhatProportionOfTheLotIsCoveredByHailNetting>   {UW}     <ClaimsIncurred>{BCCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{BCCLMCNT}</NumberOfClaims>
	<Premium>{BCEXPPREM}</Premium>   {LOC_BC_CLAUSE}   <ClassCode>
		<APRA>FISR</APRA>
		<Business>BSP</Business>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>

', N'<coverage>
	<Type>{COVERAGE}</Type>
	<Indicator>{BUSINESSCONTENTS_IND}</Indicator>
	<CoverageLevel>Per Occurrence</CoverageLevel>
	<Excess>
		<Flood>{FLOODEXCESS}</Flood>
		<Earthquake>{EARTHQUAKEEXCESS}</Earthquake>
		<Imposed>{IMPOSEDEXCESS}</Imposed>
		<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
		<Hail>{HAILDAMAGEEXCESS}</Hail>
		<Standard>{STANDARDEXCESS}</Standard>
		<Amount/>
	</Excess>   {SUBCOV}   <MaliciousDamagetoStockCustomerVehiclesWatercraft/>
	<Code>BC</Code>
	<contentsd/>
	<coverage>
		<Indicator>1</Indicator>
		<Type>STD_BF</Type>
		<Code>BCSTD_BF</Code>
		<Description>Bushfire</Description>
		<limit>
			<Type>STD_BF</Type>
			<iValue>{CONTENTSLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_BCSTD_BF}</Premium>
	</coverage>
	<coverage>
		<Indicator>1</Indicator>
		<Type>STD_CY</Type>
		<Code>BCSTD_CY</Code>
		<Description>Cyclone</Description>
		<limit>
			<Type>STD_CY</Type>
			<iValue>{CONTENTSLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_BCSTD_CY}</Premium>
	</coverage>
	<coverage>
		<Indicator>1</Indicator>
		<Type>STD_EQ</Type>
		<Code>BCSTD_EQ</Code>
		<Description>Earthquake</Description>
		<limit>
			<Type>STD_EQ</Type>
			<iValue>{CONTENTSLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_BCSTD_EQ}</Premium>
	</coverage>
	<coverage>
		<Indicator>1</Indicator>
		<Type>STD_ST</Type>
		<Code>BCSTD_ST</Code>
		<Description>Storm</Description>
		<limit>
			<Type>STD_ST</Type>
			<iValue>{CONTENTSLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_BCSTD_ST}</Premium>
	</coverage>
	<coverage>
		<Indicator>1</Indicator>
		<Type>HAL_ST</Type>
		<Code>BCHAL_ST</Code>
		<Description>Hail Storm</Description>
		<limit>
			<Type>HAL_ST</Type>
			<iValue>{CONTENTSLIMIT}</iValue>
		</limit>
		<Premium>{EXP_PREM_BCHAL_ST}</Premium>
	</coverage>
	<WhatProportionOfTheLotIsCoveredByHailNetting>{PROPORTIONOFHAILNETTING}</WhatProportionOfTheLotIsCoveredByHailNetting>   {UW}      <ClaimsIncurred>{BCCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{BCCLMCNT}</NumberOfClaims>
	<Premium>{BCEXPPREM}</Premium>   {LOC_BC_CLAUSE}   <ClassCode>
		<APRA/>
		<Business/>
	</ClassCode>
	<ExpiringPurePremium/>
	<ExpiringPremium/>
</coverage>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T10:53:03.1700000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (56, 54, N'BP_RISK_LOCATION_UW_COMBINE', N'AGGNE.DEV.RISK_LOCATION_UW_COMBINE', N'AGGNE.DEV.RISK_BUILDING_FINAL_TARGET', N'AGGNE.DEV.PA_RISK_LOCATION_UW_COMBINE', N'AGGNE.DEV.PA_RISK_BUILDING_FINAL_TARGET', N'
<UnderwritingAdjustment>
		<Type>Property</Type>
		<IsUWAdjReadOnly/>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	</Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', N'
<UnderwritingAdjustment>
		<Type>Property</Type>
		<IsUWAdjReadOnly/>
		<AdjustmentSelection>{ADJUSTMENTSELECTION}</AdjustmentSelection>
		<AdjustmentDollarAndPercent>{ADJUSTMENTDOLLARANDPERCENT}</AdjustmentDollarAndPercent>
		<AdjustmentAmount></AdjustmentAmount>
		<Recurring>
		<Indicator>{RECURRINGINDICATOR}</Indicator>
	</Recurring>
		<UnderwritingDescription>{UNDERWRITINGDESCRIPTION}</UnderwritingDescription>
	</UnderwritingAdjustment>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T10:56:14.6830000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (57, 55, N'BP_RISK_Building', N'AGGNE.DEV.RISK_BUILDING_FINAL', N'AGGNE.DEV.RISK_BUILDING_FINAL_TARGET', N'AGGNE.DEV.PA_RISK_BUILDING_FINAL', N'AGGNE.DEV.PA_RISK_BUILDING_FINAL_TARGET', N'<risk>
	<Type>Building</Type>
	<LocationNumber>{RISKNUMBER}</LocationNumber>
	<SICCode>{SICCODE}</SICCode>
	<NumberOfSprayBoothsAtThisLocation>{NOOFSPRAYBOOTHS}</NumberOfSprayBoothsAtThisLocation>
	<Condition>{SMASHREPAIR_CONDITION}</Condition>
	<IsTheSurroundingAreaFreeOfAccelerantsAndHeatWork>{SURRAREAFREEOFHEATWORK}</IsTheSurroundingAreaFreeOfAccelerantsAndHeatWork>
	<SurroundingAreaHousekeeping>{SURRAREAHOUSEKEEP}</SurroundingAreaHousekeeping>
	<MixingRoomHousekeeping>{MIXINGRMHOUSEKEEP}</MixingRoomHousekeeping>
	<OldestBoothAgeYears>{AGEOFOLDESTBOOTH}</OldestBoothAgeYears>
	<ApproximateReplacementCostOfHighestValueBooth>{REPLACECOST}</ApproximateReplacementCostOfHighestValueBooth>
	<YearOfLastProfessionalService/>
	<IsThereEvidenceOfRegularBoothCleaningOrServicing>{REGULARSERVICELOG}</IsThereEvidenceOfRegularBoothCleaningOrServicing>
	<IsBoothInteriorWallProtectionUsed>{INTERIORWALLPROTECTIONUSED}</IsBoothInteriorWallProtectionUsed>
	<HasTheExhaustFanBeenReconditionedOrReplacedInTheLast5yrs>{EXHAUSTFANREPLACED}</HasTheExhaustFanBeenReconditionedOrReplacedInTheLast5yrs>
	<DismantlerFloorCondition>{FLOORCONDITION}</DismantlerFloorCondition>
	<DismantlerAreaHousekeeping>{DISMANTLEAREAHOUSEKEEP}</DismantlerAreaHousekeeping>
	<LocationOfDefueling>{DEFUELLOCATION}</LocationOfDefueling>
	<LocationOfDismantlingArea>{DISMANTLELOC}</LocationOfDismantlingArea>
	<AreHoistsUsedForDismantling>{HOISTSUSED}</AreHoistsUsedForDismantling>
	<FireSuppressionEquipmentNearDismantlingAreas>{FIREEQUIPNEAR}</FireSuppressionEquipmentNearDismantlingAreas>
	<IsMetalRecyclingConductedOnSite>{METALRECYCLEONSITE}</IsMetalRecyclingConductedOnSite>
	<AreMetalRecyclingActivitiesConductedInsideABuilding>{METALRECYCLEINSIDE}</AreMetalRecyclingActivitiesConductedInsideABuilding>
	<StockStorageHousekeeping>{STOCKHOUSEKEEPING}</StockStorageHousekeeping>
	<TyresOrBatteriesStorageHousekeeping>{TYRESBATTERIESHOUSEKEEP}</TyresOrBatteriesStorageHousekeeping>
	<StorageOfEVsAndTheirBatteries>{EVSTORAGE}</StorageOfEVsAndTheirBatteries>
	<AreVehiclesStackedOrRacked>{VEHICLESSTACKED}</AreVehiclesStackedOrRacked>
	<HowIsFuelStored>{FUELSTORE}</HowIsFuelStored>
	<AverageNumberOfVehiclesInTheYard>{AVGNOVEHSSTORED}</AverageNumberOfVehiclesInTheYard>
	<YardFloorOrHousekeeping>{YARDFLOORHOUSEKEEP}</YardFloorOrHousekeeping>
	<ClearLandSqm>{CLEARLANDSQM}</ClearLandSqm>
	<AdequateSecurityForOvernightStorage>{ADEQUATESECOVSTORAGE}</AdequateSecurityForOvernightStorage>
	<HighRiskSpecialisedEquipment>{HIGHRISKSPECIALISEDEQUIP}</HighRiskSpecialisedEquipment>
	<Detail>{DETAILSHIGHRISKSPECEQUIP}</Detail>
	<EvidenceOfInadequateFuelStorageProcedures>{INADEQUATEFUELSTORAGE}</EvidenceOfInadequateFuelStorageProcedures>
	<AreThereMoreThanAFewTyresStackedUpAgainstTheBuilding>{MORETHANFEWTYRESTACK}</AreThereMoreThanAFewTyresStackedUpAgainstTheBuilding>
	<VolumeOfTyresStackedOutside>{VOLTYRESTACK}</VolumeOfTyresStackedOutside>
	<VolumeOfTyresStackedInside>{VOLTYRESTACKIN}</VolumeOfTyresStackedInside>
	<AreTheTyresOutsideStoredInAnOrderlyManner>{TYRESTOREDOUTORDERLY}</AreTheTyresOutsideStoredInAnOrderlyManner>
	<IsExcessiveOilResiduePresentOnTheOutsideGround>{EXCOILRESIDUEOUT}</IsExcessiveOilResiduePresentOnTheOutsideGround>
	<SatisfactoryRiskMitigationProcessesEvident>{SATISFACTORYRISKMITIGATION}</SatisfactoryRiskMitigationProcessesEvident>
	<StandardExcess/>
	<ImposedExcess/>
	<IsBuildingHeritage>0</IsBuildingHeritage>
	<AmoutOfEPS>0</AmoutOfEPS>
	<ExternalDoors>1</ExternalDoors>
	<SecurityAccessibleWindows>1</SecurityAccessibleWindows>
	<SecurityAlarm>0</SecurityAlarm>
	<VehicleYardShowingAnySecurity>0</VehicleYardShowingAnySecurity>
	<VehicleKeyStorage>0</VehicleKeyStorage>
	<HireVehicleContractSupplied>0</HireVehicleContractSupplied>
	<LocationANZSICCode>{LOCATIONANZSICCODE}</LocationANZSICCode>
	<LocationConnectedToTownWaterMain>0</LocationConnectedToTownWaterMain>
	<StoreFlammableGoods>0</StoreFlammableGoods>
	<WhatQuantity/>
	<IsAusStandardFollowed>1</IsAusStandardFollowed>
	<VoluntaryExcess/>   {RISK_BUILDING}   {RISK_BC}   {RISK_BI}    {RISK_BG}   {RISK_MONEY}   {RISK_EN}   <LocationAggregatePropertyLimit/>
	<RoofConstruction>{ROOFCONSTRUCTION_FINAL}</RoofConstruction>
	<WhatYearWasTheBuildingConstructed>{YEARBUILDINGCONSTRUCTED}</WhatYearWasTheBuildingConstructed>
	<RoofSqmAon>0</RoofSqmAon>
	<OccupationOfHighestRiskTenant/>
	<YearTheBuildingWasLastReWired>{YEARLASTREWIRED}</YearTheBuildingWasLastReWired>
	<YearTheBuildingWasLastRePlumbed/>
	<YearTheBuildingWasLastReRoofed/>
	<MainWallConstruction>{MAINWALLCONSTRUCTION_FINAL}</MainWallConstruction>
	<FloorConstruction>{FLOORCONSTRUCTION_FINAL}</FloorConstruction>
	<YearLastReWiredCalculation/>
	<WhatTypeOfAlarmSystemIsInstalled>{ALARMSYSTEMINSTALLED_FINAL}</WhatTypeOfAlarmSystemIsInstalled>
	<DoYouHaveSecurityCamerasOrCCTVInstalled>{SECURITYCAMERAS_FINAL}</DoYouHaveSecurityCamerasOrCCTVInstalled>
	<IsThereATwoMeterHighPerimeterFenceEnclosingThePremises>{TWOMETERHIGHPERIMETERFENCE_FINAL}</IsThereATwoMeterHighPerimeterFenceEnclosingThePremises>
	<AreSecurityBollardsInPlace>{SECURITYBOLLARDS_FINAL}</AreSecurityBollardsInPlace>
	<AreYourPremisesPatrolledByASecurityGuard>{PATROLLEDBYASECURITYGUARD_FINAL}</AreYourPremisesPatrolledByASecurityGuard>
	<AreDeadlocksInstalledOnAllExternalDoors>{DEADLOCKSINSTALLED_FINAL}</AreDeadlocksInstalledOnAllExternalDoors>
	<IsThereExteriorSecurityLighting>{EXTERIORSECURITYLIGHTING_FINAL}</IsThereExteriorSecurityLighting>
	<BarsOrGrillsInstalledOnAllWindows>{BARSORGRILLSINSTALLED_FINAL}</BarsOrGrillsInstalledOnAllWindows>
	<TwentyFourHoursAttendanceOnSite>{TWENTYFOURHOURSATTENDANCE_FINAL}</TwentyFourHoursAttendanceOnSite>
	<WhatYearWasARiskAssessmentReviewLastUndertaken>2025</WhatYearWasARiskAssessmentReviewLastUndertaken>
	<ConditionOfBuilding>{CONDITIONOFBUILDING}</ConditionOfBuilding>
	<ConditionOfRoof>{CONDITIONOFROOF}</ConditionOfRoof>
	<RoofConstructionAon/>
	<LandSqm/>
	<DismatlingScore/>
	<PremisesScore/>
	<StorageScore/>
	<TotalDismantlerScore/>
	<PropertyInputGeocodeURL/>
	<BuildingName/>
	<ExpiringPremium/>   {UW_COMBINE}  </risk>', N'
<risk deleted="0">
	<Type>Building</Type>
	<LocationNumber>{RISKNUMBER}</LocationNumber>
	<SICCode>Mobile Mechanic</SICCode>
	<NumberOfSprayBoothsAtThisLocation/>
	<Condition/>
	<IsTheSurroundingAreaFreeOfAccelerantsAndHeatWork/>
	<SurroundingAreaHousekeeping/>
	<MixingRoomHousekeeping/>
	<OldestBoothAgeYears/>
	<ApproximateReplacementCostOfHighestValueBooth/>
	<YearOfLastProfessionalService/>
	<IsThereEvidenceOfRegularBoothCleaningOrServicing/>
	<IsBoothInteriorWallProtectionUsed/>
	<HasTheExhaustFanBeenReconditionedOrReplacedInTheLast5yrs/>
	<DismantlerFloorCondition/>
	<DismantlerAreaHousekeeping/>
	<LocationOfDefueling/>
	<LocationOfDismantlingArea/>
	<AreHoistsUsedForDismantling/>
	<FireSuppressionEquipmentNearDismantlingAreas/>
	<IsMetalRecyclingConductedOnSite/>
	<AreMetalRecyclingActivitiesConductedInsideABuilding/>
	<StockStorageHousekeeping/>
	<TyresOrBatteriesStorageHousekeeping/>
	<StorageOfEVsAndTheirBatteries/>
	<AreVehiclesStackedOrRacked/>
	<HowIsFuelStored/>
	<AverageNumberOfVehiclesInTheYard/>
	<YardFloorOrHousekeeping/>
	<ClearLandSqm/>
	<AdequateSecurityForOvernightStorage/>
	<HighRiskSpecialisedEquipment/>
	<Detail/>
	<EvidenceOfInadequateFuelStorageProcedures/>
	<AreThereMoreThanAFewTyresStackedUpAgainstTheBuilding/>
	<VolumeOfTyresStackedOutside/>
	<VolumeOfTyresStackedInside/>
	<AreTheTyresOutsideStoredInAnOrderlyManner/>
	<IsExcessiveOilResiduePresentOnTheOutsideGround/>
	<SatisfactoryRiskMitigationProcessesEvident/>
	<StandardExcess/>
	<ImposedExcess/>
	<IsBuildingHeritage>0</IsBuildingHeritage>
	<AmoutOfEPS>0</AmoutOfEPS>
	<ExternalDoors>1</ExternalDoors>
	<SecurityAccessibleWindows>1</SecurityAccessibleWindows>
	<SecurityAlarm>0</SecurityAlarm>
	<VehicleYardShowingAnySecurity>0</VehicleYardShowingAnySecurity>
	<VehicleKeyStorage>0</VehicleKeyStorage>
	<HireVehicleContractSupplied>0</HireVehicleContractSupplied>
	<LocationANZSICCode>{LOCATIONANZSICCODE}</LocationANZSICCode>
	<LocationConnectedToTownWaterMain>0</LocationConnectedToTownWaterMain>
	<StoreFlammableGoods>0</StoreFlammableGoods>
	<WhatQuantity/>
	<IsAusStandardFollowed>1</IsAusStandardFollowed>
	<VoluntaryExcess></VoluntaryExcess>
	{RISK_BUILDING}
	{RISK_BC}
	{RISK_BI}	
	{RISK_BG}
	{RISK_MONEY}
	{RISK_EN}
	<LocationAggregatePropertyLimit/>
	<RoofConstruction>Concrete</RoofConstruction>
	<WhatYearWasTheBuildingConstructed>1900</WhatYearWasTheBuildingConstructed>
	<RoofSqmAon>0</RoofSqmAon>
	<OccupationOfHighestRiskTenant/>
	<YearTheBuildingWasLastReWired>{YEARLASTREWIRED}</YearTheBuildingWasLastReWired>
	<YearTheBuildingWasLastRePlumbed></YearTheBuildingWasLastRePlumbed>
	<YearTheBuildingWasLastReRoofed></YearTheBuildingWasLastReRoofed>
	<MainWallConstruction>{MAINWALLCONSTRUCTION_FINAL}</MainWallConstruction>
	<FloorConstruction>{FLOORCONSTRUCTION_FINAL}</FloorConstruction>
	<YearLastReWiredCalculation></YearLastReWiredCalculation>
	<WhatTypeOfAlarmSystemIsInstalled>{ALARMSYSTEMINSTALLED_FINAL}</WhatTypeOfAlarmSystemIsInstalled>
	<DoYouHaveSecurityCamerasOrCCTVInstalled>{SECURITYCAMERAS_FINAL}</DoYouHaveSecurityCamerasOrCCTVInstalled>
	<IsThereATwoMeterHighPerimeterFenceEnclosingThePremises>{TWOMETERHIGHPERIMETERFENCE_FINAL}</IsThereATwoMeterHighPerimeterFenceEnclosingThePremises>
	<AreSecurityBollardsInPlace>{SECURITYBOLLARDS_FINAL}</AreSecurityBollardsInPlace>
	<AreYourPremisesPatrolledByASecurityGuard>{PATROLLEDBYASECURITYGUARD_FINAL}</AreYourPremisesPatrolledByASecurityGuard>
	<AreDeadlocksInstalledOnAllExternalDoors>{DEADLOCKSINSTALLED_FINAL}</AreDeadlocksInstalledOnAllExternalDoors>
	<IsThereExteriorSecurityLighting>{EXTERIORSECURITYLIGHTING_FINAL}</IsThereExteriorSecurityLighting>
	<BarsOrGrillsInstalledOnAllWindows>{BARSORGRILLSINSTALLED_FINAL}</BarsOrGrillsInstalledOnAllWindows>
	<TwentyFourHoursAttendanceOnSite>{TWENTYFOURHOURSATTENDANCE_FINAL}</TwentyFourHoursAttendanceOnSite>
	<WhatYearWasARiskAssessmentReviewLastUndertaken>2025</WhatYearWasARiskAssessmentReviewLastUndertaken>
	<ConditionOfBuilding/>
	<ConditionOfRoof>{CONDITIONOFROOF}</ConditionOfRoof>
	<RoofConstructionAon/>
	<LandSqm></LandSqm>
	<DismatlingScore></DismatlingScore>
	<PremisesScore></PremisesScore>
	<StorageScore></StorageScore>
	<TotalDismantlerScore></TotalDismantlerScore>
	<PropertyInputGeocodeURL/>
	<BuildingName/>
	<ExpiringPremium></ExpiringPremium>
	{UW_COMBINE}
</risk>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T10:59:23.8990000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (58, 56, N'BP_fleet_coverage_Vehicle_SubCov', N'AGGNE.DEV.FLEET_VEHICLE_SUBCOVERAGES', N'AGGNE.DEV.RISK_FLEET_VEHICLE_TARGET', N'AGGNE.DEV.FLEET_VEHICLE_SUBCOVERAGES_POLICYATTACH', N'AGGNE.DEV.RISK_FLEET_VEHICLE_TARGET_POLICY_ATTACH', N'
<coverage>
<Indicator>1</Indicator>
<limit>
<Type>{FLTYPE}</Type>
<iValue>{ACCESSORIESVALUE}</iValue>
</limit>
<Type>{FLTYPE}</Type>
<Code>{FLCODE}</Code>
<Description>{PROTECTIONTYPE}</Description>
<Premium>{EXPPREMIUM}</Premium>
</coverage>', N'
<coverage>
<Indicator>1</Indicator>
<limit>
<Type>{FLTYPE}</Type>
<iValue>{ACCESSORIESVALUE}</iValue>
</limit>
<Type>{FLTYPE}</Type>
<Code>{FLCODE}</Code>
<Description>{VALUE}</Description>
<Premium>{EXPPREMIUM}</Premium>
</coverage>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T11:34:09.2600000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (59, 57, N'BP_Fleet_Vehicle_coverage', N'AGGNE.DEV.FLEET_VEHICLE_VIEW', N'AGGNE.DEV.RISK_FLEET_VEHICLE_TARGET', N'AGGNE.DEV.FLEET_VEHICLE_VIEW_POLICYATTACH', N'AGGNE.DEV.RISK_FLEET_VEHICLE_TARGET_POLICY_ATTACH', N'
<Vehicle>
   <Type>FleetVehicle</Type>
   <State>{REGISTRATIONSTATE}</State>
   <Year>{YEAR}</Year>
   <Make>{MAKE}</Make>
   <Model>{MODEL}</Model>
   <ImportType>N/A</ImportType>
   <Segment>car</Segment>
   <IsUploadDataReadOnly>1</IsUploadDataReadOnly>
   <RegoStatus></RegoStatus>
   <Status>0</Status>
   <ReadOnlyFlagForFleetData>1</ReadOnlyFlagForFleetData>
   <coverage>
       <Type>FleetVehicle</Type>
       <Indicator>1</Indicator>
       <limit>
           <Type>FleetVehicle</Type>
           <iValue>0</iValue>
       </limit>
       <ClassCode>
           <APRA>CMV</APRA>
           <Business>CMV</Business>
       </ClassCode>
       <Code>FL</Code>
       <Description>Fleet Vehicle</Description>
        {SUBCOV_XML}
   </coverage>
   <Registration>{REGISTRATIONNUMBER}</Registration>
   <VehicleDescription>{VEHICLEDESCRIPTION}</VehicleDescription>
   <MarketValue></MarketValue>
   <HighestRiskUse>{HIGHESTRISKUSE}</HighestRiskUse>
   <VehicleAccessoriesDescription>{ACCESSORIESDESCRIPTION}</VehicleAccessoriesDescription>
   <VehicleAccessoriesValue>{ACCESSORIESVALUE_FLEET}</VehicleAccessoriesValue>
   <AdditonalParty>{ADDITONALPARTY}</AdditonalParty>
   <FleetVehicleOverrideInfo>0</FleetVehicleOverrideInfo>
   <Description>{DESCRIPTION}</Description>
   <BodyType>{BODYTYPE}</BodyType>
   <EngineSize>{ENGINESIZE}</EngineSize>
   <NumberOfCylinders>{NUMBEROFCYLINDERS}</NumberOfCylinders>
   <InductionType>{INDUCTIONTYPE}</InductionType>
   <GrossVehicleMass>{GROSSVEHICLEMASS}</GrossVehicleMass>
   <AddAccessoriesOrModification>{ADDACCESSORIES}</AddAccessoriesOrModification>
   <MarketValueWithAccessories>{ACCESSORIESVALUE_FLEET}</MarketValueWithAccessories>
   <HaveInterestedParty>{HAVEINTERESTEDPARTY}</HaveInterestedParty>
   <ModelOther/>
   <MakeOther/>
   <FuelType/>
   <PowerKW/>
   <TrackRear/>
   <limit>
       <Type>LegalLiability</Type>
       <iValue></iValue>
   </limit>
   <VehicleType/>
   <DriveDescription/>
	<ClaimsIncurred>{FVCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{FVCLMCNT}</NumberOfClaims>
	<Premium>{FVEXPPREM}</Premium>
</Vehicle>', N'<Vehicle>
	<Type>FleetVehicle</Type>
	<State>{REGISTRATIONSTATE}</State>
	<Year>{YEAR}</Year>
	<Make>{MAKE}</Make>
	<Model>{MODEL}</Model>
	<ImportType>N/A</ImportType>
	<Segment>car</Segment>
	<IsUploadDataReadOnly>1</IsUploadDataReadOnly>
	<RegoStatus/>
	<Status>0</Status>
	<ReadOnlyFlagForFleetData>1</ReadOnlyFlagForFleetData>
	<coverage>
		<Type>FleetVehicle</Type>
		<Indicator>1</Indicator>
		<limit>
			<Type>FleetVehicle</Type>
			<iValue>0</iValue>
		</limit>
		<ClassCode>
			<APRA>CMV</APRA>
			<Business>CMV</Business>
		</ClassCode>
		<Code>FL</Code>
		<Description>Fleet Vehicle</Description>          {SUBCOV_XML}      </coverage>
	<Registration>{REGISTRATIONNUMBER}</Registration>
	<VehicleDescription>{VEHICLEDESCRIPTION}</VehicleDescription>
	<MarketValue/>
	<HighestRiskUse>{HIGHESTRISKUSE}</HighestRiskUse>
	<VehicleAccessoriesDescription>{ACCESSORIESDESCRIPTION}</VehicleAccessoriesDescription>
	<VehicleAccessoriesValue>{ACCESSORIESVALUE_FLEET}</VehicleAccessoriesValue>
	<AdditonalParty>{ADDITONALPARTY}</AdditonalParty>
	<FleetVehicleOverrideInfo>0</FleetVehicleOverrideInfo>
	<Description>{DESCRIPTION}</Description>
	<BodyType>{BODYTYPE}</BodyType>
	<EngineSize>{ENGINESIZE}</EngineSize>
	<NumberOfCylinders>{NUMBEROFCYLINDERS}</NumberOfCylinders>
	<InductionType>{INDUCTIONTYPE}</InductionType>
	<GrossVehicleMass>{GROSSVEHICLEMASS}</GrossVehicleMass>
	<AddAccessoriesOrModification>{ADDACCESSORIES}</AddAccessoriesOrModification>
	<MarketValueWithAccessories>{ACCESSORIESVALUE_FLEET}</MarketValueWithAccessories>
	<HaveInterestedParty>{HAVEINTERESTEDPARTY}</HaveInterestedParty>
	<ModelOther/>
	<MakeOther/>
	<FuelType/>
	<PowerKW/>
	<TrackRear/>
	<limit>
		<Type>LegalLiability</Type>
		<iValue>20000000</iValue>
	</limit>
	<VehicleType/>
	<DriveDescription/>
	<ClaimsIncurred>{FVCLMINCD}</ClaimsIncurred>
	<NumberOfClaims>{FVCLMCNT}</NumberOfClaims>
	<Premium>{FVEXPPREM}</Premium>
</Vehicle>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T11:37:41.9320000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (60, 58, N'BP_FL_MOTOR_EXCESS', N'AGGNE.DEV.FL_MOTOR_EXCESS', N'AGGNE.DEV.RISK_FLEET_VEHICLE_TARGET', N'AGGNE.DEV.FL_MOTOR_EXCESS_POLICYATTACH', N'AGGNE.DEV.RISK_FLEET_VEHICLE_TARGET_POLICY_ATTACH', N'
<Excess>
       <OnHook>0</OnHook>
       <HireVehicle>0</HireVehicle>
       <Standard></Standard>
       <Voluntary>{VOLUNTARYEXCESS}</Voluntary>
       <Imposed></Imposed>
   </Excess>', N'<Excess>
	<OnHook>{ONHOOKTOWINGPROTECTION}</OnHook>
	<HireVehicle>0</HireVehicle>
	<Standard>{STANDARDEXCESS}</Standard>
	<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
	<Imposed>{IMPOSEDEXCESS}</Imposed>
	<AgeLessThan20>{FVLESSTHAN19}</AgeLessThan20>
	<AgeBetween20To21>{FVLESSTHAN21}</AgeBetween20To21>
	<AgeBetween22To25>{FVLESSTHAN25}</AgeBetween22To25>
</Excess>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T11:40:05.4490000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (61, 59, N'BP_FL_Motor_Clauses', N'AGGNE.DEV.FL_MOTOR_CLAUSE', N'AGGNE.DEV.RISK_FLEET_VEHICLE_TARGET', N'AGGNE.DEV.FL_MOTOR_CLAUSE_POLICYATTACH', N'AGGNE.DEV.RISK_FLEET_VEHICLE_TARGET_POLICY_ATTACH', N'
<Clauses>
       <Type>Motor</Type>
       <ClausesSelection>{DCCLAUSETYPE}</ClausesSelection>
       <SelectClauseDescription>{CLAUSEDESCRIPTION}</SelectClauseDescription>
   </Clauses>', N'
<Clauses>
        <Type>Motor</Type>
        <ClausesSelection>{DCCLAUSETYPE}</ClausesSelection>
        <SelectClauseDescription>{CLAUSEDESCRIPTION}</SelectClauseDescription>
    </Clauses>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T11:42:21.4640000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (62, 60, N'BP_FL_Motor_UW', N'AGGNE.DEV.FL_MOTOR_UW', N'AGGNE.DEV.RISK_FLEET_VEHICLE_TARGET', N'AGGNE.DEV.FL_MOTOR_UW_POLICYATTACH', N'AGGNE.DEV.RISK_FLEET_VEHICLE_TARGET_POLICY_ATTACH', N'
<UnderwritingAdjustment>
		<Type>Motor</Type>
       <Recurring>
		 <Indicator>{RECURRINGIND}</Indicator>
		</Recurring>
       <UnderwritingDescription>{UWADJUSTNOTE}</UnderwritingDescription>
       <AdjustmentSelection></AdjustmentSelection>
       <AdjustmentDollarAndPercent>{ADJUSTMENTTYPE}</AdjustmentDollarAndPercent>
       <AdjustmentAmount>{UWADJUSTAMOUNT}</AdjustmentAmount>
   </UnderwritingAdjustment>', N'
<UnderwritingAdjustment>
		<Type>Motor</Type>
        <Recurring>
		  <Indicator>{RECURRINGIND}</Indicator>
		</Recurring>
        <UnderwritingDescription>{UWADJUSTNOTE}</UnderwritingDescription>
        <AdjustmentSelection></AdjustmentSelection>
        <AdjustmentDollarAndPercent>{ADJUSTMENTTYPE}</AdjustmentDollarAndPercent>
        <AdjustmentAmount>{UWADJUSTAMOUNT}</AdjustmentAmount>
    </UnderwritingAdjustment>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T11:43:54.7060000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (63, 61, N'BP_Fleet_Vehicle_main', N'AGGNE.DEV.FLEET_VEHICLE_MAIN_VIEW', N'AGGNE.DEV.RISK_FLEET_VEHICLE_TARGET', N'AGGNE.DEV.FLEET_VEHICLE_MAIN_VIEW_POLICYATTACH', N'AGGNE.DEV.RISK_FLEET_VEHICLE_TARGET_POLICY_ATTACH', N'
<risk>
   <Type>Motor</Type>
   <ExcessWaiverForGlass></ExcessWaiverForGlass>
   <OnHookTowingProtection></OnHookTowingProtection>
   <ProtectionType>{PROTECTIONTYPE}</ProtectionType>
   <HireVehicleExcess></HireVehicleExcess>
   <CourtesyVehicleExcess></CourtesyVehicleExcess>
   <ValueAccessoriesOption></ValueAccessoriesOption>
   <MarketValueWithoutAccessories></MarketValueWithoutAccessories>
   <ValueWithoutAccessories></ValueWithoutAccessories>
   <HireCourtesyDeliveryUse></HireCourtesyDeliveryUse>
   <UnlimitedGlass>{UNLIMITEDGLASS}</UnlimitedGlass>
   <OnHook>{ONHOOK}</OnHook>
   <DeliveryVehicleExcess></DeliveryVehicleExcess>
   <InterestedParties></InterestedParties>
   <InterestedPartiesAddress/>
   <InterestedPartiesName/>
   <IsVehicleImportedorNot></IsVehicleImportedorNot>
   <NonClaimDiscount></NonClaimDiscount>
   <LocationID></LocationID>
   <FleetType>{FLEETTYPE}</FleetType>
   <VehicleDetails></VehicleDetails>
   <GaragingPostcode></GaragingPostcode>
   <Usage/>
   <Performance></Performance>
   <PrincipalOperator></PrincipalOperator>
   <Included></Included>
   <HighestValueVehicleinFleet></HighestValueVehicleinFleet>
   <MaximumOneVehiclePay></MaximumOneVehiclePay>
   <State></State>
   <Segment></Segment>
   <PerformanceSafetyModifications></PerformanceSafetyModifications>
   <IsNonStandardAccessoriesIncludedinCover></IsNonStandardAccessoriesIncludedinCover>
   <CarHaveAnyModifications></CarHaveAnyModifications>
   <WindscreenExtFlag></WindscreenExtFlag>
   <Code>FL</Code>
   <ImportType></ImportType>
   <AddedHistoryID></AddedHistoryID>
   <CommercialVehicleNumber></CommercialVehicleNumber>
   <CoverType/>
   <VehicleType/>
   <VehicleInfoOverride></VehicleInfoOverride>
   <RegistrationNumber/>
   <VinNumber/>
   <Year/>
   <RegoStatus/>
   <Make/>
   <Model/>
   <Description/>
   <NightParkingLocation/>
   <NightParkingPostcode/>
   <DayParkingLocation/>
   <DayParkingPostcode/>
   <SecurityType/>
   <FinanceType/>
   <DateOfPurchase/>
   <AnnualMileage/>
   <CoverValue/>
   <Excess/>
   <NonStandardAccessories/>
   <NonStandardAccessoriesSumInsured/>
   <ModificationType/>
   <ModificationSumInsured/>
   <TotalSumInsured></TotalSumInsured>
   <LocationDescription></LocationDescription>
   <VehicleFullDescription></VehicleFullDescription>
   <BodyType/>
   <EngineSize/>
   <NumberOfCylinders/>
   <DriveDescription/>
   <InductionType/>
   <GrossVehicleMass/>
   <WouldYouLikeToAddAccessoriesOrModifications/>
   <AgreedValueAmount></AgreedValueAmount>
   <AgreedValueDescription/>
   <AgreedValueDescriptionValue/>
   <MarketValueDescription/>
   <WouldYouLikeToAddAccessoriesOrModificationsMarket></WouldYouLikeToAddAccessoriesOrModificationsMarket>
   <MarketValueDescriptionValue/>
   <MarketValueWithAccessories></MarketValueWithAccessories>
   <HighestRiskUse>{HIGHESTRISKUSE}</HighestRiskUse>
   <AgeOfYoungestRegularDriver/>
   <RestrictionOfDriverAge>{RESTRICTIONOFDRIVERAGE}</RestrictionOfDriverAge>
   <DoesTheVehicleHaveAnInterestedParty/>
   <AddDetailsForTheInterestedParty/>
   <HowManyVehiclesIsYourVehicleEquippedToCarryAtAnyOneTime/>
   <HowOftenDoYouPickUpOrDeliverVehicles/>
   <ChoiceOfRepair>{CHOICEOFREPAIR}</ChoiceOfRepair>
   <HireCarHireAfterIncident/>
   <WhatIsTheTypicalRadiusOfTravelFromTheBaseLocation/>
   <WillTheVehicleTransportMotorVehiclesOrTheMembersGeneralProperty/>
   <AreAnyVehiclesDriverSuppliedPM/>
   <Details/>
   <IsThisVehicleUsedForRideShareOperation/>
   <AreHireContractsRestrictedToNamedDriversOnly>{CONTRACTRESTRICTION}</AreHireContractsRestrictedToNamedDriversOnly>
   <AreAnyVehiclesDriverSupplied>{HIREVEHDRIVERSUPPLIED}</AreAnyVehiclesDriverSupplied>
   <WillAnyContractorsOperateThisVehicle/>
   <WillThisVehicleBeUsedToDeliverDangerousGoods/>
   <StandardExcess></StandardExcess>
   <VoluntaryExcess>{VOLUNTARYEXCESS}</VoluntaryExcess>
   <ImposedExcess></ImposedExcess>
   <OnHookExcess></OnHookExcess>
   <UWAdjustmentTotal></UWAdjustmentTotal>
   <MarketValue></MarketValue>
   <NumberofVehicles/>
   <TotalValueofNonStandard></TotalValueofNonStandard>
   <GeneralBusinessUse/>
   <CarHire>{CARHIRE}</CarHire>
   <HowManyOfYourVehiclesMayRequireOnHook/>
   <DoAnyOfYourVehiclesHaveATaxiRegistration>{TAXIREGISTRATION}</DoAnyOfYourVehiclesHaveATaxiRegistration>
   <DoesTheMemberOwnAnyOtherBusinesses>{OWNOTHERBUS}</DoesTheMemberOwnAnyOtherBusinesses>
   <WhereAreIdleVehiclesStored>{IDLEVEHSTORED}</WhereAreIdleVehiclesStored>
   <DetailsOfVehicleLocationRiskMitigation>{DETAILS_LOCRISKMIT}</DetailsOfVehicleLocationRiskMitigation>
   <AreAnyVehiclesHiredOutForRideShareOperations>{RIDESHARE}</AreAnyVehiclesHiredOutForRideShareOperations>
   <WhatPercentOfTheFleetIsHiredOutToRideShareOperators>{PERCFLRIDESHARE}</WhatPercentOfTheFleetIsHiredOutToRideShareOperators>
   <HowManyYearsExperienceDoesThisMemberHaveOperatingAHireFleet>{YEARSEXPERIENCEHIRE}</HowManyYearsExperienceDoesThisMemberHaveOperatingAHireFleet>
   <AreContractorsEmployedAsDrivers>{ARECONTEMPDRIVER}</AreContractorsEmployedAsDrivers>
   <AreAnyVehiclesUsedToDeliverDangerousGoods>{DELIVERDANGEROUSGOOD}</AreAnyVehiclesUsedToDeliverDangerousGoods>
   <HowManyYearsExperienceDoesThisMemberHaveOperatingADeliveryFleet>{YEARSEXPERIENCEDELIVERY}</HowManyYearsExperienceDoesThisMemberHaveOperatingADeliveryFleet>
   <HowOftenIsTheVehicleUsed/>
   <IsTheVehicleUsedForMembersBusinessNeedsOnly/>
   <IsTheVehicleUsedForMembersBusinessNeedsOnlyDetails/>
   <VehicleTransportHazardousDangerousGoods/>
   <VehicleTransportHazardousDangerousGoodsDetails/>
   <IsTheVehicleUsedToTransportAnyCustomerItemsReward/>
   <IsTheVehicleUsedToTransportAnyCustomerItemsRewardDetails/>
   <MaximumRangeVehicleWillTravelBusinessUse/>
   <IsTheVehicleDrivenByDirectEmployeesOnly/>
   <IsTheVehicleDrivenByDirectEmployeesOnlyDetails/>
   <IfPrimeMoverWillItTowMoreThan1TrailerAtTime/>
   <IfPrimeMoverWillItTowMoreThan1TrailerAtTimeDetails/>
   <MakeOther/>
   <ModelOther/>
   <PowerKW/>
   <TrackRear/>
   <FuelType/>
    {FL_MOTOR_EXCESS}
    {FL_MOTOR_CLAUSES}
    {FL_MOTOR_UW}
    {VEHICLE_COV_XML}
   <NumberOfVehicles></NumberOfVehicles>
</risk>', N'<risk deleted="0">
	<Type>Motor</Type>
	<ExcessWaiverForGlass/>
	<OnHookTowingProtection/>
	<ProtectionType>{PROTECTIONTYPE}</ProtectionType>
	<HireVehicleExcess/>
	<CourtesyVehicleExcess/>
	<ValueAccessoriesOption/>
	<MarketValueWithoutAccessories/>
	<ValueWithoutAccessories/>
	<HireCourtesyDeliveryUse/>
	<UnlimitedGlass>{UNLIMITEDGLASS}</UnlimitedGlass>
	<OnHook>{ONHOOK}</OnHook>
	<DeliveryVehicleExcess/>
	<InterestedParties/>
	<InterestedPartiesAddress/>
	<InterestedPartiesName/>
	<IsVehicleImportedorNot/>
	<NonClaimDiscount/>
	<LocationID/>
	<FleetType>Fleet</FleetType>
	<VehicleDetails/>
	<GaragingPostcode/>
	<Usage/>
	<Performance/>
	<PrincipalOperator/>
	<Included/>
	<HighestValueVehicleinFleet/>
	<MaximumOneVehiclePay/>
	<State/>
	<Segment/>
	<PerformanceSafetyModifications/>
	<IsNonStandardAccessoriesIncludedinCover/>
	<CarHaveAnyModifications/>
	<WindscreenExtFlag/>
	<Code>FL</Code>
	<ImportType/>
	<AddedHistoryID/>
	<CommercialVehicleNumber/>
	<CoverType/>
	<VehicleType/>
	<VehicleInfoOverride/>
	<RegistrationNumber/>
	<VinNumber/>
	<Year/>
	<RegoStatus/>
	<Make/>
	<Model/>
	<Description/>
	<NightParkingLocation/>
	<NightParkingPostcode/>
	<DayParkingLocation/>
	<DayParkingPostcode/>
	<SecurityType/>
	<FinanceType/>
	<DateOfPurchase/>
	<AnnualMileage/>
	<CoverValue/>
	<Excess/>
	<NonStandardAccessories/>
	<NonStandardAccessoriesSumInsured/>
	<ModificationType/>
	<ModificationSumInsured/>
	<TotalSumInsured/>
	<LocationDescription/>
	<VehicleFullDescription/>
	<BodyType/>
	<EngineSize/>
	<NumberOfCylinders/>
	<DriveDescription/>
	<InductionType/>
	<GrossVehicleMass/>
	<WouldYouLikeToAddAccessoriesOrModifications/>
	<AgreedValueAmount/>
	<AgreedValueDescription/>
	<AgreedValueDescriptionValue/>
	<MarketValueDescription/>
	<WouldYouLikeToAddAccessoriesOrModificationsMarket/>
	<MarketValueDescriptionValue/>
	<MarketValueWithAccessories/>
	<HighestRiskUse>{HIGHESTRISKUSE}</HighestRiskUse>
	<AgeOfYoungestRegularDriver>{AGEOFYOUNGESTREGULARDRIVER}</AgeOfYoungestRegularDriver>
	<RestrictionOfDriverAge>{RESTRICTIONOFDRIVERAGE}</RestrictionOfDriverAge>
	<DoesTheVehicleHaveAnInterestedParty/>
	<AddDetailsForTheInterestedParty/>
	<HowManyVehiclesIsYourVehicleEquippedToCarryAtAnyOneTime/>
	<HowOftenDoYouPickUpOrDeliverVehicles/>
	<ChoiceOfRepair>{CHOICEOFREPAIR}</ChoiceOfRepair>
	<HireCarHireAfterIncident/>
	<WhatIsTheTypicalRadiusOfTravelFromTheBaseLocation/>
	<WillTheVehicleTransportMotorVehiclesOrTheMembersGeneralProperty/>
	<AreAnyVehiclesDriverSuppliedPM/>
	<Details/>
	<IsThisVehicleUsedForRideShareOperation/>
	<AreHireContractsRestrictedToNamedDriversOnly>{CONTRACTRESTRICTION}</AreHireContractsRestrictedToNamedDriversOnly>
	<AreAnyVehiclesDriverSupplied>{HIREVEHDRIVERSUPPLIED}</AreAnyVehiclesDriverSupplied>
	<WillAnyContractorsOperateThisVehicle/>
	<WillThisVehicleBeUsedToDeliverDangerousGoods/>
	<StandardExcess/>
	<VoluntaryExcess>{VOLUNTARYEXCESS}</VoluntaryExcess>
	<ImposedExcess/>
	<OnHookExcess/>
	<UWAdjustmentTotal/>
	<MarketValue/>
	<NumberofVehicles/>
	<TotalValueofNonStandard/>
	<GeneralBusinessUse/>
	<CarHire>{CARHIRE}</CarHire>
	<HowManyOfYourVehiclesMayRequireOnHook/>
	<DoAnyOfYourVehiclesHaveATaxiRegistration>{TAXIREGISTRATION}</DoAnyOfYourVehiclesHaveATaxiRegistration>
	<DoesTheMemberOwnAnyOtherBusinesses>{OWNOTHERBUS}</DoesTheMemberOwnAnyOtherBusinesses>
	<WhereAreIdleVehiclesStored>{IDLEVEHSTORED}</WhereAreIdleVehiclesStored>
	<DetailsOfVehicleLocationRiskMitigation>{DETAILS_LOCRISKMIT}</DetailsOfVehicleLocationRiskMitigation>
	<AreAnyVehiclesHiredOutForRideShareOperations>{RIDESHARE}</AreAnyVehiclesHiredOutForRideShareOperations>
	<WhatPercentOfTheFleetIsHiredOutToRideShareOperators>{PERCFLRIDESHARE}</WhatPercentOfTheFleetIsHiredOutToRideShareOperators>
	<HowManyYearsExperienceDoesThisMemberHaveOperatingAHireFleet>{YEARSEXPERIENCEHIRE}</HowManyYearsExperienceDoesThisMemberHaveOperatingAHireFleet>
	<AreContractorsEmployedAsDrivers>{ARECONTEMPDRIVER}</AreContractorsEmployedAsDrivers>
	<AreAnyVehiclesUsedToDeliverDangerousGoods>{DELIVERDANGEROUSGOOD}</AreAnyVehiclesUsedToDeliverDangerousGoods>
	<HowManyYearsExperienceDoesThisMemberHaveOperatingADeliveryFleet>{YEARSEXPERIENCEDELIVERY}</HowManyYearsExperienceDoesThisMemberHaveOperatingADeliveryFleet>
	<HowOftenIsTheVehicleUsed/>
	<IsTheVehicleUsedForMembersBusinessNeedsOnly/>
	<IsTheVehicleUsedForMembersBusinessNeedsOnlyDetails/>
	<VehicleTransportHazardousDangerousGoods/>
	<VehicleTransportHazardousDangerousGoodsDetails/>
	<IsTheVehicleUsedToTransportAnyCustomerItemsReward/>
	<IsTheVehicleUsedToTransportAnyCustomerItemsRewardDetails/>
	<MaximumRangeVehicleWillTravelBusinessUse/>
	<IsTheVehicleDrivenByDirectEmployeesOnly/>
	<IsTheVehicleDrivenByDirectEmployeesOnlyDetails/>
	<IfPrimeMoverWillItTowMoreThan1TrailerAtTime/>
	<IfPrimeMoverWillItTowMoreThan1TrailerAtTimeDetails/>
	<MakeOther/>
	<ModelOther/>
	<PowerKW/>
	<TrackRear/>
	<FuelType/>      {FL_MOTOR_EXCESS}      {FL_MOTOR_CLAUSES}      {FL_MOTOR_UW}      {VEHICLE_COV_XML}      <NumberOfVehicles/>
</risk>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T11:47:17.2290000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (64, 62, N'BP_CV_Vehicle_SubCov', N'AGGNE.DEV.CV_COVERAGE_VEHICLE_SUBCOV', N'AGGNE.DEV.CV_FLEET_VEHICLE_TARGET', N'AGGNE.DEV.CV_COVERAGE_VEHICLE_SUBCOV_POLICYATTACH', N'AGGNE.DEV.CV_FLEET_VEHICLE_TARGET_POLICYATTACH', N'
<coverage>
    		<Indicator>1</Indicator>
    		<limit>
    			<Type>{CMTYPE}</Type>
    			<iValue>{ACCESSORIESVALUE}</iValue>
    		</limit>
    		<Type>{CMTYPE}</Type>
    		<Code>{CMCODE}</Code>
    		<Description>{PROTECTIONTYPE}</Description>
			<Premium>{EXPPREMIUM}</Premium>
    	</coverage>', N'
<coverage>
    		<Indicator>1</Indicator>
    		<limit>
    			<Type>{CMTYPE}</Type>
    			<iValue>{ACCESSORIESVALUE}</iValue>
    		</limit>
    		<Type>{CMTYPE}</Type>
    		<Code>{CMCODE}</Code>
    		<Description>{VALUE}</Description>
			<Premium>{EXPPREMIUM}</Premium>
    	</coverage>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T11:49:23.1980000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (65, 63, N'BP_CV_vehicle_Cov', N'AGGNE.DEV.CV_COVERAGE_VEHICLE_COV', N'AGGNE.DEV.CV_FLEET_VEHICLE_TARGET', N'AGGNE.DEV.CV_COVERAGE_VEHICLE_COV_POLICYATTACH', N'AGGNE.DEV.CV_FLEET_VEHICLE_TARGET_POLICYATTACH', N'
<coverage>
	<Type>CommercialVehicle</Type>
	<limit>
		<Type>{TYPE}</Type>
		<iValue>{MARKETVALUEWITHACCESSORIESAMOUNT}</iValue>
	</limit>
	<Indicator>1</Indicator>
	<ClassCode>
		<APRA>CMV</APRA>
		<Business>CMV</Business>
	</ClassCode>
	<Code>CM</Code>
   <ClaimsIncurred>{CMCLMINCD}</ClaimsIncurred>
   <NumberOfClaims>{CMCLMCNT}</NumberOfClaims>
   <Premium>{CMEXPPREM}</Premium>
	{SUBCOV_XML}
</coverage>', N'
<coverage>
	<Type>CommercialVehicle</Type>
	<limit>
		<Type>{TYPE}</Type>
		<iValue>{MARKETVALUEWITHACCESSORIESAMOUNT}</iValue>
	</limit>
	<Indicator>1</Indicator>
	<ClassCode>
		<APRA>CMV</APRA>
		<Business>CMV</Business>
	</ClassCode>
	<Code>CM</Code>
    <ClaimsIncurred>{CMCLMINCD}</ClaimsIncurred>
    <NumberOfClaims>{CMCLMCNT}</NumberOfClaims>
    <Premium>{CMEXPPREM}</Premium>
	{SUBCOV_XML}
</coverage>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T11:51:37.5540000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (66, 64, N'BP_CV_MOTOR_EXCESS', N'AGGNE.DEV.CV_MOTOR_EXCESS', N'AGGNE.DEV.CV_FLEET_VEHICLE_TARGET', N'AGGNE.DEV.CV_MOTOR_EXCESS_POLICYATTACH', N'AGGNE.DEV.CV_FLEET_VEHICLE_TARGET_POLICYATTACH', N'
<Excess>
       <OnHook>0</OnHook>
       <HireVehicle>0</HireVehicle>
       <Standard></Standard>
       <Voluntary>{VOLUNTARYEXCESS}</Voluntary>
       <Imposed></Imposed>
   </Excess>', N'<Excess>
	<OnHook>{ONHOOKTOWINGPROTECTION}</OnHook>
	<HireVehicle>0</HireVehicle>
	<Standard>{STANDARDEXCESS}</Standard>
	<Voluntary>{VOLUNTARYEXCESS}</Voluntary>
	<Imposed>{IMPOSEDEXCESS}</Imposed>
	<AgeLessThan20>{CMCVAGE19}</AgeLessThan20>
	<AgeBetween20To21>{CMCVAGE21}</AgeBetween20To21>
	<AgeBetween22To25>{CMCVAGE25}</AgeBetween22To25>
</Excess>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T11:52:57.0340000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (67, 65, N'BP_CV_Motor_Clauses', N'AGGNE.DEV.CV_MOTOR_CLAUSE', N'AGGNE.DEV.CV_FLEET_VEHICLE_TARGET', N'AGGNE.DEV.CV_MOTOR_CLAUSE_POLICYATTACH', N'AGGNE.DEV.CV_FLEET_VEHICLE_TARGET_POLICYATTACH', N'
<Clauses>
       <Type>Motor</Type>
       <ClausesSelection>{DCCLAUSETYPE}</ClausesSelection>
       <SelectClauseDescription>{CLAUSEDESCRIPTION}</SelectClauseDescription>
   </Clauses>', N'
<Clauses>
        <Type>Motor</Type>
        <ClausesSelection>{DCCLAUSETYPE}</ClausesSelection>
        <SelectClauseDescription>{CLAUSEDESCRIPTION}</SelectClauseDescription>
    </Clauses&gt ', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T11:54:01.2190000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (68, 66, N'BP_CV_Motor_UW', N'AGGNE.DEV.CV_MOTOR_UW', N'AGGNE.DEV.CV_FLEET_VEHICLE_TARGET', N'AGGNE.DEV.CV_MOTOR_UW_POLICYATTACH', N'AGGNE.DEV.CV_FLEET_VEHICLE_TARGET_POLICYATTACH', N'
<UnderwritingAdjustment>
		<Type>Motor</Type>
       <Recurring>
		 <Indicator>{RECURRINGIND}</Indicator>
		</Recurring>
       <UnderwritingDescription>{UWADJUSTNOTE}</UnderwritingDescription>
       <AdjustmentSelection></AdjustmentSelection>
       <AdjustmentDollarAndPercent>{ADJUSTMENTTYPE}</AdjustmentDollarAndPercent>
       <AdjustmentAmount>{UWADJUSTAMOUNT}</AdjustmentAmount>
   </UnderwritingAdjustment>', N'
<UnderwritingAdjustment>
		<Type>Motor</Type>
        <Recurring>
		  <Indicator>{RECURRINGIND}</Indicator>
		</Recurring>
        <UnderwritingDescription>{UWADJUSTNOTE}</UnderwritingDescription>
        <AdjustmentSelection></AdjustmentSelection>
        <AdjustmentDollarAndPercent>{ADJUSTMENTTYPE}</AdjustmentDollarAndPercent>
        <AdjustmentAmount>{UWADJUSTAMOUNT}</AdjustmentAmount>
    </UnderwritingAdjustment>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T11:55:35.3970000' AS DateTime2), NULL, NULL)
GO
INSERT [dbo].[ConversionConfig] ([ConversionConfigId], [SequenceID], [ScriptName], [ConversionSourceTable], [ConversionTargetTable], [AttachSourceTable], [AttachTargetTable], [ConversionScript], [AttachScript], [IsActive], [CreatedBy], [CreatedOn], [ModifiedBy], [ModifiedOn]) VALUES (69, 67, N'BP_CV_Vehicle_main', N'AGGNE.DEV.CV_RISK_COV_FINAL_VIEW', N'AGGNE.DEV.CV_FLEET_VEHICLE_TARGET', N'AGGNE.DEV.CV_RISK_COV_FINAL_VIEW_POLICYATTACH', N'AGGNE.DEV.CV_FLEET_VEHICLE_TARGET_POLICYATTACH', N'<risk>
	<Type>Motor</Type>
	<RegistrationNumber>{REGISTRATIONNUMBER}</RegistrationNumber>
	<RedbookCode>{CMRBVEHICLEKEY}</RedbookCode>
	<VehicleFullDescription/>
	<MarketValue>{MARKETVALUEWITHACCESSORIESAMOUNT}</MarketValue>
	<ProtectionType>{PROTECTIONTYPE}</ProtectionType>
	<HighestRiskUse>{HIGHESTRISKUSE}</HighestRiskUse>
	<OnHookTowingProtection>{ONHOOKTOWINGPROTECTION}</OnHookTowingProtection>
	<ChoiceOfRepair>{CHOICEOFREPAIR}</ChoiceOfRepair>
	<HireCarHireAfterIncident>{HIRECARHIREAFTERINCIDENT}</HireCarHireAfterIncident>
	<ExcessWaiverForGlass>{EXCESSWAIVERFORGLASS}</ExcessWaiverForGlass>
	<State>{STATE}</State>
	<VehicleType>{VEHICLETYPE}</VehicleType>
	<Make>{MAKE}</Make>
	<Model>{MODEL}</Model>
	<Year>{YEAR}</Year>
	<Description>{DESCRIPTION}</Description>
	<BodyType>{BODYTYPE}</BodyType>
	<EngineSize>{ENGINESIZE}</EngineSize>
	<NumberOfCylinders>{NUMBEROFCYLINDERS}</NumberOfCylinders>
	<DriveDescription>{DRIVEDESCRIPTION}</DriveDescription>
	<InductionType>{INDUCTIONTYPE}</InductionType>
	<GrossVehicleMass>{GROSSVEHICLEMASS}</GrossVehicleMass>
	<ImportType>N/A</ImportType>
	<FuelType/>
	<PowerKW/>
	<TrackRear/>
	<AgreedValue/>
	<ValueWithoutAccessories>{VALUEWITHOUTACCESSORIES}</ValueWithoutAccessories>
	<WouldYouLikeToAddAccessoriesOrModificationsMarket>{WOULDYOULIKETOADDACCESSORIESORMODIFICATIONS}</WouldYouLikeToAddAccessoriesOrModificationsMarket>
	<AgreedValueDescription>{AGREEDVALUEDESCRIPTION}</AgreedValueDescription>
	<AgreedValueDescriptionValue>{AGREEDVALUEDESCRIPTIONVALUE}</AgreedValueDescriptionValue>
	<AgreedValueAmount>{AGREEDVALUEAMOUNT}</AgreedValueAmount>
	<MarketValueWithoutAccessories>{MARKETVALUEWITHOUTACCESSORIESAMOUNT}</MarketValueWithoutAccessories>
	<MarketValueDescription>{MARKETVALUEDESCRIPTION}</MarketValueDescription>
	<MarketValueDescriptionValue>{MARKETVALUEDESCRIPTIONVALUE}</MarketValueDescriptionValue>
	<MarketValueWithAccessories>{MARKETVALUEWITHACCESSORIESAMOUNT}</MarketValueWithAccessories>
	<AgeOfYoungestRegularDriver>{AGEOFYOUNGESTREGULARDRIVER}</AgeOfYoungestRegularDriver>
	<RestrictionOfDriverAge>{RESTRICTIONOFDRIVERAGE}</RestrictionOfDriverAge>
	<DoesTheVehicleHaveAnInterestedParty>{DOESTHEVEHICLEHAVEANINTERESTEDPARTY}</DoesTheVehicleHaveAnInterestedParty>
	<AddDetailsForTheInterestedParty>{ADDDETAILSFORTHEINTERESTEDPARTY}</AddDetailsForTheInterestedParty>
	<HowManyVehiclesIsYourVehicleEquippedToCarryAtAnyOneTime>{HOWMANYVEHICLESISYOURVEHICLEEQUIPPEDTOCARRYATANYONETIME}</HowManyVehiclesIsYourVehicleEquippedToCarryAtAnyOneTime>
	<HowOftenDoYouPickUpOrDeliverVehicles>{HOWOFTEN}</HowOftenDoYouPickUpOrDeliverVehicles>
	<HowOftenIsTheVehicleUsed>{HOWOFTENISTHEVEHICLEUSED}</HowOftenIsTheVehicleUsed>
	<IsTheVehicleUsedForMembersBusinessNeedsOnly>{ISTHEVEHICLEUSEDFORMEMBERSBUSINESSNEEDSONLY}</IsTheVehicleUsedForMembersBusinessNeedsOnly>
	<IsTheVehicleUsedForMembersBusinessNeedsOnlyDetails>{DETAILSMEMBUS}</IsTheVehicleUsedForMembersBusinessNeedsOnlyDetails>
	<VehicleTransportHazardousDangerousGoods>{VEHICLETRANSPORTHAZARDOUSDANGEROUSGOODS}</VehicleTransportHazardousDangerousGoods>
	<VehicleTransportHazardousDangerousGoodsDetails>{DETAILS}</VehicleTransportHazardousDangerousGoodsDetails>
	<IsTheVehicleUsedToTransportAnyCustomerItemsReward>{ISTHEVEHICLEUSEDTOTRANSPORTANYCUSTOMERITEMSREWARD}</IsTheVehicleUsedToTransportAnyCustomerItemsReward>
	<IsTheVehicleUsedToTransportAnyCustomerItemsRewardDetails>{DETAILSCUSTITEM}</IsTheVehicleUsedToTransportAnyCustomerItemsRewardDetails>
	<MaximumRangeVehicleWillTravelBusinessUse>{MAXIMUMRANGEVEHICLEWILLTRAVELBUSINESSUSE}</MaximumRangeVehicleWillTravelBusinessUse>
	<IsTheVehicleDrivenByDirectEmployeesOnly>{DRIVEBYDIRECTEMP}</IsTheVehicleDrivenByDirectEmployeesOnly>
	<IsTheVehicleDrivenByDirectEmployeesOnlyDetails>{DETAILSDIRECTEMP}</IsTheVehicleDrivenByDirectEmployeesOnlyDetails>
	<IfPrimeMoverWillItTowMoreThan1TrailerAtTime>{IFPRIMEMOVERWILLITTOWMORETHAN1TRAILERATTIME}</IfPrimeMoverWillItTowMoreThan1TrailerAtTime>
	<IfPrimeMoverWillItTowMoreThan1TrailerAtTimeDetails>{DETAILSTOWGT1}</IfPrimeMoverWillItTowMoreThan1TrailerAtTimeDetails>
	<IsThisVehicleUsedForRideShareOperation>{ISTHISVEHICLEUSEDFORRIDESHAREOPERATION}</IsThisVehicleUsedForRideShareOperation>
	<AreHireContractsRestrictedToNamedDriversOnly>{CONTRACTRESTRICTION}</AreHireContractsRestrictedToNamedDriversOnly>
	<AreAnyVehiclesDriverSupplied>{AREANYVEHICLESDRIVERSUPPLIED}</AreAnyVehiclesDriverSupplied>
	<WillAnyContractorsOperateThisVehicle>{WILLANYCONTRACTORSOPERATETHISVEHICLE}</WillAnyContractorsOperateThisVehicle>
	<WillThisVehicleBeUsedToDeliverDangerousGoods>{WILLTHISVEHICLEBEUSEDTODELIVERDANGEROUSGOODS}</WillThisVehicleBeUsedToDeliverDangerousGoods>      {CV_MOTOR_EXCESS}      {CV_MOTOR_CLAUSES}      {CV_MOTOR_UW}      {CV_VEHICLE_COV}   <RegoStatus/>
	<VehicleInfoOverride>1</VehicleInfoOverride>
</risk>', N'<risk deleted="0">
	<Type>Motor</Type>
	<RegistrationNumber>{REGISTRATIONNUMBER}</RegistrationNumber>
	<VehicleFullDescription/>
	<MarketValue>{MARKETVALUEWITHACCESSORIESAMOUNT}</MarketValue>
	<ProtectionType>{PROTECTIONTYPE}</ProtectionType>
	<HighestRiskUse>{HIGHESTRISKUSE}</HighestRiskUse>
	<OnHookTowingProtection>{ONHOOKTOWINGPROTECTION}</OnHookTowingProtection>
	<ChoiceOfRepair>{CHOICEOFREPAIR}</ChoiceOfRepair>
	<HireCarHireAfterIncident>{HIRECARHIREAFTERINCIDENT}</HireCarHireAfterIncident>
	<ExcessWaiverForGlass>{EXCESSWAIVERFORGLASS}</ExcessWaiverForGlass>
	<State>{STATE}</State>
	<VehicleType>{VEHICLETYPE}</VehicleType>
	<FleetType>Default</FleetType>
	<Make>{MAKE}</Make>
	<Model>{MODEL}</Model>
	<Year>{YEAR}</Year>
	<Description>{DESCRIPTION}</Description>
	<BodyType>{BODYTYPE}</BodyType>
	<EngineSize>{ENGINESIZE}</EngineSize>
	<NumberOfCylinders>{NUMBEROFCYLINDERS}</NumberOfCylinders>
	<DriveDescription>{DRIVEDESCRIPTION}</DriveDescription>
	<InductionType>{INDUCTIONTYPE}</InductionType>
	<GrossVehicleMass>{GROSSVEHICLEMASS}</GrossVehicleMass>
	<ImportType>N/A</ImportType>
	<FuelType/>
	<limit>
    <Type>LegalLiability</Type>
    <iValue>20000000</iValue>
    </limit>
	<PowerKW/>
	<TrackRear/>
	<AgreedValue/>
	<ValueWithoutAccessories>{VALUEWITHOUTACCESSORIES}</ValueWithoutAccessories>
	<WouldYouLikeToAddAccessoriesOrModificationsMarket>{WOULDYOULIKETOADDACCESSORIESORMODIFICATIONS}</WouldYouLikeToAddAccessoriesOrModificationsMarket>
	<AgreedValueDescription>{AGREEDVALUEDESCRIPTION}</AgreedValueDescription>
	<AgreedValueDescriptionValue>{AGREEDVALUEDESCRIPTIONVALUE}</AgreedValueDescriptionValue>
	<AgreedValueAmount>{AGREEDVALUEAMOUNT}</AgreedValueAmount>
	<MarketValueWithoutAccessories>{MARKETVALUEWITHOUTACCESSORIESAMOUNT}</MarketValueWithoutAccessories>
	<MarketValueDescription>{MARKETVALUEDESCRIPTION}</MarketValueDescription>
	<MarketValueDescriptionValue>{MARKETVALUEDESCRIPTIONVALUE}</MarketValueDescriptionValue>
	<MarketValueWithAccessories>{MARKETVALUEWITHACCESSORIESAMOUNT}</MarketValueWithAccessories>
	<AgeOfYoungestRegularDriver>{AGEOFYOUNGESTREGULARDRIVER}</AgeOfYoungestRegularDriver>
	<RestrictionOfDriverAge>{RESTRICTIONOFDRIVERAGE}</RestrictionOfDriverAge>
	<DoesTheVehicleHaveAnInterestedParty>{DOESTHEVEHICLEHAVEANINTERESTEDPARTY}</DoesTheVehicleHaveAnInterestedParty>
	<AddDetailsForTheInterestedParty>{ADDDETAILSFORTHEINTERESTEDPARTY}</AddDetailsForTheInterestedParty>
	<HowManyVehiclesIsYourVehicleEquippedToCarryAtAnyOneTime>{HOWMANYVEHICLESISYOURVEHICLEEQUIPPEDTOCARRYATANYONETIME}</HowManyVehiclesIsYourVehicleEquippedToCarryAtAnyOneTime>
	<HowOftenDoYouPickUpOrDeliverVehicles>{HOWOFTEN}</HowOftenDoYouPickUpOrDeliverVehicles>
	<HowOftenIsTheVehicleUsed>{HOWOFTENISTHEVEHICLEUSED}</HowOftenIsTheVehicleUsed>
	<IsTheVehicleUsedForMembersBusinessNeedsOnly>{ISTHEVEHICLEUSEDFORMEMBERSBUSINESSNEEDSONLY}</IsTheVehicleUsedForMembersBusinessNeedsOnly>
	<IsTheVehicleUsedForMembersBusinessNeedsOnlyDetails>{DETAILSMEMBUS}</IsTheVehicleUsedForMembersBusinessNeedsOnlyDetails>
	<VehicleTransportHazardousDangerousGoods>{VEHICLETRANSPORTHAZARDOUSDANGEROUSGOODS}</VehicleTransportHazardousDangerousGoods>
	<VehicleTransportHazardousDangerousGoodsDetails>{DETAILS}</VehicleTransportHazardousDangerousGoodsDetails>
	<IsTheVehicleUsedToTransportAnyCustomerItemsReward>{ISTHEVEHICLEUSEDTOTRANSPORTANYCUSTOMERITEMSREWARD}</IsTheVehicleUsedToTransportAnyCustomerItemsReward>
	<IsTheVehicleUsedToTransportAnyCustomerItemsRewardDetails>{DETAILSCUSTITEM}</IsTheVehicleUsedToTransportAnyCustomerItemsRewardDetails>
	<MaximumRangeVehicleWillTravelBusinessUse>{MAXIMUMRANGEVEHICLEWILLTRAVELBUSINESSUSE}</MaximumRangeVehicleWillTravelBusinessUse>
	<IsTheVehicleDrivenByDirectEmployeesOnly>{DRIVEBYDIRECTEMP}</IsTheVehicleDrivenByDirectEmployeesOnly>
	<IsTheVehicleDrivenByDirectEmployeesOnlyDetails>{DETAILSDIRECTEMP}</IsTheVehicleDrivenByDirectEmployeesOnlyDetails>
	<IfPrimeMoverWillItTowMoreThan1TrailerAtTime>{IFPRIMEMOVERWILLITTOWMORETHAN1TRAILERATTIME}</IfPrimeMoverWillItTowMoreThan1TrailerAtTime>
	<IfPrimeMoverWillItTowMoreThan1TrailerAtTimeDetails>{DETAILSTOWGT1}</IfPrimeMoverWillItTowMoreThan1TrailerAtTimeDetails>
	<IsThisVehicleUsedForRideShareOperation>{ISTHISVEHICLEUSEDFORRIDESHAREOPERATION}</IsThisVehicleUsedForRideShareOperation>
	<AreHireContractsRestrictedToNamedDriversOnly>{CONTRACTRESTRICTION}</AreHireContractsRestrictedToNamedDriversOnly>
	<AreAnyVehiclesDriverSupplied>{AREANYVEHICLESDRIVERSUPPLIED}</AreAnyVehiclesDriverSupplied>
	<WillAnyContractorsOperateThisVehicle>{WILLANYCONTRACTORSOPERATETHISVEHICLE}</WillAnyContractorsOperateThisVehicle>
	<WillThisVehicleBeUsedToDeliverDangerousGoods>{WILLTHISVEHICLEBEUSEDTODELIVERDANGEROUSGOODS}</WillThisVehicleBeUsedToDeliverDangerousGoods>      {CV_MOTOR_EXCESS}      {CV_MOTOR_CLAUSES}      {CV_MOTOR_UW}      {CV_VEHICLE_COV}   <RegoStatus/>
	<VehicleInfoOverride>1</VehicleInfoOverride>
</risk>', 1, N'CapSwiftConversiondev', CAST(N'2026-02-19T12:02:03.6810000' AS DateTime2), NULL, NULL)
GO
SET IDENTITY_INSERT [dbo].[ConversionConfig] OFF
GO
ALTER TABLE [dbo].[ConversionConfig] ADD  CONSTRAINT [DF_ConversionConfig_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[ConversionConfig] ADD  CONSTRAINT [DF_ConversionConfig_CreatedBy]  DEFAULT (suser_sname()) FOR [CreatedBy]
GO
ALTER TABLE [dbo].[ConversionConfig] ADD  CONSTRAINT [DF_ConversionConfig_CreatedOn]  DEFAULT (sysutcdatetime()) FOR [CreatedOn]
GO
