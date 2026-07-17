<xsl:stylesheet version="1.0" xmlns:i="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns="Address.Types" xmlns:afs="http://schemas.datacontract.org/2004/07/AFS.Architecture.Common" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
  <xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
  <xsl:variable name="transactionDate" select="string(Util:GetValueByKey('transactionDate'))" />

  <xsl:template match="/">
    <AddressTypeAssociationsDTO i="http://www.w3.org/2001/XMLSchema-instance">
      <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
      <AddressTypeAssociations>
        
            <AddressTypeAssociationDTO>
              <afs:EntityAuthLevel>FullAccess</afs:EntityAuthLevel>
              <AddressID>
                <xsl:value-of select="PartyAddressDetailDTO/Address/AddressID" />
              </AddressID>
              <AddressType>
                <xsl:value-of select="string(Util:GetOneRelatedItem('DCTLocationInvolvementType','_LEG','8501'))"/>
              </AddressType>
              <AddressTypeAssociationID nil="true" />
             
              <EffectiveDate>
                <xsl:value-of select="string(Util:GetCurrentDate())"/>
              </EffectiveDate>

              <ExpirationDate>
                <xsl:value-of select="string(Util:GetMaxDate())"/>
              </ExpirationDate>
              <LastTransactionID nil="true" />
              <LastUpdatedDate>
                <xsl:value-of select="string(Util:GetCurrentDate())"/>
              </LastUpdatedDate>
            </AddressTypeAssociationDTO>
      </AddressTypeAssociations>
    </AddressTypeAssociationsDTO>
  </xsl:template>
</xsl:stylesheet>