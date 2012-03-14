# /=====================================================================\ #
# |  LaTeXML::Post::XSLT                                                | #
# | Postprocessor for XSL Transform                                     | #
# |=====================================================================| #
# | Part of LaTeXML:                                                    | #
# |  Public domain software, produced as part of work done by the       | #
# |  United States Government & not subject to copyright in the US.     | #
# |---------------------------------------------------------------------| #
# | Bruce Miller <bruce.miller@nist.gov>                        #_#     | #
# | http://dlmf.nist.gov/LaTeXML/                              (o o)    | #
# \=========================================================ooo==U==ooo=/ #
# ================================================================================
# LaTeXML::Post::MathParser  Math Parser for LaTeXML using Parse::RecDescent.
# Parse the intermediate representation generated by the TeX processor.
# ================================================================================
package LaTeXML::Post::XSLT;
use strict;
use XML::LibXML;
use XML::LibXSLT;

sub new {
  my($class,%options)=@_;
  bless {},$class; }

sub process {
  my($self,$doc,%options)=@_;
  my $stylesheet = $options{stylesheet};
  if(!$stylesheet){
    foreach my $dir (@INC){
      my $xsl = "$dir/LaTeXML/dtd/LaTeXML.xsl";
      if(-f $xsl){ $stylesheet=$xsl; last; }}}
  if($stylesheet && !(ref $stylesheet)){
    my $ssdoc = XML::LibXML->new()->parse_file($stylesheet);
    $stylesheet = XML::LibXSLT->new()->parse_stylesheet($ssdoc); }
  die "No Stylesheet found!" unless $stylesheet;
  $stylesheet->transform($doc, 
			 ($options{CSS} ? (CSS=>"'$options{CSS}'") :())); }
# ================================================================================
1;
