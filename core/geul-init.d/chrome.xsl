<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns:bood="http://netj.org/2004/bood"
    exclude-result-prefixes="html bood"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

    <xsl:param name="BaseURL" select="'http://example.org/'"/>

    <xsl:output encoding="UTF-8"
        method="xml" media-type="application/xhtml+xml"
        doctype-public="-//W3C//DTD XHTML 1.1//EN"
        doctype-system="http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd"
        />

    <xsl:variable name="PermaLink" select="//html:meta[@name='PermaLink']/@content"/>
    <xsl:variable name="Id" select="substring-after($PermaLink, $BaseURL)"/>
    <xsl:variable name="IdYear" select="substring-before($Id, '/')"/>
    <xsl:variable name="IdMonth" select="substring-before(substring-after($Id, '/'), '/')"/>
    <xsl:variable name="IdName" select="substring-after($Id, concat($IdYear, '/', $IdMonth, '/'))"/>

    <!--
    <xsl:template match="html:head">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <meta charset="UTF-8"/>
            <xsl:apply-templates select="html:*[local-name() != 'title']"/>
            <title><xsl:value-of select="html:title"/> - example.org</title>
            <link rel="alternate" type="application/atom+xml" title="example.org" href="http://feeds.feedburner.com/example"/>
            <link rel="stylesheet" type="text/css" href="chrome/j.css"/>
            <link rel="icon" href="example.png"/>
            <script type="text/javascript" src="chrome/top.js">;</script>
        </xsl:copy>
    </xsl:template>
    -->

    <!--
    <xsl:template match="html:body">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <div id="frame">
                <xsl:call-template name="site-head"/>
                <div id="main">
                    <xsl:apply-templates select="node()[@id='head']"/>
                    <xsl:apply-templates select="node()[@id='body']"/>
                    <xsl:call-template name="comments"/>
                    <xsl:apply-templates select="node()[@id='foot']"/>
                </div>
                <xsl:apply-templates select="node()[@id!='head' and @id!='body' and @id!='foot']"/>
                <nav id="navigation">
                </nav>
                <aside id="aside">
                </aside>
                <xsl:call-template name="site-foot"/>
            </div>
            <xsl:call-template name="scripts"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template name="site-head">
        <header id="site-head">
            <div id="site-title">Geul Example Site</div>
        </header>
    </xsl:template>

    <xsl:template name="site-foot">
        <footer id="site-foot">
            <span id="copyright">
                ©
                2010
                Author Name
            </span>
        </footer>
    </xsl:template>

    <xsl:template name="comments">
        <section id="comments">
            <div id="disqus_thread"><xsl:comment>comments</xsl:comment></div>
            <script type="text/javascript">
                /**
                * var disqus_identifier; [Optional but recommended: Define a unique identifier (e.g. post id or slug) for this thread] 
                */
                (function() {
                var dsq = document.createElement('script'); dsq.type = 'text/javascript'; dsq.async = true;
                dsq.src = 'http://example.disqus.com/embed.js';
                (document.getElementsByTagName('head')[0] || document.getElementsByTagName('body')[0]).appendChild(dsq);
                })();
            </script>
            <noscript>Please enable JavaScript to view the <a href="http://disqus.com/?ref_noscript=example">comments powered by Disqus.</a></noscript>
            <a href="http://disqus.com" class="dsq-brlink">blog comments powered by <span class="logo-disqus">Disqus</span></a>
        </section>
    </xsl:template>

    <xsl:template name="scripts">
        <script type="text/javascript">
            <xsl:text disable-output-escaping="yes">
                //&lt;![CDATA[
                (function() {
                var links = document.getElementsByTagName('a');
                var query = '?';
                for(var i = 0; i &lt; links.length; i++) {
                if(links[i].href.indexOf('#disqus_thread') >= 0) {
                query += 'url' + i + '=' + encodeURIComponent(links[i].href) + '&amp;';
                }
                }
                document.write('&lt;script charset="utf-8" type="text/javascript" src="http://disqus.com/forums/example/get_num_replies.js' + query + '">&lt;/' + 'script>');
                })();
                //]]&gt;
            </xsl:text>
        </script>

        <script type="text/javascript">
            var _gaq = _gaq || [];
            _gaq.push(['_setAccount', 'UA-1621845-1']);
            _gaq.push(['_setLocalRemoteServerMode']);
            _gaq.push(['_trackPageview']);
            (function() {
            var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
            ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
            var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
            })();
        </script>

        <script type="text/javascript" src="chrome/bottom.js">;</script>
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

