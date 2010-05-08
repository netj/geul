<?xml version="1.0"?>
<!-- 
XSLT for presenting Geul articles in HTML
Author: Jaeho Shin &lt;netj@sparcs.org>
Created: 2009-06-04
-->
<xsl:stylesheet version="1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:atom="http://www.w3.org/2005/Atom"
    xmlns:geul="http://netj.org/2009/geul"
    xmlns:exsl="http://exslt.org/common"
    xmlns:dt="http://xsltsl.org/date-time"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    exclude-result-prefixes="html atom geul exsl dt dc"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:import href="id.xsl"/>
    <xsl:import href="date.xsl"/>
    <xsl:import href="atom2html.xsl"/>

    <xsl:output method="xml"/>

    <xsl:param name="Id"/>
    <xsl:param name="BaseURL">
        <xsl:call-template name="relative-base-url">
            <xsl:with-param name="path" select="$Id"/>
        </xsl:call-template>
    </xsl:param>
    <xsl:template name="relative-base-url">
        <xsl:param name="path"/>
        <xsl:if test="contains($path, '/')">
            <xsl:text>../</xsl:text>
            <xsl:call-template name="relative-base-url">
                <xsl:with-param name="path" select="substring-after($path, '/')"/>
            </xsl:call-template>
        </xsl:if>
    </xsl:template>
    <xsl:variable name="BaseURLPath"
        select="concat('/', substring-after(
            substring-after($BaseURL, '://'), '/'))"/>

    <xsl:template match="/">
        <html>
            <head>
                <xsl:apply-templates select="." mode="meta"/>
            </head>
            <body>
                <xsl:apply-templates select="." mode="head"/>
                <article id="body">
                    <section>
                        <xsl:apply-templates select="." mode="body"/>
                    </section>
                </article>
                <xsl:apply-templates select="." mode="foot"/>
            </body>
        </html>
    </xsl:template>


    <xsl:template match="*" mode="meta">
        <xsl:if test="$BaseURL">
            <base href="{$BaseURL}"/>
        </xsl:if>
        <!-- TODO use geul:title() instead -->
        <title><xsl:value-of select="normalize-space(//html:head/html:title)"/></title>
        <link rel="stylesheet" type="text/css" href="chrome/geul.css"/>
        <script type="text/javascript" src="chrome/geul.js">;</script>
        <meta name="PermaLink" content="{$BaseURL}{$Id}"/>
    </xsl:template>

    <xsl:template match="*" mode="head">
        <header id="head">
            <h1 id="title">
                <xsl:apply-templates select="." mode="title"/>
            </h1>
            <div id="updating">
                <xsl:apply-templates select="." mode="updating"/>
            </div>
        </header>
    </xsl:template>

    <xsl:template match="*" mode="body">
        <xsl:apply-templates select="//html:body/node()"/>
    </xsl:template>

    <xsl:template match="*" mode="foot">
        <footer id="foot">
            <xsl:comment> foot </xsl:comment>
        </footer>
    </xsl:template>

    <xsl:template match="*" mode="title">
        <xsl:value-of select="//html:head/html:title"/>
    </xsl:template>

    <xsl:template match="*" mode="updating">
        <xsl:variable name="revision" select="//geul:revision[1]"/>
        <div id="created" class="timestamp">
            <xsl:choose>
                <xsl:when test="//geul:revision">
                    <xsl:apply-templates select="(
                        //html:meta[@name='created']/@content |
                        //geul:revision[last()]/@date)[1]" mode="date"/>
                    <xsl:if test="contains($revision/@status, 'DRAFT')"> (작성중)</xsl:if>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:comment>not available</xsl:comment>
                </xsl:otherwise>
            </xsl:choose>
        </div>
        <div id="modified" class="timestamp">
            <xsl:choose>
                <xsl:when test="//geul:revision">
                    <xsl:apply-templates select="$revision/@date" mode="abbrv"/>
                    <xsl:text>, </xsl:text>
                    <xsl:value-of select="$revision/@number"/><xsl:text>판</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:comment>not available</xsl:comment>
                </xsl:otherwise>
            </xsl:choose>
        </div>
    </xsl:template>



    <xsl:template match="@author | @location">
        <xsl:value-of select="."/>
    </xsl:template>


    <!-- some elements -->

    <!-- fix plain intra-links with titles -->
    <!--
    <xsl:variable name="LinksURL" select="concat($BASE, $Id, '.links')"/>
    <xsl:template match="html:a[@href = .]">
        <xsl:variable name="Links" select="document($LinksURL)/geul:links"/>
        <xsl:variable name="a" select="$Links/html:a[@href=current()/@href]"/>
        <xsl:copy>
            <xsl:copy-of select="@*"/>
            <xsl:choose>
                <xsl:when test="$a">
                    <xsl:copy-of select="$a/node()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:copy-of select="node()"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:copy>
    </xsl:template>
    -->

    <xsl:template match="html:pre[html:code]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:attribute name="class">code</xsl:attribute>
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="html:a">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <!-- TODO replace with title -->
            <xsl:apply-templates select="node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template match="html:a/@href | html:img/@src">
        <xsl:call-template name="rewrite-link"/>
    </xsl:template>

    <xsl:template name="rewrite-link">
        <xsl:param name="SelfURL">
            <!-- @ can mean $Id or atom:link -->
            <xsl:variable name="atom-link" select="ancestor::atom:entry/atom:link"/>
            <xsl:choose>
                <xsl:when test="$atom-link">
                    <xsl:value-of select="$atom-link/@href"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="$Id"/>
                </xsl:otherwise>
            </xsl:choose>
        </xsl:param>
        <xsl:choose>
            <xsl:when test="starts-with(., '/') or contains(., '://')">
                <xsl:copy-of select="."/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:attribute name="{name(.)}">
                    <xsl:value-of select="$BaseURLPath"/>
                    <xsl:choose>
                        <!-- replace only the first @ -->
                        <xsl:when test="starts-with(., '@')">
                            <xsl:value-of select="$SelfURL"/>
                            <xsl:value-of select="substring-after(.,'@')"/>
                        </xsl:when>
                        <xsl:otherwise>
                            <xsl:value-of select="."/>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:attribute>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
