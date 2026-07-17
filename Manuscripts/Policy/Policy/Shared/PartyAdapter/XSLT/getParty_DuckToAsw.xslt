<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="Party.Types" xmlns:par="Party.Services" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:arr="http://schemas.microsoft.com/2003/10/Serialization/Arrays" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:template match="/Filters">

		<PartyFilterCriteriaDTO>
			<afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
			<xsl:variable name="PartyTypeCount" select="count(./Filter[@Type = 'PartyType'])"/>
			<xsl:variable name="PhoneTypeCount" select="count(./Filter[@Type = 'PhoneType'])"/>
			<xsl:variable name="EmailTypeCount" select="count(./Filter[@Type = 'EmailType'])"/>
			<xsl:variable name="LicenseTypeCount" select="count(./Filter[@Type = 'LicenseType'])"/>
			<xsl:variable name="ReferenceTypeCount" select="count(./Filter[@Type = 'ReferenceType'])"/>
			<xsl:variable name="LocationTypeCount" select="count(./Filter[@Type = 'LocationType'])"/>
			<xsl:variable name="OtherNameCount" select="count(./Filter[@Type = 'OtherNameType'])"/>
			<xsl:variable name="RelationshipCount" select="count(./Filter[@Type = 'RelationshipType'])"/>
			
			<xsl:variable name="PartyRecordFilter" >
				<xsl:choose>
					<xsl:when test="count(./Filter[@Type = 'RecordType']) > 0">
						<xsl:value-of select="./Filter[@Type = 'RecordType']/@Value"/>
					</xsl:when>
					<xsl:otherwise>Active</xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
			
			<xsl:variable name="AddrFilter" >
				<xsl:choose>
					<xsl:when test="count(./Filter[@Type = 'AddrFilter']) > 0">
						<xsl:value-of select="./Filter[@Type = 'AddrFilter']/@Value"/>
					</xsl:when>
					<xsl:otherwise><xsl:value-of select="$PartyRecordFilter" /></xsl:otherwise>
				</xsl:choose>
			</xsl:variable>
		
			<xsl:choose>
				<xsl:when test="$LocationTypeCount > 0">
					<AddressRecordCriteria>
						<xsl:value-of select="$AddrFilter" />
					</AddressRecordCriteria>
					<AddressTypeCode>
						<xsl:for-each select="./Filter[@Type = 'LocationType']">
							<arr:string>
								<xsl:value-of select="string(Util:GetOneRelatedItem('DCTLocationInvolvementType',@Value,'8501'))"/>
							</arr:string>
						</xsl:for-each>
					</AddressTypeCode>
				</xsl:when>
				<xsl:otherwise>
					<AddressRecordCriteria>
						<xsl:value-of select="$AddrFilter" />
					</AddressRecordCriteria>
				</xsl:otherwise>
			</xsl:choose>
			<AsOfDate>
				<xsl:value-of select="string(Util:GetValueByKey('TransactionDate'))"/>
			</AsOfDate>
			<xsl:choose>
				<xsl:when test="$EmailTypeCount > 0">
					<EmailRecordCriteria>
						<xsl:value-of select="$PartyRecordFilter" />
					</EmailRecordCriteria>
					<EmailTypeCode>
						<xsl:for-each select="./Filter[@Type = 'EmailType']">
							<arr:string>
								<xsl:value-of select="string(Util:GetOneRelatedItem('DCTEmailType',@Value,'31'))"/>
							</arr:string>
						</xsl:for-each>
					</EmailTypeCode>
				</xsl:when>
				<xsl:otherwise>
					<EmailRecordCriteria>
						<xsl:value-of select="$PartyRecordFilter" />
					</EmailRecordCriteria>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:choose>
				<xsl:when test="$LicenseTypeCount > 0">
					<LicenseRecordCriteria>Active</LicenseRecordCriteria>
					<LicenseTypeCode>
						<xsl:for-each select="./Filter[@Type = 'LicenseType']">
							<arr:string>
								<xsl:value-of select="string(Util:GetOneRelatedItem('DCTLicenseType',@Value,'PTYLicTyp'))"/>
							</arr:string>
						</xsl:for-each>
					</LicenseTypeCode>
				</xsl:when>
				<xsl:otherwise>
					<LicenseRecordCriteria>Active</LicenseRecordCriteria>
				</xsl:otherwise>
			</xsl:choose>

			<xsl:if test="$ReferenceTypeCount > 0">
				<MembershipRecordCriteria>All</MembershipRecordCriteria>
				<MembershipTypeCode>
					<xsl:for-each select="./Filter[@Type = 'ReferenceType']">
						<arr:string>
							<xsl:value-of select="string(Util:GetOneRelatedItem('DCTReferenceType',@Value,'PTYMbrshpTyp'))"/>
						</arr:string>
					</xsl:for-each>
				</MembershipTypeCode>
			</xsl:if>

			<xsl:choose>
				<xsl:when test="$OtherNameCount > 0">
					<NameRecordCriteria>
						<xsl:value-of select="$PartyRecordFilter" />
					</NameRecordCriteria>
					<NameTypeCode>
						<xsl:for-each select="./Filter[@Type = 'OtherNameType']">
							<arr:string>
								<xsl:value-of select="string(Util:GetOneRelatedItem('DCTNameType',@Value,'29'))"/>
							</arr:string>
						</xsl:for-each>
					</NameTypeCode>
				</xsl:when>
				<xsl:otherwise>
					<NameRecordCriteria>
						<xsl:value-of select="$PartyRecordFilter" />
					</NameRecordCriteria>
				</xsl:otherwise>
			</xsl:choose>

			<xsl:choose>
				<xsl:when test="$PhoneTypeCount > 0">
					<PhoneRecordCriteria>
						<xsl:value-of select="$PartyRecordFilter" />
					</PhoneRecordCriteria>
					<PhoneTypeCode>
						<xsl:for-each select="./Filter[@Type = 'PhoneType']">
							<arr:string>
								<xsl:value-of select="string(Util:GetOneRelatedItem('DCTPhoneType',@Value,'26'))"/>
							</arr:string>
						</xsl:for-each>
					</PhoneTypeCode>
				</xsl:when>
				<xsl:otherwise>
					<PhoneRecordCriteria>
						<xsl:value-of select="$PartyRecordFilter" />
					</PhoneRecordCriteria>
				</xsl:otherwise>
			</xsl:choose>
			<xsl:if test="$RelationshipCount > 0">
				<RelationshipRecordCriteria>All</RelationshipRecordCriteria>
				<RelationshipTypeCode>
					<xsl:for-each select="./Filter[@Type = 'RelationshipType']">
						<arr:string>
							<xsl:value-of select="string(Util:GetOneRelatedItem('DCTRelationshipType',@Value,'PTYRelshpTyp'))"/>
						</arr:string>
					</xsl:for-each>
				</RelationshipTypeCode>
			</xsl:if>
		</PartyFilterCriteriaDTO>
	</xsl:template>
</xsl:stylesheet>

