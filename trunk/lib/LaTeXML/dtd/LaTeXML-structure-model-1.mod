<!--
 /=====================================================================\ 
 |  LaTeXML-model-1.dtd                                                |
 | Modular DTD model for LaTeXML generated documents                   |
 |=====================================================================|
 | Part of LaTeXML:                                                    |
 |  Public domain software, produced as part of work done by the       |
 |  United States Government & not subject to copyright in the US.     |
 |=====================================================================|
 | Bruce Miller <bruce.miller@nist.gov>                        #_#     |
 | http://dlmf.nist.gov/LaTeXML/                              (o o)    |
 \=========================================================ooo==U==ooo=/
-->

<!-- In case the driver hasn't alread set these: -->
<!ENTITY % LaTeXML.SectionalFrontMatter.class
	 "%LaTeXML-structure.SectionalFrontMatter.class;">
<!ENTITY % LaTeXML.FrontMatter.class
	 "%LaTeXML-structure.SectionalFrontMatter.class; %LaTeXML-structure.FrontMatter.class;">
<!ENTITY % LaTeXML.BackMatter.class
	 "%LaTeXML-structure.BackMatter.class;">

<!-- note that frontmatter and backmatter are not forced to be ordered -->

<!-- ======================================================================
     Document Structure
     ====================================================================== -->

<!ELEMENT %LaTeXML.document.qname;
          ((%LaTeXML.FrontMatter.class;)*,
	  (%LaTeXML.part.qname;)*,(%LaTeXML.chapter.qname;)*,(%LaTeXML.section.qname;)*,
	  (%LaTeXML.BackMatter.class;)*)>

<!ELEMENT %LaTeXML.part.qname;
          ((%LaTeXML.SectionalFrontMatter.class;)*,
	  (%LaTeXML.chapter.qname;)*)>

<!ELEMENT %LaTeXML.chapter.qname;
          ((%LaTeXML.SectionalFrontMatter.class;)*, 
	  (%LaTeXML.section.qname;)*)>

<!ELEMENT %LaTeXML.section.qname;
          ((%LaTeXML.SectionalFrontMatter.class;)*,
	  (%LaTeXML.Para.mix;)*, (%LaTeXML.paragraph.qname;)*, (%LaTeXML.subsection.qname;)*)>
<!ELEMENT %LaTeXML.appendix.qname;
          ((%LaTeXML.SectionalFrontMatter.class;)*,
	  (%LaTeXML.Para.mix;)*, (%LaTeXML.paragraph.qname;)*, (%LaTeXML.subsection.qname;)*)>
<!ELEMENT %LaTeXML.subsection.qname;
          ((%LaTeXML.SectionalFrontMatter.class;)*,
	  (%LaTeXML.Para.mix;)*, (%LaTeXML.paragraph.qname;)*, (%LaTeXML.subsubsection.qname;)*)>
<!ELEMENT %LaTeXML.subsubsection.qname;
          ((%LaTeXML.SectionalFrontMatter.class;)*,
	  (%LaTeXML.Para.mix;)*, (%LaTeXML.paragraph.qname;)*)>
<!ELEMENT %LaTeXML.paragraph.qname;
          ((%LaTeXML.SectionalFrontMatter.class;)*,
	  (%LaTeXML.Para.mix;)*)>
<!ELEMENT %LaTeXML.bibliography.qname; 
	  ((%LaTeXML.SectionalFrontMatter.class;)?,
	  (%LaTeXML-bib.biblist.qname;)*)>
<!ELEMENT %LaTeXML.index.qname; 
	  ((%LaTeXML.SectionalFrontMatter.class;)?,
           (%LaTeXML.indexlist.qname;)*)>

<!ATTLIST %LaTeXML.document.qname;      %LaTeXML.Common.attrib; %LaTeXML.Labelled.attrib;>
<!ATTLIST %LaTeXML.part.qname;          %LaTeXML.Common.attrib; %LaTeXML.Labelled.attrib;>
<!ATTLIST %LaTeXML.chapter.qname;       %LaTeXML.Common.attrib; %LaTeXML.Labelled.attrib;>
<!ATTLIST %LaTeXML.section.qname;       %LaTeXML.Common.attrib; %LaTeXML.Labelled.attrib;>
<!ATTLIST %LaTeXML.appendix.qname;      %LaTeXML.Common.attrib; %LaTeXML.Labelled.attrib;>
<!ATTLIST %LaTeXML.subsection.qname;    %LaTeXML.Common.attrib; %LaTeXML.Labelled.attrib;>
<!ATTLIST %LaTeXML.subsubsection.qname; %LaTeXML.Common.attrib; %LaTeXML.Labelled.attrib;>
<!ATTLIST %LaTeXML.paragraph.qname;     %LaTeXML.Common.attrib; %LaTeXML.Labelled.attrib;>
<!ATTLIST %LaTeXML.bibliography.qname;  
	  %LaTeXML.Common.attrib; %LaTeXML.Labelled.attrib; 
          files CDATA #IMPLIED>
<!ATTLIST %LaTeXML.index.qname;
	  %LaTeXML.Common.attrib; %LaTeXML.Labelled.attrib;>

<!ELEMENT %LaTeXML.title.qname;        %LaTeXML.Inline.model; >
<!ATTLIST %LaTeXML.title.qname;        %LaTeXML.Common.attrib;>

<!ELEMENT %LaTeXML.toctitle.qname;     %LaTeXML.Inline.model; >
<!ATTLIST %LaTeXML.toctitle.qname;     %LaTeXML.Common.attrib;>

<!ELEMENT %LaTeXML.personname.qname;   %LaTeXML.Inline.model; >
<!ATTLIST %LaTeXML.personname.qname;   %LaTeXML.Common.attrib;>
<!ELEMENT %LaTeXML.contact.qname;      %LaTeXML.Inline.model; >
<!ATTLIST %LaTeXML.contact.qname;
	  %LaTeXML.Common.attrib;
	  role CDATA #IMPLIED>

<!ELEMENT %LaTeXML.creator.qname;       (%LaTeXML.Person.class;)* >
<!ATTLIST %LaTeXML.creator.qname;
	  %LaTeXML.Common.attrib;
	  role CDATA #IMPLIED>

<!ELEMENT %LaTeXML.date.qname;         %LaTeXML.Inline.model;>
<!ATTLIST %LaTeXML.date.qname;
	  %LaTeXML.Common.attrib;
	  role CDATA #IMPLIED>

<!ELEMENT %LaTeXML.abstract.qname;    (%LaTeXML.Para.mix;)*>
<!ATTLIST %LaTeXML.abstract.qname;     %LaTeXML.Common.attrib;>

<!ELEMENT %LaTeXML.acknowledgements.qname; %LaTeXML.Inline.model;>
<!ATTLIST %LaTeXML.acknowledgements.qname; %LaTeXML.Common.attrib;>

<!ELEMENT %LaTeXML.keywords.qname; %LaTeXML.Inline.model;>
<!ATTLIST %LaTeXML.keywords.qname; %LaTeXML.Common.attrib;>
