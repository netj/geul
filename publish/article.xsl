<?xml version="1.0"?>
<!-- 
XSLT for presenting Geul articles in HTML
Author: Jaeho Shin &lt;netj@sparcs.org>
Created: 2009-06-04
-->
<xsl:stylesheet version="1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:geul="http://netj.org/2009/geul"
    xmlns:exsl="http://exslt.org/common"
    xmlns:dt="http://xsltsl.org/date-time"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    exclude-result-prefixes="geul html exsl dt dc"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:import href="date.xsl"/>

    <xsl:output method="xml"/>

    <xsl:param name="ArticleId"/>
    <xsl:param name="BaseURL">
        <xsl:call-template name="relative-base-url">
            <xsl:with-param name="path" select="$ArticleId"/>
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

    <xsl:template match="/">
        <html>
            <head>
                <xsl:apply-templates select="." mode="meta"/>
            </head>
            <body>
                <div id="main">
                    <xsl:apply-templates select="." mode="head"/>
                    <div id="body">
                        <xsl:apply-templates select="." mode="body"/>
                    </div>
                    <xsl:apply-templates select="." mode="foot"/>
                </div>
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
        <meta name="PermaLink" content="{$BaseURL}{$ArticleId}"/>
    </xsl:template>

    <xsl:template match="*" mode="head">
        <div id="head" class="layout">
            <h1 id="title">
                <xsl:apply-templates select="." mode="title"/>
            </h1>
            <div id="updating">
                <xsl:apply-templates select="." mode="updating"/>
            </div>
            <div id="actions" class="tools">
                <xsl:apply-templates select="." mode="actions"/>
            </div>
        </div>
    </xsl:template>

    <xsl:template match="*" mode="body">
        <xsl:apply-templates select="//html:body/node()"/>
    </xsl:template>

    <xsl:template match="*" mode="foot">
        <div id="foot" class="layout">
            <xsl:comment> foot </xsl:comment>
        </div>
    </xsl:template>

    <xsl:template match="*" mode="title">
        <xsl:value-of select="//html:head/html:title"/>
    </xsl:template>

    <xsl:template match="*" mode="updating">
        <xsl:variable name="revision" select="//geul:revision[1]"/>
        <div id="created" class="timestamp">
            <xsl:apply-templates select="(
                //html:meta[@name='created']/@content |
                //geul:revision[last()]/@date)[1]" mode="date"/>
            <xsl:if test="contains($revision/@status, 'DRAFT')"> (작성중)</xsl:if>
        </div>
        <div id="modified" class="timestamp">
            <xsl:apply-templates select="$revision/@date" mode="abbrv"/>
            <xsl:text>, </xsl:text>
            <xsl:value-of select="$revision/@number"/><xsl:text>판</xsl:text>
        </div>
    </xsl:template>

    <xsl:template match="*" mode="actions">
        <xsl:comment> actions </xsl:comment>
        <!--
        <ul>
            <xsl:if test="$IdMonth != ''">
                <li><a href="{$IdMonth}/">달력</a></li>
            </xsl:if>
            <li><a href="./{$Id}">읽기</a></li>
            <li><a href="./{$Id}:changes">바뀐 점</a></li>
            <li><a href="./{$Id}:related">관련 글</a></li>
            <li><a href="./{$Id}:watch">지켜보기</a></li>
            <li><a href="./{$Id}:printable">인쇄판</a></li>
        </ul>
        -->
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

    <!-- Use identity transform as default.
    See: http://www.dpawson.co.uk/xsl/sect2/identity.html#d5343e103 -->
    <xsl:template match="node()|@*">
        <xsl:copy>
            <xsl:apply-templates select="node()|@*"/>
        </xsl:copy>
    </xsl:template>

</xsl:stylesheet>
