<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns:html="http://www.w3.org/1999/xhtml"
    exclude-result-prefixes="html"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <!--
    Ditched XHTML and using HTML5 with text/html instead
    See: http://hixie.ch/advocacy/xhtml

    <xsl:output encoding="UTF-8"
    method="xml" media-type="application/xhtml+xml"
    doctype-public="-//W3C//DTD XHTML 1.1//EN"
    doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"/>
    -->

    <xsl:output encoding="UTF-8"
        method="html" media-type="text/html"
        />

    <!--
    XXX Using a DRAFT XSLT compatiblity doctype
    See: http://www.contentwithstyle.co.uk/content/xslt-and-html-5-problems

        doctype-public="XSLT-compat"

    Another workaround can be:
    -->
    <xsl:template match="/">
        <xsl:text disable-output-escaping="yes">&lt;</xsl:text>!DOCTYPE html<xsl:text disable-output-escaping="yes">&gt;</xsl:text>
        <xsl:apply-templates select="node()"/>
    </xsl:template>

    <!-- Identity transform with XHTML namespace stripping.
    In order to generate a correct HTML output, i.e. with no stray end tags,
    all elements should be in default namespace instead of the XHTML namespace.
    It might be an LibXSLT specific problem or the standard may also state so.
    See: http://www.eggheadcafe.com/forumarchives/xsl/Aug2005/post23513691.asp
    -->
    <xsl:template match="html:*">
        <xsl:element name="{local-name(.)}">
            <xsl:apply-templates select="@*|node()"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="*">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="text() | @*">
        <xsl:copy />
    </xsl:template>

</xsl:stylesheet>
