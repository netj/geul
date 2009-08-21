<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:atom="http://www.w3.org/2005/Atom"
    exclude-result-prefixes="atom html"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:template match="atom:feed">
        <div class="atom-feed">
            <xsl:apply-templates/>
        </div>
    </xsl:template>

    <xsl:template match="atom:entry">
        <div class="atom-entry">
            <xsl:variable name="link" select="atom:link[@rel='alternative']"/>
            <!-- title and published -->
            <h2 class="atom-title"><xsl:choose>
                    <xsl:when test="$link">
                        <a href="{$link/@href}"><xsl:value-of select="atom:title"/></a>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="atom:title"/>
                    </xsl:otherwise>
            </xsl:choose></h2>
            <div class="atom-published">
                <xsl:apply-templates select="atom:published" mode="date"/>
            </div>

            <!-- summary -->
            <xsl:if test="atom:summary">
                <div class="atom-summary">
                    <xsl:choose>
                        <xsl:when test="atom:summary/@type = 'xhtml'">
                            <xsl:copy-of select="atom:summary/html:div"/>
                        </xsl:when>
                        <xsl:when test="atom:summary/@type = 'text'">
                            <xsl:value-of select="atom:summary"/>
                        </xsl:when>
                        <xsl:when test="atom:summary/@type = 'html'">
                            <xsl:value-of select="atom:summary" disable-output-escaping="yes"/>
                        </xsl:when>
                    </xsl:choose>
                </div>
            </xsl:if>

            <!-- link -->
            <xsl:if test="$link">
                <div class="atom-link">
                    <a href="{$link/@href}">[...]</a>
                </div>
            </xsl:if>
        </div>
    </xsl:template>

</xsl:stylesheet>
