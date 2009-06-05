<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:geul="http://netj.org/2009/geul"
    xmlns:dt="http://xsltsl.org/date-time"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    exclude-result-prefixes="html geul dt dc"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:import href="xsltsl/string.xsl"/>
    <xsl:import href="xsltsl/date-time.xsl"/>

    <xsl:template match="@date | dc:date | @generated | @created">
        <xsl:apply-templates select="." mode="date"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="time"/>
    </xsl:template>

    <xsl:template match="*|@*" mode="date">
        <xsl:variable name="date">
            <xsl:apply-templates select="." mode="dateabbrv"/>
        </xsl:variable>
        <!-- TODO: use dt:format-date-time -->
        <xsl:variable name="year" select="substring-before($date, '-')"/>
        <xsl:variable name="monthday" select="substring-after($date, '-')"/>
        <xsl:variable name="month" select="substring-before($monthday, '-')"/>
        <xsl:variable name="daywithname" select="substring-after($monthday, '-')"/>
        <xsl:variable name="day" select="substring-before($daywithname, ' ')"/>
        <xsl:variable name="dayname" select="substring-after($daywithname, ' ')"/>

        <xsl:value-of select="$year"/><xsl:text>년 </xsl:text>
        <xsl:value-of select="number($month)"/><xsl:text>월 </xsl:text>
        <xsl:value-of select="number($day)"/><xsl:text>일 </xsl:text>
        <xsl:value-of select="$dayname"/><xsl:text>요일</xsl:text>
    </xsl:template>

    <xsl:template match="*|@*" mode="time">
        <xsl:variable name="time">
            <xsl:apply-templates select="." mode="timeabbrv"/>
        </xsl:variable>
        <xsl:variable name="zone" select="substring-after(., $time)"/>
        <xsl:variable name="hour" select="substring-before($time, ':')"/>
        <xsl:variable name="minsec" select="substring-after($time, ':')"/>
        <xsl:variable name="min" select="substring-before($minsec, ':')"/>
        <xsl:variable name="sec" select="substring-after($minsec, ':')"/>

        <xsl:value-of select="number($hour)"/><xsl:text>시 </xsl:text>
        <xsl:value-of select="number($min)"/><xsl:text>분 </xsl:text>
        <xsl:value-of select="number($sec)"/><xsl:text>초</xsl:text>
    </xsl:template>

    <xsl:template match="@date | dc:date | @generated" mode="abbrv">
        <xsl:apply-templates select="." mode="dateabbrv"/>
        <xsl:text> </xsl:text>
        <xsl:apply-templates select="." mode="timeabbrv"/>
    </xsl:template>

    <xsl:template match="*|@*" mode="dateabbrv">
        <xsl:call-template name="dt:format-date-time">
            <xsl:with-param name="xsd-date-time" select="."/>
            <xsl:with-param name="format" select="'%Y-%m-%d '"/>
        </xsl:call-template>
        <xsl:call-template name="name-of-day">
            <xsl:with-param name="day">
                <xsl:call-template name="dt:calculate-day-of-the-week">
                    <xsl:with-param name="year">
                        <xsl:call-template name="dt:get-xsd-datetime-year">
                            <xsl:with-param name="xsd-date-time" select="."/>
                        </xsl:call-template>
                    </xsl:with-param>
                    <xsl:with-param name="month">
                        <xsl:call-template name="dt:get-xsd-datetime-month">
                            <xsl:with-param name="xsd-date-time" select="."/>
                        </xsl:call-template>
                    </xsl:with-param>
                    <xsl:with-param name="day">
                        <xsl:call-template name="dt:get-xsd-datetime-day">
                            <xsl:with-param name="xsd-date-time" select="."/>
                        </xsl:call-template>
                    </xsl:with-param>
                </xsl:call-template>
            </xsl:with-param>
        </xsl:call-template>
    </xsl:template>

    <xsl:template match="*|@*" mode="timeabbrv">
        <xsl:call-template name="dt:format-date-time">
            <xsl:with-param name="xsd-date-time" select="."/>
            <xsl:with-param name="format" select="'%H:%M:%S'"/>
        </xsl:call-template>
    </xsl:template>

    <xsl:template name="name-of-day">
        <xsl:param name="day"/>
        <xsl:choose>
            <xsl:when test="$day = 0">일</xsl:when>
            <xsl:when test="$day = 1">월</xsl:when>
            <xsl:when test="$day = 2">화</xsl:when>
            <xsl:when test="$day = 3">수</xsl:when>
            <xsl:when test="$day = 4">목</xsl:when>
            <xsl:when test="$day = 5">금</xsl:when>
            <xsl:when test="$day = 6">토</xsl:when>
            <xsl:otherwise/>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
