<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:Util="urn:Util" xmlns:msxsl="urn:schemas-microsoft-com:xslt" xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs msxsl xsl Util">
	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8" indent="yes"/>
	<xsl:template match="table">
		<xsl:copy>
			<xsl:apply-templates select="row" />
		</xsl:copy>
	</xsl:template>
	<xsl:template match="row">
		<xsl:copy>
			<xsl:attribute name="questionLevel">
				<xsl:value-of select="cell[@name='QuestionLevel']/@value" />
			</xsl:attribute>
			<QuestionCaption>
				<xsl:value-of select="cell[@name='Caption']/@value" />
			</QuestionCaption>
			<xsl:apply-templates select="cell"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="cell" />
	<xsl:template match="cell[@name='AnswerType' and @value='YesNo']">
		<bValue/>
		<DataType>boolean</DataType>
		<FieldType>radio</FieldType>
	</xsl:template>
	<xsl:template match="cell[@name='Show' and not(@value='')]">
		<Show>
			<xsl:value-of select="@value" />
		</Show>
	</xsl:template>
	<xsl:template match="cell[@name='QuestionCode' and not(@value='')]">
		<QuestionCode>
			<xsl:value-of select="@value" />
		</QuestionCode>
	</xsl:template>
	<xsl:template match="cell[@name='AnswerType' and @value='LongDescription']">
		<DataType>string</DataType>
		<FieldType>LongDescription</FieldType>
	</xsl:template>
	<xsl:template match="cell[@name='Code' and not(@value='')]">
		<Code>
			<xsl:value-of select="@value" />
		</Code>
	</xsl:template>	
	<xsl:template match="cell[@name='QuestionOrder' and not(@value='')]">
		<Order>
			<xsl:value-of select="@value" />
		</Order>
	</xsl:template>
	<xsl:template match="cell[@name='ParentCode' and not(@value='')]">
		<ParentCode>
			<xsl:value-of select="@value"/>
		</ParentCode>
		<Rowid>
			<xsl:value-of select="./key/@value"/>
		</Rowid>
	</xsl:template>
</xsl:stylesheet>