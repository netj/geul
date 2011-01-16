<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns:atom="http://www.w3.org/2005/Atom"
    xmlns:str="http://exslt.org/strings"
    exclude-result-prefixes="atom str"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:output method="text"/>

    <xsl:template match="atom:feed">
        <xsl:text>[&#10;</xsl:text>
        <xsl:apply-templates select="atom:entry"/>
        <xsl:text>]&#10;</xsl:text>
    </xsl:template>

    <xsl:template match="atom:entry">
        <xsl:text>{&#10;</xsl:text>
        <xsl:call-template name="json-field">
            <xsl:with-param name="name" select="'id'"/>
            <xsl:with-param name="value" select="atom:link[@rel='alternative' or not(@rel)][1]/@href"/>
        </xsl:call-template>
        <xsl:text>,&#10;</xsl:text>
        <xsl:call-template name="json-field">
            <xsl:with-param name="name" select="'title'"/>
            <xsl:with-param name="value" select="atom:title"/>
        </xsl:call-template>
        <xsl:text>,&#10;</xsl:text>
        <xsl:call-template name="json-field">
            <xsl:with-param name="name" select="'published'"/>
            <xsl:with-param name="value" select="atom:published"/>
        </xsl:call-template>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>}</xsl:text>
        <xsl:if test="position() != last()">
            <xsl:text>,</xsl:text>
        </xsl:if>
        <xsl:text>&#10;</xsl:text>
    </xsl:template>

    <xsl:template name="json-field">
        <xsl:param name="name"/>
        <xsl:param name="value"/>
        <xsl:text>"</xsl:text>
        <xsl:value-of select="$name"/>
        <xsl:text>": "</xsl:text>
        <xsl:value-of select="str:replace($value, '&quot;', '\&quot;')"/>
        <xsl:text>"</xsl:text>
    </xsl:template>

</xsl:stylesheet>
