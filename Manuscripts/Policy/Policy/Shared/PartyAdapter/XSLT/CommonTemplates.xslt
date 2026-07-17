<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:d2p1="AFS.AEF.WCF.Types" xmlns:d4p1="Address.Types" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="d2p1 d4p1 xs msxsl xsl Util">
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	<xsl:template name="ResponseInfo">
		<xsl:param name="ReturnCode">
		</xsl:param>
		<xsl:param name="NotificationResponse"/>
		<ResponseInfo>
			<ReturnCode>
				<xsl:value-of select="$ReturnCode"/>
			</ReturnCode>
			<xsl:choose>
				<xsl:when test="$NotificationResponse != ''">
					<NotificationResponse>
						<xsl:value-of select="$NotificationResponse"/>
					</NotificationResponse>
				</xsl:when>
				<xsl:otherwise>
					<NotificationResponse />
				</xsl:otherwise>
			</xsl:choose>
		</ResponseInfo>
	</xsl:template>

	<xsl:template name="ExtendedDataASWToDuck">
		<xsl:param name="TagName"/>
		<xsl:param name="AswTagName"/>
		<xsl:variable name="DtoTag">
			<xsl:choose>
				<xsl:when test="$AswTagName!=''">
					<xsl:value-of select="$AswTagName" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$TagName" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="./*[local-name(.)=$DtoTag]/ExtendedFields/ExtendedFieldDTO/XMLValue/./*[local-name(.)=$TagName]/null">
				<!--don't output anything for our null marker workaround -->
			</xsl:when>
			<xsl:when test="./*[local-name(.)=$DtoTag]/ExtendedFields/ExtendedFieldDTO/XMLValue[@nil='true']" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
				<!--don't output anything for nil -->
			</xsl:when>
			<xsl:when test="./*[local-name(.)=$DtoTag]/ExtendedFields/ExtendedFieldDTO/XMLValue/./*[local-name(.)=$TagName]">
				<xsl:copy-of select="./*[local-name(.)=$DtoTag]/ExtendedFields/ExtendedFieldDTO/XMLValue/./*[local-name(.)=$TagName]"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:element name="{$TagName}" />
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="ExtendedData" xmlns="Party.Types">
		<xsl:param name="TagName"/>
		<xsl:param name="AswTagName"/>
		<xsl:param name="SuiteTagName"/>
		<xsl:param name="PhysicalTableName"/>
		<xsl:param name="LogicalTableName"/>
		<xsl:param name="LogicalColumnName"/>
		<xsl:variable name="OutTag">
			<xsl:choose>
				<xsl:when test="$AswTagName!=''">
					<xsl:value-of select="$AswTagName" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="$TagName" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
			<xsl:element name="{$OutTag}">
				<d2p1:PhysicalTableName>
					<xsl:value-of select="$PhysicalTableName" />
				</d2p1:PhysicalTableName>
				<d2p1:ExtendedFields>
					<d2p1:ExtendedFieldDTO>
						<d2p1:LogicalTableName>
							<xsl:value-of select="$LogicalTableName" />
						</d2p1:LogicalTableName>
						<d2p1:LogicalColumnName>
							<xsl:value-of select="$LogicalColumnName" />
						</d2p1:LogicalColumnName>
						<d2p1:DataType>XElement</d2p1:DataType>
						<d2p1:XMLValue>
							<xsl:choose>
								<xsl:when test="./*[local-name(.)=$TagName]/node()">
									<xsl:copy-of select="./*[local-name(.)=$TagName]"/>
								</xsl:when>
								<xsl:when test="./*[local-name(.)=$TagName]">
									<xsl:element name="{$TagName}" namespace=""/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:element name="{$TagName}" namespace="">
										<null/>
									</xsl:element>
								</xsl:otherwise>
							</xsl:choose>
						</d2p1:XMLValue>
					</d2p1:ExtendedFieldDTO>
					<xsl:for-each select="./*[local-name(.)=$SuiteTagName]/*">
							<xsl:call-template name="SuiteFieldsDuckToASW">
            
								<xsl:with-param name="FieldValue" select ="node()"></xsl:with-param>
             					<xsl:with-param name="FieldName" select ="local-name(.)"></xsl:with-param>
								<xsl:with-param name="SuiteTagName" select ="$SuiteTagName"></xsl:with-param>
           
							</xsl:call-template>
					</xsl:for-each>
				</d2p1:ExtendedFields>
			</xsl:element>
	</xsl:template>
	
	<xsl:template name="SuiteFieldsDuckToASW"  xmlns="Party.Types">

		<xsl:param name="FieldValue"/>
		<xsl:param name="FieldName"/>
		<xsl:param name="SuiteTagName"/>


		<xsl:variable name="lookupDoc" select="document('../ExtendedFieldMappings.xml')" />
		<xsl:variable name="AFSField"	select="$lookupDoc/*/*[local-name(.)=$SuiteTagName]/Key[@ManuscriptField = $FieldName]/@CustomFieldFQN" />
		<xsl:variable name="DataType"	select="$lookupDoc/*/*[local-name(.)=$SuiteTagName]/Key[@ManuscriptField = $FieldName]/@AFSDataType" />

		<xsl:variable name="LogTableName"	select="substring-before($AFSField,'.')" />
		<xsl:variable name="LogColumnName"	select="substring-after($AFSField,'.')" />


		<xsl:choose>
			<xsl:when test="$AFSField and $LogTableName and $LogColumnName">

				<!-- When Field is in Manuscript, but mapping is missing -->
				<!-- Need to handle Failure on substring, LogTable / Column name missing ? -->
		
				<d2p1:ExtendedFieldDTO>
					<d2p1:LogicalTableName>
					<xsl:value-of select="$LogTableName"/>
					</d2p1:LogicalTableName>
					<d2p1:LogicalColumnName>
					<xsl:value-of select="$LogColumnName"/>
					</d2p1:LogicalColumnName>
					<d2p1:DataType>
					<xsl:value-of select="$DataType"/>
					</d2p1:DataType>
					<xsl:choose>
						<xsl:when test="$FieldValue">				
				
							<xsl:choose>
							<xsl:when test="$DataType='Int32'">
								<xsl:element name="d2p1:IntegerValue" >
									<xsl:value-of  select="$FieldValue"/>
								</xsl:element>
							</xsl:when>

							<xsl:when test="$DataType='Decimal'">
								<xsl:element name="d2p1:FloatingValue" >
									<xsl:value-of  select="$FieldValue"/>
								</xsl:element>
							</xsl:when>

							<xsl:when test="$DataType='DateTime'">
								<xsl:element name="d2p1:DateTimeValue" >
									<xsl:value-of  select="$FieldValue"/>
								</xsl:element>
							</xsl:when>

							<xsl:when test="$DataType='Time'">
								<xsl:element name="d2p1:DateTimeValue" >
									<xsl:value-of  select="string(Util:ConvertTimeToAswFormat($FieldValue, '1800-01-01'))"/>
								</xsl:element>
							</xsl:when>
				
							<xsl:when test="$DataType='Boolean'">
								<xsl:element name="d2p1:BooleanValue" >
									<xsl:value-of  select="$FieldValue"/>
								</xsl:element>
							</xsl:when>

							<xsl:when test="$DataType='Currency'">
								<xsl:element name="d2p1:CurrencyValue" >
									<xsl:value-of  select="$FieldValue"/>
								</xsl:element>
							</xsl:when>


							<xsl:when test="$DataType='String'">
								<xsl:element name="d2p1:TextValue" >
									<xsl:value-of  select="$FieldValue"/>
								</xsl:element>
							</xsl:when>
								
							<xsl:otherwise>
								<xsl:variable name="ErrMsg"	select="concat('ExtendedFieldMappings.xml Invalid DataType for DateType:',$DataType)" />
								<xsl:value-of  select="string(Util:LogExtendedFieldMappingsError($ErrMsg))" />
							</xsl:otherwise>

						</xsl:choose>
		    
						</xsl:when>   
      
					</xsl:choose>
					</d2p1:ExtendedFieldDTO>

			</xsl:when>
			<xsl:otherwise>

				<xsl:variable name="ErrMsg"	select="concat('ExtendedFieldMappings.xml Missing Mapping for Manuscript Field:',$FieldName)" />
				<xsl:value-of  select="string(Util:LogExtendedFieldMappingsError($ErrMsg))" />
			
			</xsl:otherwise>
		</xsl:choose>



		
	</xsl:template>
  <xsl:template name="ASWExtendedDataToDuck">
    <xsl:param name="TagName"/>
    <xsl:choose>
      <xsl:when test="./XMLValue/./*[local-name(.)=$TagName]/null">
        <!--don't output anything for our null marker workaround -->
      </xsl:when>
      <xsl:when test="./XMLValue[@nil='true']" xmlns:i="http://www.w3.org/2001/XMLSchema-instance">
        <!--don't output anything for nil -->
      </xsl:when>
      <xsl:when test="./XMLValue/./*[local-name(.)=$TagName]">
        <xsl:copy-of select="./XMLValue/./*[local-name(.)=$TagName]"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:element name="{$TagName}" />
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
	
  <xsl:template name="SuiteASWExtendedDataToDuck">
	  
		<xsl:param name="SuiteTagName"/>
		<xsl:variable name="lookupDoc" select="document('../ExtendedFieldMappings.xml')" />
		<xsl:variable name="LogTable"	select="./*[local-name(.)='LogicalTableName']/node()" />
		<xsl:variable name="LogColumn"	select="./*[local-name(.)='LogicalColumnName']/node()" />
		

    <xsl:variable name="AFSFQN">
      <xsl:value-of select="concat($LogTable,'.',$LogColumn)" />
    </xsl:variable>
    <xsl:variable name="msfield" select="$lookupDoc/*/*[local-name(.)=$SuiteTagName]/Key[@CustomFieldFQN = $AFSFQN]/@ManuscriptField" />

    <xsl:choose>
      
    <xsl:when test="count($msfield)&gt;0 and $msfield != ''" >

		<xsl:choose>
			<xsl:when test="./DataType='Int32'">

				<xsl:choose>
					<xsl:when test="./IntegerValue[@nil='true']" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"></xsl:when>
					<xsl:when test="./IntegerValue">
						<xsl:element name="{$msfield}" >
							<xsl:value-of  select="./IntegerValue"/>
						</xsl:element>
					</xsl:when>
					<xsl:otherwise>
						<xsl:element name="{$msfield}" />
					</xsl:otherwise>
				</xsl:choose>

			</xsl:when>


			<xsl:when test="./DataType='Boolean'">
				<xsl:choose>
					<xsl:when test="./BooleanValue[@nil='true']" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"></xsl:when>
					<xsl:when test="./BooleanValue">
						<xsl:element name="{$msfield}" >
							<xsl:choose>
								<xsl:when test="./BooleanValue= 'true'">1</xsl:when>
								<xsl:otherwise>0</xsl:otherwise>
							</xsl:choose>       
						</xsl:element>
					</xsl:when>
					<xsl:otherwise>
						<xsl:element name="{$msfield}" />
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			

			<xsl:when test="./DataType='Decimal'">

				<xsl:choose>
					<xsl:when test="./FloatingValue[@nil='true']" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"></xsl:when>
					<xsl:when test="./FloatingValue">
						<xsl:element name="{$msfield}" >
							<xsl:value-of  select="./FloatingValue"/>
						</xsl:element>
					</xsl:when>
					<xsl:otherwise>
						<xsl:element name="{$msfield}" />
					</xsl:otherwise>
				</xsl:choose>

			</xsl:when>

			<xsl:when test="./DataType='DateTime'">

				<xsl:choose>
					<xsl:when test="./DateTimeValue[@nil='true']" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"></xsl:when>
					<xsl:when test="./DateTimeValue">
						<xsl:element name="{$msfield}" >
							<xsl:value-of  select="./DateTimeValue"/>
						</xsl:element>
					</xsl:when>
					<xsl:otherwise>
						<xsl:element name="{$msfield}" />
					</xsl:otherwise>
				</xsl:choose>

			</xsl:when>

			<xsl:when test="./DataType='Time'">


				
				<xsl:choose>
					<xsl:when test="./DateTimeValue[@nil='true']" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"></xsl:when>
					<xsl:when test="./DateTimeValue">

							<xsl:variable name="Time1"	select="substring-after(./DateTimeValue,'1800-01-01T')" />
							<xsl:variable name="Time2"	select="concat($Time1,'.000')" />
							<xsl:element name="{$msfield}">
								<xsl:value-of  select="$Time2"/>
							</xsl:element>
						
					</xsl:when>
					<xsl:otherwise>
						<xsl:element name="{$msfield}" />
					</xsl:otherwise>
				</xsl:choose>

			</xsl:when>

			<xsl:otherwise>

				<xsl:choose>
					<!--<xsl:when test="./TextValue[@nil='true']" xmlns:i="http://www.w3.org/2001/XMLSchema-instance"></xsl:when>-->
					<xsl:when test="./TextValue">
						<xsl:element name="{$msfield}" >
							<xsl:value-of  select="./TextValue"/>
						</xsl:element>
					</xsl:when>
					<xsl:otherwise>
						<xsl:element name="{$msfield}" />
					</xsl:otherwise>
				</xsl:choose>

			</xsl:otherwise>
		</xsl:choose>


    </xsl:when>
	<xsl:otherwise>
	
		<xsl:if test="./DataType !='XElement' and $msfield = ''">
			<xsl:variable name="ErrMsg"	select="concat('Manuscript FieldId missing for AFS Custom Field:',$AFSFQN)" />
			<xsl:value-of  select="string(Util:LogExtendedFieldMappingsError($ErrMsg))" />
		</xsl:if>
		
	</xsl:otherwise>

    </xsl:choose>

	</xsl:template>
</xsl:stylesheet>