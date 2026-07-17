<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0" xmlns:xslNsExt="urn:xslExtensions" xmlns:xslNsODExt="urn:xslOnDemandExtensions" xmlns:ext="urn:ext">
	<xsl:template name="buildHeaderLanguageCombo">
		<xsl:param name="imageComboContainerId"/>
		<xsl:param name="imageComboInputId"/>
		<xsl:param name="imageComboHiddenIName"/>
		<xsl:param name="imageComboContainerClass"/>
		<xsl:variable name="GlobalCultureCode">
			<xsl:value-of select="xslNsODExt:getCulture()"/>
		</xsl:variable>
		<xsl:element name="div">
			<xsl:attribute name="id">
				<xsl:value-of select="$imageComboContainerId"/>
			</xsl:attribute>
			<xsl:attribute name="class">
				<xsl:value-of select="$imageComboContainerClass"/>
			</xsl:attribute>
			<xsl:element name="div">
				<xsl:attribute name="class">headerlanguageComboField</xsl:attribute>
				<xsl:attribute name="data-config">
					<xsl:text>{</xsl:text>
					<xsl:text>renderTo: "</xsl:text>
					<xsl:value-of select="$imageComboContainerId"/>
					<xsl:text>",  value: "</xsl:text>
					<xsl:value-of select="$GlobalCultureCode"/>
					<xsl:text>",</xsl:text>
					<xsl:text>dctComboImageInputCls: "</xsl:text>
					<xsl:text>languageComboInputFlag</xsl:text>
					<xsl:text>",</xsl:text>
					<xsl:text>id: "</xsl:text>
					<xsl:value-of select="$imageComboInputId"/>
					<xsl:text>",</xsl:text>
					<xsl:text>hiddenName: "</xsl:text>
					<xsl:value-of select="$imageComboHiddenIName"/>
					<xsl:text>",</xsl:text>
					<xsl:text>dctStore:  </xsl:text>
					<xsl:text>[</xsl:text>
					<xsl:call-template name="buildLanguageComboDataStore">
						<xsl:with-param name="resourceName">LanguageEN</xsl:with-param>
						<xsl:with-param name="name">en-US</xsl:with-param>
						<xsl:with-param name="imageFile">no_Flag.gif</xsl:with-param>
					</xsl:call-template>
					
<xsl:text>,</xsl:text>
          <xsl:call-template name="buildLanguageComboDataStore">
            <xsl:with-param name="resourceName">LanguageEN</xsl:with-param>
            <xsl:with-param name="name">en-AU</xsl:with-param>
            <xsl:with-param name="imageFile">Flag_Australia.png</xsl:with-param>
          </xsl:call-template>
          <xsl:text>]</xsl:text>
					<xsl:text> }</xsl:text>
				</xsl:attribute>
			</xsl:element>
		</xsl:element>
	</xsl:template>
	<xsl:template name="buildLanguageCombo">
		<xsl:param name="imageComboContainerId"/>
		<xsl:param name="imageComboInputId"/>
		<xsl:param name="imageComboHiddenIName"/>
		<xsl:param name="imageComboContainerClass"/>
		<xsl:variable name="GlobalCultureCode">
			<xsl:value-of select="xslNsODExt:getCulture()"/>
		</xsl:variable>
		<xsl:element name="div">
			<xsl:attribute name="id">
				<xsl:value-of select="$imageComboContainerId"/>
			</xsl:attribute>
			<xsl:attribute name="class">
				<xsl:value-of select="$imageComboContainerClass"/>
				<xsl:text> languageDropdownContainer</xsl:text>
			</xsl:attribute>
			<xsl:element name="div">
				<xsl:attribute name="class">languageComboField</xsl:attribute>
				<xsl:attribute name="data-config">
					<xsl:text>{</xsl:text>
					<xsl:text>renderTo: "</xsl:text>
					<xsl:value-of select="$imageComboContainerId"/>
					<xsl:text>",  value: "</xsl:text>
					<xsl:value-of select="$GlobalCultureCode"/>
					<xsl:text>",</xsl:text>
					<xsl:text>dctComboImageInputCls: "</xsl:text>
					<xsl:text>languageComboInputFlag</xsl:text>
					<xsl:text>",</xsl:text>
					<xsl:text>id: "</xsl:text>
					<xsl:value-of select="$imageComboInputId"/>
					<xsl:text>",</xsl:text>
					<xsl:text>hiddenName: "</xsl:text>
					<xsl:value-of select="$imageComboHiddenIName"/>
					<xsl:text>",</xsl:text>
					<xsl:text>growAppend: "W",</xsl:text>
					<xsl:text>dctStore:  </xsl:text>
					<xsl:text>[</xsl:text>
					<xsl:call-template name="buildLanguageComboDataStore">
						<xsl:with-param name="resourceName">LanguageEN</xsl:with-param>
						<xsl:with-param name="name">en-US</xsl:with-param> 
						<xsl:with-param name="imageFile">Flag_UnitedStates.png</xsl:with-param>
					</xsl:call-template>
					
<xsl:text>,</xsl:text>
          <xsl:call-template name="buildLanguageComboDataStore">
            <xsl:with-param name="resourceName">LanguageEN</xsl:with-param>
            <xsl:with-param name="name">en-AU</xsl:with-param>
            <xsl:with-param name="imageFile">Flag_Australia.png</xsl:with-param>
          </xsl:call-template>
          <xsl:text>]</xsl:text>
					<xsl:if test="/page/themeSettings[@theme=$theme]/Controls/ComboBoxPaddingString[@enabled='1']">
						<xsl:text>,</xsl:text>
						<xsl:text>dctPaddingString: "</xsl:text>
						<xsl:value-of select="/page/themeSettings/Controls/ComboBoxPaddingString"/>
						<xsl:text>"</xsl:text>
					</xsl:if>
					<xsl:if test="/page/settings/Controls/ComboBoxes/@maxSize">
						<xsl:text>,</xsl:text>
						<xsl:text>dctMaxSize: "</xsl:text>
						<xsl:value-of select="/page/settings/Controls/ComboBoxes/@maxSize"/>
						<xsl:text>"</xsl:text>
					</xsl:if>
					<xsl:text> }</xsl:text>
				</xsl:attribute>
			</xsl:element>
		</xsl:element>
	</xsl:template>
</xsl:stylesheet>
