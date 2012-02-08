# /=====================================================================\ #
# |  LaTeXML::Post::MathPath                                            | #
# | Tool for finding math tokens in formula                             | #
# |=====================================================================| #
# | Part of LaTeXML:                                                    | #
# |  Public domain software, produced as part of work done by the       | #
# |  United States Government & not subject to copyright in the US.     | #
# |---------------------------------------------------------------------| #
# | Bruce Miller <bruce.miller@nist.gov>                        #_#     | #
# | http://dlmf.nist.gov/LaTeXML/                              (o o)    | #
# \=========================================================ooo==U==ooo=/ #

# ================================================================================
# LaTeXML::Post::MathPath  
#  Translate (eventually?)(a subset of?) math expressions, in the form of
# the text attribute generated by MathParser, into XPath expressions
# which will select the appropriate XMath nodes.
# ================================================================================
package LaTeXML::Post::MathPath;
use strict;
#use LaTeXML::Post::MathDictionary;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = (qw(&constructMathPath));
our @EXPORT = (qw(&constructMathPath));

our %table;
# Construct an XPath selector from a textual math expression.
# Returns undef if it can't understand the expression.
# Options are:
#   undeclared=>1 only selects nodes that don't have POS (part of speech) attribute.
#   container=>1 selects XMath nodes that have matching nodes, 
#     rather than the nodes themselves.
#   label=>$label only selects nodes within some element labeled by $label
#   refnum=>$refnum only selects nodes within some element with refnum = $refnum
sub constructMathPath {
  my($pattern,%options)=@_;
  my $nested = $pattern;
  # Replace ( and ) by markers noting the nesting level.
  my $level=0;
  $nested =~ s/(\(|\))/{ ($1 eq "\(" ? "#O".++$level."#" : "#C".$level--."#"); }/ge;
  my @xpaths = constructXPath1($nested);
  return undef unless scalar(@xpaths)==1; # Too many parts or not enough??
  my $xpath = $xpaths[0];
  return undef unless defined $xpath;
  # Add conditional to restrict to undeclared items.
  $xpath .= "[not(ancestor::XMWrap)][not(\@POS)]" if $options{undeclared};
  $xpath .= "[\@font='$options{font}']" if defined $options{font};
  # Wrap approriately to select containing XMath, or just node.
  $xpath = ($options{container} ? "//XMath[descendant::".$xpath."]" : "//".$xpath);
  # Add restrictions for  label or refnum.
  $xpath .= "[ancestor-or-self::*[\@label='$options{label}']]" if defined $options{label};
  $xpath .= "[ancestor-or-self::*[\@refnum='$options{refnum}']]" if defined $options{refnum};
  $xpath; }

# If we can work something out for infix, maybe we can leverage the
# stuff in MathDictionary!

BEGIN{
  %table=(subscript=>\&dosubscript,
	      map(($_=>\&doaccent), (qw(OverHat OverCheck OverBreve OverAcute OverGrave 
					OverTilde OverBar OverArrow
					OverDot OverDoubleDot OverLine OverBrace
					UnderLine UnderBrace))));

}
sub constructXPath1 {
  my($expr)=@_;
  my @stuff;
  do {
    if($expr =~ s/^(\w+)#O(\d+)#(.*)#C\2#//){
      my($op,$args)=($1,$3);
      my $fcn = $table{$op};
      my @args = constructXPath1($args);
      return undef if !defined $op or grep(!defined $_,@args);
      push(@stuff,&$fcn($op,@args)); }
    elsif($expr =~ s/^(\w+)//){
      my $name = $1;
     push(@stuff,"XMTok[\@name='$name' or text()='$name']"); }
    elsif($expr =~ s/^\$//){
     push(@stuff,"*"); }
    elsif($expr =~ s/^(.)//){
      my $name = $1;
     push(@stuff,"XMTok[\@name='$name' or text()='$name']"); }
    else { 
      return undef;	}	# Unmatched stuff? 
    } while($expr =~ s/^,//);

  @stuff; }

sub dosubscript {
  my($op,$base,$script)=@_;
  if(defined $script){
    $base
      ."[following-sibling::*[1][self::XMApp][\@name='PostSubscript']"
	."[child::*[1][self::XMArg/$script]]"
	  ."]"; }
  else {
    $base
      ."[following-sibling::*[1][self::XMApp][\@name='PostSubscript']]"; }
  }

sub doaccent {
  my($op,$var)=@_;
  "XMApp[child::*[1][self::XMTok[\@name='$op']]][child::*[2][self::XMArg[child::$var]]]"; }

# ================================================================================
1;