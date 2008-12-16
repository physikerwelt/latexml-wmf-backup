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

package LaTeXML::Post::XSLT;
use strict;
use LaTeXML::Util::Pathname;
use LaTeXML::Common::XML;
###use XML::LibXSLT;
use base qw(LaTeXML::Post);

# Useful Options:
#    stylesheet : path to XSLT stylesheet.
#    css        : array of paths to CSS stylesheets.
sub new {
  my($class,%options)=@_;
  my $self = $class->SUPER::new(%options);
  $$self{css} = $options{css};
  my $stylesheet = $options{stylesheet};
  $self->Error(undef,"No stylesheet specified!") unless $stylesheet;
  if(!ref $stylesheet){
    my $pathname = pathname_find($stylesheet,
				 types=>['xsl'],installation_subdir=>'style');
    $self->Error(undef,"No stylesheet \"$stylesheet\" found!")
      unless $pathname && -f $pathname;
    $stylesheet = $pathname; }
  $stylesheet = LaTeXML::Common::XML::XSLT->new($stylesheet);
  if((!ref $stylesheet) || !($stylesheet->can('transform'))){
    $self->Error(undef,"Stylesheet \"$stylesheet\" is not a usable stylesheet!"); }
  $$self{stylesheet}=$stylesheet;
  my %params = ();
  %params = %{$options{parameters}} if $options{parameters};
  $$self{parameters}={%params};
  $self; }

sub process {
  my($self,$doc)=@_;
  my $css = $$self{css};
  my $dir = $doc->getDestinationDirectory;
  my $cssparam = ($css ? join('|',map(pathname_relative($_,$dir),@$css)) : undef);
  # Copy the CSS file to the destination. if found & needed.
  $doc->new($$self{stylesheet}->transform($doc->getDocument,
					  ($cssparam ? (CSS=>"'$cssparam'") :()),
					  %{$$self{parameters}})); }

# ================================================================================
1;

