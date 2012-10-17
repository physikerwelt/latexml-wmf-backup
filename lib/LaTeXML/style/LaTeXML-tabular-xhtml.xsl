<?xml version="1.0" encoding="utf-8"?>
<!--
/=====================================================================\ 
|  LaTeXML-tabular-xhtml.xsl                                          |
|  Converting tabular to xhtml                                        |
|=====================================================================|
| Part of LaTeXML:                                                    |
|  Public domain software, produced as part of work done by the       |
|  United States Government & not subject to copyright in the US.     |
|=====================================================================|
| Bruce Miller <bruce.miller@nist.gov>                        #_#     |
| http://dlmf.nist.gov/LaTeXML/                              (o o)    |
\=========================================================ooo==U==ooo=/
-->
<xsl:stylesheet
    version     = "1.0"
    xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
    xmlns:ltx   = "http://dlmf.nist.gov/LaTeXML"
    xmlns       = "http://www.w3.org/1999/xhtml"
    xmlns:f     = "http://dlmf.nist.gov/LaTeXML/functions"
    extension-element-prefixes="f"
    exclude-result-prefixes = "ltx f">

  <!-- ======================================================================
       Tabulars
       ====================================================================== -->

  <xsl:template match="ltx:tabular">
    <xsl:text>&#x0A;</xsl:text>
    <table>
      <xsl:call-template name="add_id"/>
      <xsl:call-template name="add_attributes"/>
      <xsl:apply-templates/>
      <xsl:text>&#x0A;</xsl:text>
    </table>
  </xsl:template>

  <xsl:template match="ltx:thead">
    <xsl:text>&#x0A;</xsl:text>
    <thead>
      <xsl:call-template name="add_id"/>
      <xsl:call-template name="add_attributes"/>
      <xsl:apply-templates/>
      <xsl:text>&#x0A;</xsl:text>
    </thead>
  </xsl:template>

  <xsl:template match="ltx:tbody">
    <xsl:text>&#x0A;</xsl:text>
    <tbody>
      <xsl:call-template name="add_id"/>
      <xsl:call-template name="add_attributes"/>
      <xsl:apply-templates/>
      <xsl:text>&#x0A;</xsl:text>
    </tbody>
  </xsl:template>

  <xsl:template match="ltx:tfoot">
    <xsl:text>&#x0A;</xsl:text>
    <tfoot>
      <xsl:call-template name="add_id"/>
      <xsl:call-template name="add_attributes"/>
      <xsl:apply-templates/>
      <xsl:text>&#x0A;</xsl:text>
    </tfoot>
  </xsl:template>

  <xsl:template match="ltx:tr">
    <xsl:text>&#x0A;</xsl:text>
    <tr>
      <xsl:call-template name="add_id"/>
      <xsl:call-template name="add_attributes"/>
      <xsl:apply-templates/>
    </tr>
  </xsl:template>

  <xsl:template match="ltx:td">
    <xsl:text>&#x0A;</xsl:text>
    <xsl:element name="{f:if(@thead,'th','td')}">
      <xsl:call-template name="add_id"/>
      <xsl:call-template name="add_attributes">
	<xsl:with-param name="extra_classes">
	  <xsl:if test="@border"><xsl:value-of select="@border"/></xsl:if>
	</xsl:with-param>
      </xsl:call-template>
      <xsl:if test="@colspan">
	<xsl:attribute name='colspan'><xsl:value-of select='@colspan'/></xsl:attribute>
      </xsl:if>
      <xsl:if test="@rowspan">
	<xsl:attribute name='rowspan'><xsl:value-of select='@rowspan'/></xsl:attribute>
      </xsl:if>
      <xsl:choose>
	<xsl:when test="starts-with(@align,'char:')">
	  <xsl:attribute name='align'>char</xsl:attribute>
	  <xsl:attribute name='char'>
	    <xsl:value-of select="substring-after(@align,'char:')"/>
	  </xsl:attribute>
	</xsl:when>
	<xsl:when test="@align">
	  <xsl:attribute name='align'><xsl:value-of select='@align'/></xsl:attribute>
	</xsl:when>
      </xsl:choose>
      <xsl:choose>
	<xsl:when test="@width">
	  <xsl:attribute name='width'><xsl:value-of select="@width"/></xsl:attribute>
	</xsl:when>
      </xsl:choose>
      <xsl:apply-templates/>
    </xsl:element>
  </xsl:template>

</xsl:stylesheet>
