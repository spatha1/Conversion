<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output omit-xml-declaration="yes" indent="yes"></xsl:output>
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"></xsl:apply-templates>
    </xsl:copy>
  </xsl:template>
  <xsl:template match="changeSummary">
    <ChangeSummary>
	<PolicyGroupChangeSummary>
<xsl:for-each select="//SessionReconcile.buildChangeSummaryRs/changeSummary/group[@groupID='Policy']">
<xsl:element name="{@groupID}">
<xsl:attribute name="id">
<xsl:value-of select="instance/@dataID"></xsl:value-of>
</xsl:attribute>
<xsl:attribute name="Change">
<xsl:value-of select="instance/@type"></xsl:value-of>
</xsl:attribute>
<xsl:for-each select="instance/change">
<xsl:element name="{substring-after(@fieldID,'.')}">
<xsl:attribute name="Old">
<xsl:value-of select="@old"></xsl:value-of>
</xsl:attribute>
<xsl:attribute name="New">
<xsl:value-of select="@new"></xsl:value-of>
</xsl:attribute>
</xsl:element>
</xsl:for-each>
</xsl:element>
</xsl:for-each>
</PolicyGroupChangeSummary>
      <PolicyChangeSummary>
        <xsl:for-each select="//SessionReconcile.buildChangeSummaryRs/changeSummary/group[@groupID='BusinessInformation']">
          <xsl:element name="{@groupID}">
            <xsl:attribute name="id">
              <xsl:value-of select="instance/@dataID"></xsl:value-of>
            </xsl:attribute>
            <xsl:attribute name="Change">
              <xsl:value-of select="instance/@type"></xsl:value-of>
            </xsl:attribute>
            <xsl:for-each select="instance/change">
              <xsl:element name="{substring-after(@fieldID,'.')}">
                <xsl:attribute name="Old">
                  <xsl:value-of select="@old"></xsl:value-of>
                </xsl:attribute>
                <xsl:attribute name="New">
                  <xsl:value-of select="@new"></xsl:value-of>
                </xsl:attribute>
              </xsl:element>
            </xsl:for-each>
          </xsl:element>
        </xsl:for-each>
      </PolicyChangeSummary>
	  <AdditionalInterestSMEChangeSummary>
        <xsl:for-each select="//SessionReconcile.buildChangeSummaryRs/changeSummary/group[@groupID='AdditionalInterestSME']">
          <xsl:element name="{@groupID}">
            <xsl:for-each select="instance">
              <xsl:element name="instance">
                <xsl:attribute name="Id">
                  <xsl:value-of select="@dataID"></xsl:value-of>
                </xsl:attribute>
                <xsl:attribute name="Change">
                  <xsl:value-of select="@type"></xsl:value-of>
                </xsl:attribute>
                <xsl:for-each select="change">
                  <xsl:element name="{substring-after(@fieldID,'.')}">
                    <xsl:attribute name="Old">
                      <xsl:value-of select="@old"></xsl:value-of>
                    </xsl:attribute>
                    <xsl:attribute name="New">
                      <xsl:value-of select="@new"></xsl:value-of>
                    </xsl:attribute>
                  </xsl:element>
                </xsl:for-each>
              </xsl:element>
            </xsl:for-each>
          </xsl:element>
        </xsl:for-each>
      </AdditionalInterestSMEChangeSummary>
	  <SpecifiedToolsChangeSummary>
        <xsl:for-each select="//SessionReconcile.buildChangeSummaryRs/changeSummary/group[@groupID='SpecifiedTools']">
          <xsl:element name="{@groupID}">
            <xsl:for-each select="instance">
              <xsl:element name="instance">
                <xsl:attribute name="Id">
                  <xsl:value-of select="@dataID"></xsl:value-of>
                </xsl:attribute>
                <xsl:attribute name="Change">
                  <xsl:value-of select="@type"></xsl:value-of>
                </xsl:attribute>
                <xsl:for-each select="change">
                  <xsl:element name="{substring-after(@fieldID,'.')}">
                    <xsl:attribute name="Old">
                      <xsl:value-of select="@old"></xsl:value-of>
                    </xsl:attribute>
                    <xsl:attribute name="New">
                      <xsl:value-of select="@new"></xsl:value-of>
                    </xsl:attribute>
                  </xsl:element>
                </xsl:for-each>
              </xsl:element>
            </xsl:for-each>
          </xsl:element>
        </xsl:for-each>
      </SpecifiedToolsChangeSummary>
      <HomeContentsChangeSummary>
        <xsl:for-each select="//SessionReconcile.buildChangeSummaryRs/changeSummary/group[@groupID='HomeContents']">
          <xsl:element name="{@groupID}">
            <xsl:for-each select="instance">
              <xsl:element name="instance">
                <xsl:attribute name="Id">
                  <xsl:value-of select="@dataID"></xsl:value-of>
                </xsl:attribute>
                <xsl:attribute name="Change">
                  <xsl:value-of select="@type"></xsl:value-of>
                </xsl:attribute>
                <xsl:for-each select="change">
                  <xsl:element name="{substring-after(@fieldID,'.')}">
                    <xsl:attribute name="Old">
                      <xsl:value-of select="@old"></xsl:value-of>
                    </xsl:attribute>
                    <xsl:attribute name="New">
                      <xsl:value-of select="@new"></xsl:value-of>
                    </xsl:attribute>
                  </xsl:element>
                </xsl:for-each>
              </xsl:element>
            </xsl:for-each>
          </xsl:element>
        </xsl:for-each>
      </HomeContentsChangeSummary>
      <SpecifiedContentsChangeSummary>
        <xsl:for-each select="//SessionReconcile.buildChangeSummaryRs/changeSummary/group[@groupID='SpecifiedContents']">
          <xsl:element name="{@groupID}">
            <xsl:for-each select="instance">
              <xsl:element name="instance">
                <xsl:attribute name="Id">
                  <xsl:value-of select="@dataID"></xsl:value-of>
                </xsl:attribute>
                <xsl:attribute name="Change">
                  <xsl:value-of select="@type"></xsl:value-of>
                </xsl:attribute>
                <xsl:for-each select="change">
                  <xsl:element name="{substring-after(@fieldID,'.')}">
                    <xsl:attribute name="Old">
                      <xsl:value-of select="@old"></xsl:value-of>
                    </xsl:attribute>
                    <xsl:attribute name="New">
                      <xsl:value-of select="@new"></xsl:value-of>
                    </xsl:attribute>
                  </xsl:element>
                </xsl:for-each>
              </xsl:element>
            </xsl:for-each>
          </xsl:element>
        </xsl:for-each>
      </SpecifiedContentsChangeSummary>
      <LineChangeSummary>
        <xsl:for-each select="//SessionReconcile.buildChangeSummaryRs/changeSummary/group[@groupID='PublicProductLiability' or @groupID='ProfessionalProtection' or @groupID='GeneralProperty' or @groupID='GoodsInTransit' or @groupID='LegalExpenses' or @groupID='TaxAudit' or @groupID='CustomerVehicles' or @groupID='StockVehicles']">
          <xsl:element name="{@groupID}">
            <xsl:attribute name="Id">
              <xsl:value-of select="instance/@dataID"></xsl:value-of>
            </xsl:attribute>
            <xsl:attribute name="Change">
              <xsl:value-of select="instance/@type"></xsl:value-of>
            </xsl:attribute>
            <xsl:for-each select="instance/change">
              <xsl:element name="{substring-after(@fieldID,'.')}">
                <xsl:attribute name="Old">
                  <xsl:value-of select="@old"></xsl:value-of>
                </xsl:attribute>
                <xsl:attribute name="New">
                  <xsl:value-of select="@new"></xsl:value-of>
                </xsl:attribute>
              </xsl:element>
            </xsl:for-each>
          </xsl:element>
        </xsl:for-each>
      </LineChangeSummary>
      <LocationChangeSummary>
        <xsl:for-each select="//SessionReconcile.buildChangeSummaryRs/changeSummary/group[@groupID='Location']">
          <xsl:element name="{@groupID}">
            <xsl:for-each select="instance">
              <xsl:element name="instance">
                <xsl:attribute name="Id">
                  <xsl:value-of select="@dataID"></xsl:value-of>
                </xsl:attribute>
                <xsl:attribute name="Change">
                  <xsl:value-of select="@type"></xsl:value-of>
                </xsl:attribute>
                <xsl:for-each select="change">
                  <xsl:element name="{substring-after(@fieldID,'.')}">
                    <xsl:attribute name="Old">
                      <xsl:value-of select="@old"></xsl:value-of>
                    </xsl:attribute>
                    <xsl:attribute name="New">
                      <xsl:value-of select="@new"></xsl:value-of>
                    </xsl:attribute>
                  </xsl:element>
                </xsl:for-each>
              </xsl:element>
            </xsl:for-each>
          </xsl:element>
        </xsl:for-each>
      </LocationChangeSummary>
      <PropertyChangeSummary>
        <xsl:for-each select="//SessionReconcile.buildChangeSummaryRs/changeSummary/group[@groupID='Theft' or @groupID='BuildingRiskSME' or @groupID='ContentsAndStocks' or @groupID='Money' or @groupID='Engineering' or @groupID='Interruption']">
          <xsl:element name="{@groupID}">
            <xsl:for-each select="instance">
              <xsl:variable name="UniqueVariable" select="@dataID"></xsl:variable>
              <xsl:element name="instance">
                <xsl:attribute name="Id">
                  <xsl:value-of select="@dataID"></xsl:value-of>
                </xsl:attribute>
                <xsl:attribute name="ParentID">
                  <xsl:value-of select="//data/policy/line/risk[Type='Building'][coverage/@id =$UniqueVariable]/@id"></xsl:value-of>
                </xsl:attribute>
                <xsl:attribute name="Change">
                  <xsl:value-of select="@type"></xsl:value-of>
                </xsl:attribute>
                <xsl:for-each select="change">
                  <xsl:element name="{substring-after(@fieldID,'.')}">
                    <xsl:attribute name="Old">
                      <xsl:value-of select="@old"></xsl:value-of>
                    </xsl:attribute>
                    <xsl:attribute name="New">
                      <xsl:value-of select="@new"></xsl:value-of>
                    </xsl:attribute>
                  </xsl:element>
                </xsl:for-each>
              </xsl:element>
            </xsl:for-each>
          </xsl:element>
        </xsl:for-each>
      </PropertyChangeSummary>
      <VehicleChangeSummary>
        <xsl:for-each select="//SessionReconcile.buildChangeSummaryRs/changeSummary/group[@groupID='Vehicle']">
          <xsl:element name="{@groupID}">
            <xsl:for-each select="instance">
              <xsl:element name="instance">
                <xsl:attribute name="dataID">
                  <xsl:value-of select="@dataID"></xsl:value-of>
                </xsl:attribute>
                <xsl:attribute name="Change">
                  <xsl:value-of select="@type"></xsl:value-of>
                </xsl:attribute>
                <xsl:for-each select="change">
                  <xsl:element name="{substring-after(@fieldID,'.')}">
                    <xsl:attribute name="Old">
                      <xsl:value-of select="@old"></xsl:value-of>
                    </xsl:attribute>
                    <xsl:attribute name="New">
                      <xsl:value-of select="@new"></xsl:value-of>
                    </xsl:attribute>
                  </xsl:element>
                </xsl:for-each>
              </xsl:element>
            </xsl:for-each>
          </xsl:element>
        </xsl:for-each>
      </VehicleChangeSummary>
      <PropertyGroupChangeSummary>
        <xsl:for-each select="//SessionReconcile.buildChangeSummaryRs/changeSummary/group[@groupID='Property']">
          <xsl:element name="{@groupID}">
            <xsl:for-each select="instance">
              <xsl:element name="instance">
                <xsl:attribute name="dataID">
                  <xsl:value-of select="@dataID"></xsl:value-of>
                </xsl:attribute>
                <xsl:attribute name="Change">
                  <xsl:value-of select="@type"></xsl:value-of>
                </xsl:attribute>
                <xsl:for-each select="change">
                  <xsl:element name="{substring-after(@fieldID,'.')}">
                    <xsl:attribute name="Old">
                      <xsl:value-of select="@old"></xsl:value-of>
                    </xsl:attribute>
                    <xsl:attribute name="New">
                      <xsl:value-of select="@new"></xsl:value-of>
                    </xsl:attribute>
                  </xsl:element>
                </xsl:for-each>
              </xsl:element>
            </xsl:for-each>
          </xsl:element>
        </xsl:for-each>
      </PropertyGroupChangeSummary>
    </ChangeSummary>
  </xsl:template>
</xsl:stylesheet>