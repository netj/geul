<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:atom="http://www.w3.org/2005/Atom"
    exclude-result-prefixes="atom html"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:template match="atom:feed">
        <xsl:apply-templates/>
    </xsl:template>

    <xsl:template match="atom:entry">
        <xsl:variable name="link" select="atom:link[@rel='alternative']"/>
        <h2><xsl:choose>
                <xsl:when test="$link">
                    <a href="{$link/@href}"><xsl:value-of select="atom:title"/></a>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="atom:title"/>
                </xsl:otherwise>
        </xsl:choose></h2>
        <xsl:copy-of select="atom:summary/html:div"/>
    </xsl:template>

</xsl:stylesheet>
