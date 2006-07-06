# /=====================================================================\ #
# |  LaTeXML::Post::PresentationMathML                                  | #
# | Presentation MathML generator for LaTeXML                           | #
# |=====================================================================| #
# | Part of LaTeXML:                                                    | #
# |  Public domain software, produced as part of work done by the       | #
# |  United States Government & not subject to copyright in the US.     | #
# |---------------------------------------------------------------------| #
# | Bruce Miller <bruce.miller@nist.gov>                        #_#     | #
# | http://dlmf.nist.gov/LaTeXML/                              (o o)    | #
# \=========================================================ooo==U==ooo=/ #

# ================================================================================
# LaTeXML::MathML  Math Formatter for LaTeXML's Parsed Math.
#   Cooperate with the parsed math structure generated by LaTeXML::Math and
# convert into presentation MathML.
# ================================================================================
# TODO
#  * merging of mrows when operator is `close enough' (eg (+ (+ a b) c) => (+ a b c)
#  * get presentation from DUAL
#  * proper parenthesizing (should I record the parens used when parsing?)
# Some clarity to work out:
#  We're trying to convert either parsed or unparsed math (sometimes intertwined).
# How clearly do these have to be separated?
# ================================================================================
package LaTeXML::Post::PresentationMathML;
use strict;
use LaTeXML::Util::LibXML;
use LaTeXML::Post;
our @ISA = (qw(LaTeXML::Post::Processor));

our $mmlURI = "http://www.w3.org/1998/Math/MathML";

sub process {
  my($self,$doc)=@_;

  $self->cacheIDs($doc);

  $doc->documentElement->setNamespace($mmlURI,'m',0);
  my @math = $self->find_math_nodes($doc);
  $self->Progress("Converting ".scalar(@math)." formulae");
  foreach my $math (@math){
    my $mode = $math->getAttribute('mode')||'inline';
    my ($xmath) = $math->getChildrenByTagNameNS($self->getNamespace,'XMath');
    my $mmlmath = $self->toMathML($xmath,$mode);
    $math->appendChild($mmlmath); }
  $doc; }

# ================================================================================
sub find_math_nodes {
  my($self,$doc)=@_;
  $doc->getElementsByTagNameNS($self->getNamespace,'Math'); }

# ================================================================================

sub toMathML {
  my($self,$math,$mode)=@_;
  my $mmath=new_node($mmlURI,'math',[], 
		   display=>($mode eq 'display' ? 'block' : 'inline'));

  my @nodes= element_nodes($math);
  append_nodes($mmath, map(Expr($_), @nodes));

  # Since Mozilla only breaks at top-level (not in mrows), possibly pull children up.
  # Could also want a sweeping mrow cleanup: mrow w/1 child -> child.
  my @n;
  while((@n = element_nodes($mmath)) && (scalar(@n)==1) && ($n[0]->nodeName eq 'mrow')){
    $mmath->removeChild($n[0]);
    map($mmath->appendChild($_), element_nodes($n[0])); }
  $mmath; }
# ================================================================================

sub getTokenName {
  my($node)=@_;
  my $m = $node->getAttribute('name') || $node->textContent;
  (defined $m ? $m : '?'); }

sub realize {
  my($node)=@_;
  $LaTeXML::Post::PROCESSOR->realizeXMNode($LaTeXML::Post::DOCUMENT,$node); }

# ================================================================================
our $MMLTable={};

sub DefMathML {
  my($key,$sub) =@_;
  $$MMLTable{$key} = $sub; }

# Evolve to be more data-driven, and customizable.
# NOTE: There's an almost-inconsistent usage of open/close attributes.
#  If they are on an XMApp, then they are considered `decoration',
#  If they are on the operator XMTok in an XMApp, they are part of that op's 
#  concept of how it wraps its arguments.... Or something like that.
sub Expr {
  my($node)=@_;
  my $o = $node->getAttribute('open');
  my $c = $node->getAttribute('close');
  my $p = $node->getAttribute('punctuation');
  my $result = ($node->nodeName eq 'XMRef' ? Expr(realize($node)) : Expr_internal($node));
  $result = ( $o || $c ? parenthesize($result,$o,$c) : $result); 
  ($p ? Row($result,Op($p)) : $result); }

sub Expr_internal {
  my($node)=@_;
  return Node('merror',Node('mtext',"Missing Subexpression")) unless $node;
  my $tag = $node->nodeName;
  if($tag eq 'XMDual'){
    my($content,$presentation) = element_nodes($node);
    Expr($presentation); }
  elsif($tag eq 'XMWrap'){	# Only present if parsing failed!
    Row(grep($_,map(Expr($_),element_nodes($node)))); }
  elsif($tag eq 'XMApp'){
    my($op,@args) = element_nodes($node);
    return Node('merror',Node('mtext',"Missing Operator")) unless $op;
    $op = realize($op);		# NOTE: Could loose open/close on XMRef ???
    my $name =  getTokenName($op);
    my $role =  $op->getAttribute('role') || '?';
    my $handler = $$MMLTable{"Apply:$role:$name"} || $$MMLTable{"Apply:?:$name"} 
      || $$MMLTable{"Apply:$role:?"} || $$MMLTable{"Apply:?:?"};
    &$handler($op,@args); }
  elsif($tag eq 'XMTok'){
    my $name =  getTokenName($node);
    my $role  =  $node->getAttribute('role') || '?';
    my $handler = $$MMLTable{"Token:$role:$name"} || $$MMLTable{"Token:?:$name"} 
      || $$MMLTable{"Token:$role:?"} || $$MMLTable{"Token:?:?"};
    &$handler($node); }
  elsif($tag eq 'XMHint'){
    my $name =  getTokenName($node);
    my $handler = $$MMLTable{"Hint:$name"} || $$MMLTable{"Hint:?"};
    &$handler($node); }
  else {
    Node('mtext',[$node->textContent]); }}

sub XXXExprPunct {
  my($node)=@_;
  my $p = $node->getAttribute('punctuation');
  my $result = Expr($node);
  if(!$p){ 
    $result; }
  elsif($result->nodeName eq 'mrow'){
    $result->appendChild(Op($p)); 
    $result; }
  else {
    ($result,Op($p)); }}

sub ExprPunct { Expr(@_);}

sub parenthesize {
  my($node,$open,$close)=@_;
  if(!$open && !$close){
    $node; }
  elsif($node->localName eq 'mrow'){
    $node->insertBefore(Op($open),$node->firstChild) if $open;
    $node->appendChild(Op($close)) if $close; 
    $node; }
  else {
    my @nodes = ($node);
    unshift(@nodes,Op($open)) if $open;
    push(@nodes,Op($close)) if $close;
    Row(@nodes); }}

# ================================================================================
# Mappings between internal fonts & sizes.
# Default math font is roman|medium|upright.
our %mathvariants = ('bold'             =>'bold',
		     'italic'           =>'italic',
		     'bold italic'      =>'bold-italic',
		     'doublestruck'     =>'double-struck',
		     'fraktur bold'     => 'bold-fraktur',
		     'script'           => 'script',
		     'script italic'    => 'script',
		     'script bold'      => 'bold-script',
		     'caligraphic'      => 'script',
		     'caligraphic bold' => 'bold-script',
		     'fraktur'          => 'fraktur',
		     'sansserif'        => 'san-serif',
		     'sansserif bold'   => 'bold-sans-serif',
		     'sansserif italic' => 'sans-serif-italic',
		     'sansserif bold italic'   => 'sans-serif-bold-italic',
		     'typewriter'       => 'monospace');

# ================================================================================
# Helpers
sub Node {
  my($tag,$content,%attr)=@_;
  new_node($mmlURI,"m:$tag",$content,%attr); }

sub Op { Node('mo',[@_]); }
sub Row { Node('mrow',[@_]); }

sub to_mi {
  my($node)=@_;
  my $font =  $node->getAttribute('font');
  my $variant = ($font && $mathvariants{$font})||'';
  my $content =  $node->textContent;
#  my $size = $node->getAttribute('size');
  if($content =~ /^.$/){	# Single char?
    if($variant eq 'italic'){ $variant = ''; } # Defaults to italic
    elsif(!$variant){ $variant = 'normal'; }}  # must say so explicitly.
  Node('mi',$content,($variant ? (mathvariant=>$variant) : ())); }

sub to_mo {
  my($node)=@_;
  my $font =  $node->getAttribute('font');
  my $variant = $font && $mathvariants{$font};
#  my $size = $node->getAttribute('size');
  Node('mo',$node->textContent,
       ($variant ? (mathvariant=>$variant) : ()),
       # If an operator has specifically located it's scripts, don't let mathml move them.
       (($node->getAttribute('stackscripts')||'no') eq 'yes' ? (movablelimits=>'false'):()) ); }

sub Infix {
  my($op,@list)=@_;
  return Row() unless $op && @list;
  my @mlist=();
  if(scalar(@list) == 1){	# Infix with 1 arg is presumably Prefix!
    push(@mlist,(ref $op ? Expr($op) : Node('mo',$op)),Expr($list[0])); }
  else {
    push(@mlist, Expr(shift(@list)));
    while(@list){
      push(@mlist,(ref $op ? Expr($op) : Node('mo',$op)));
      push(@mlist,Expr(shift(@list))); }}
  Row(@mlist); }

sub separated_list {
  my($separators,@args)=@_;
  $separators='' unless defined $separators;
  my $lastsep=', ';
  my @arglist;
  if(@args){
    push(@arglist,Expr(shift(@args)));
    while(@args){
      $separators =~ s/^(.)//;
      $lastsep = $1 if $1;
      push(@arglist,Op($lastsep),Expr(shift(@args))); }}
  @arglist; }
# ================================================================================
# Tokens

DefMathML('Token:?:?',    \&to_mi);

DefMathML('Token:ADDOP:?', \&to_mo);
DefMathML('Token:MULOP:?', \&to_mo);
DefMathML('Token:RELOP:?', \&to_mo);
DefMathML('Token:PUNCT:?', \&to_mo);
DefMathML('Token:SUMOP:?', \&to_mo);
DefMathML('Token:INTOP:?', \&to_mo);
DefMathML('Token:LIMITOP:?', \&to_mo);
DefMathML('Token:OPERATOR:?', \&to_mo);
DefMathML('Token:OPEN:?', \&to_mo);
DefMathML('Token:CLOSE:?', \&to_mo);
DefMathML('Token:MIDDLE:?', \&to_mo);
DefMathML('Token:VERTBAR:?', \&to_mo);
DefMathML('Token:ARROW:?', \&to_mo);
DefMathML('Token:METARELOP:?', \&to_mo);

DefMathML('Token:NUMBER:?',sub { Node('mn',$_[0]->textContent); });
DefMathML('Token:?:Empty', sub { Node('none')} );

DefMathML("Token:?:\x{2061}", \&to_mo); # FUNCTION APPLICATION
DefMathML("Token:?:\x{2062}", \&to_mo); # INVISIBLE TIMES

# ================================================================================
# Hints
DefMathML('Hint:?', sub { undef; });
# ================================================================================
# Applications.

# NOTE: A lot of these special cases could be eliminated by
# consistent creation of XMDual's (using DefMath and similar)

DefMathML('Apply:?:?', sub {
  my($op,@args)=@_;
  my @arglist  = separated_list($op->getAttribute('separators'),@args);
  my $args = (scalar(@arglist)==1 ? $arglist[0] : Row(@arglist));
  Row(Expr($op),Op("\x{2061}"),	# FUNCTION APPLICATION
      parenthesize($args,$op->getAttribute('argopen'),$op->getAttribute('argclose'))); });

DefMathML('Apply:OVERACCENT:?', sub {
  my($accent,$base)=@_;
  Node('mover', [Expr($base),Expr($accent)],accent=>'true'); });

DefMathML('Apply:UNDERACCENT:?', sub {
  my($accent,$base)=@_;
  Node('munder', [Expr($base),Expr($accent)],accent=>'true'); });

# Top level relations
DefMathML('Apply:?:Formulae',sub { 
  my($op,@elements)=@_;
  Row(separated_list($op->getAttribute('separators'),@elements)); });

DefMathML('Apply:?:MultiRelation',sub { 
  my($op,@elements)=@_;
  Row(map(Expr($_),@elements)); });

# Defaults for various parts-of-speech

# For DUAL, just translate the presentation form.
DefMathML('Apply:?:DUAL', sub { Expr($_[2]); });

DefMathML('Apply:?:Superscript', sub {
  my($op,$base,$sup)=@_;
  Node(((($base->getAttribute('stackscripts')||'no') eq 'yes') ? 'mover' : 'msup'),
       [Expr($base),Expr($sup)]); });

DefMathML('Apply:?:Subscript',   sub {
  my($op,$base,$sub)=@_;
  Node(((($base->getAttribute('stackscripts')||'no') eq 'yes') ? 'munder' : 'msub'),
       [Expr($base),Expr($sub)]); });

DefMathML('Apply:?:SubSuperscript',   sub { 
  my($op,$base,$sub,$sup)=@_;
  Node(((($base->getAttribute('stackscripts')||'no') eq 'yes') ? 'munderover' : 'msubsup'),
       [Expr($base),Expr($sub),Expr($sup)]); });

DefMathML('Apply:POSTFIX:?',     sub { Node('mrow',[Expr($_[1]),Expr($_[0])]); });

DefMathML('Apply:?:sideset', sub {
  my($op,$presub,$presup,$postsub,$postsup,$base)=@_;
  Node('mmultiscripts',[Expr($base),Expr($postsub),Expr($postsup), 
			  Node('mprescripts'),Expr($presub),Expr($presup)]); });

DefMathML('Apply:ADDOP:?', \&Infix);
DefMathML('Apply:MULOP:?', \&Infix);
DefMathML('Apply:RELOP:?', \&Infix);
DefMathML('Apply:ARROW:?', \&Infix);
DefMathML('Apply:METARELOP:?',\&Infix);

DefMathML('Apply:FENCED:?',sub {
  my($op,@elements)=@_;
  Row(Op($op->getAttribute('argopen')),
      separated_list($op->getAttribute('separators'),@elements),
      Op($op->getAttribute('argclose'))); });

# Various specific formatters.
DefMathML('Apply:?:sqrt', sub { Node('msqrt',[Expr($_[1])]); });
DefMathML('Apply:?:root', sub { Node('mroot',[Expr($_[2]),Expr($_[1])]); });

# NOTE: Need to handle displaystyle
# It is only handled here by assuming that it is already true!!!
# Need to bind and control it!!!!!
DefMathML('Apply:?:/', sub {
  my($op,$num,$den)=@_;
  my $style = $op->getAttribute('style') || '';
  if($style eq 'inline'){
    Node('mfrac',[Expr($num),Expr($den)], bevelled=>'true'); }
  elsif($style eq 'display') {
    Node('mfrac',[Expr($num),Expr($den)]); }
  else {
    Node('mstyle',[Node('mfrac',[Expr($num),Expr($den)])], displaystyle=>'false'); }
});

DefMathML('Apply:?:deriv',  sub { mml_deriv("\x{2146}",@_); }); # DOUBLE-STRUCK ITALIC SMALL D
DefMathML('Apply:?:pderiv', sub { mml_deriv("\x{2202}",@_); }); # PARTIAL DIFFERENTIAL

DefMathML('Apply:?:LimitFrom', sub {
  my($op,$arg,$dir)=@_;
  Row(Expr($arg),Expr($dir)); });

# NOTE: Need to handle displaystyle
sub mml_deriv {
  my($diffop,$op,$expr,$var,$n)=@_;
  if($n){
    Node('mfrac',[ Row(Node('msup',[Op($diffop),Expr($n)]),Expr($expr)),
		     Node('msup',[Row(Op($diffop),Expr($var)),Expr($n)])],
	 (($op->getAttribute('style')||'') eq 'inline' ? (bevelled=>'true') : ())); }
  else {
    Node('mfrac',[ Row(Op($diffop),Expr($expr)),
		     Row(Op($diffop),Expr($var))],
	 (($op->getAttribute('style')||'') eq 'inline' ? (bevelled=>'true') : ())); }}

DefMathML('Apply:?:diff', sub {  
  my($op,$x,$n)=@_;
  if($n){
    Row(Node('msup',[Op("\x{2146}"),Expr($n)]),Expr($x)); } # DOUBLE-STRUCK ITALIC SMALL D
  else {
    Row(Op("\x{2146}"),Expr($x)); }}); # DOUBLE-STRUCK ITALIC SMALL D

DefMathML('Apply:?:pdiff', sub {  
  my($op,$x,$n)=@_;
  if($n){
    Row(Node('msup',[Op("\x{2202}"),Expr($n)]),Expr($x)); } # PARTIAL DIFFERENTIAL
  else {
    Row(Op("\x{2202}"),Expr($x)); }}); # PARTIAL DIFFERENTIAL

DefMathML('Apply:?:Cases', sub {
  my($op,@cases)=@_;
  Row(Op('{'), Node('mtable',[map(Expr($_),@cases)])); });

DefMathML('Apply:?:Case',sub {
  my($op,@cells)=@_;
  Node('mtr',[map(Node('mtd',[ExprPunct($_)]),@cells)]); });

DefMathML('Apply:?:Array', sub {
  my($op,@rows)=@_;
  Node('mtable',[map(Expr($_),@rows)]); });

DefMathML('Apply:?:Matrix', sub {
  my($op,@rows)=@_;
  my($open,$close)=($op->getAttribute('open'),$op->getAttribute('close'));
  my $table = Node('mtable',[map(Expr($_),@rows)]);
  if($open||$close){
    Row(($open ? Op($open) : ()),$table,($close ? Op($close) : ())); }
  else {
    $table; }});

DefMathML('Apply:?:Row',sub {
  my($op,@cells)=@_;
  Node('mtr',[map(Expr($_),@cells)]); });

DefMathML('Apply:?:Cell',sub {
  my($op,@content)=@_;
  Node('mtd',[map(ExprPunct($_),@content)]); });

DefMathML('Apply:?:binomial', sub {
  my($op,$over,$under)=@_;
  Row(Op('('),Node('mtable',[Node('mtr',[Node('mtd',[Expr($over)])]),
			       Node('mtr',[Node('mtd',[Expr($under)])])]), Op(')')); });

DefMathML('Apply:?:pochhammer',sub {
  my($op,$a,$b)=@_;
  Node('msub',[Row(Op('('),Expr($a),Op(')')),Expr($b)]); });

DefMathML('Apply:?:stacked', sub {
  my($op,$over,$under)=@_;
  Node('mtable',[Node('mtr',[Node('mtd',[Expr($over)])]),
		   Node('mtr',[Node('mtd',[Expr($under)])])]); });

DefMathML('Apply:?:Annotated', sub {
  my($op,$var,$annotation)=@_;
  Row(Expr($var),Expr($annotation));});

# Have to deal w/ screwy structure:
# If denom is a sum/diff then last summand can be: cdots, cfrac 
#  or invisibleTimes of cdots and something which could also be a cfrac!
# NOTE: Deal with cfracstyle!!
sub do_cfrac {
  my($numer,$denom)=@_;
  if($denom->nodeName eq 'XMApp'){ # Denominator is some kind of application
    my ($denomop,@denomargs)=element_nodes($denom);
    if($denomop->getAttribute('role') eq 'ADDOP'){ # Is it a sum or difference?
      my $last = pop(@denomargs);			# Check last operand in denominator.
      # this is the current contribution to the cfrac (if we match the last term)
#      my $curr = Node('mfrac',[Expr($numer),Row(Infix(map(Expr($_),$denomop,@denomargs)),Expr($denomop))]);
      my $curr = Node('mfrac',[Expr($numer),Row(Infix($denomop,@denomargs),Expr($denomop))]);
      if(getTokenName($last) eq 'cdots'){ # Denom ends w/ \cdots
	return ($curr,Expr($last));}		   # bring dots up to toplevel
      elsif($last->nodeName eq 'XMApp'){	   # Denom ends w/ application --- what kind?
	my($lastop,@lastargs)=element_nodes($last);
	if(getTokenName($lastop) eq 'cfrac'){ # Denom ends w/ cfrac, pull it to toplevel
#	  return ($curr,do_cfrac(@lastargs)); }
	  return ($curr,Expr($last)); }
	elsif((getTokenName($lastop) eq "\x{2062}")  # Denom ends w/ * (invisible)
	      && (scalar(@lastargs)==2) && (getTokenName($lastargs[0]) eq 'cdots')){
	  return ($curr,Expr($lastargs[0]),Expr($lastargs[1])); }}}}
  (Node('mfrac',[Expr($numer),Expr($denom)])); }

DefMathML('Apply:?:cfrac', sub {
  my($op,$numer,$denom)=@_;
  Row(do_cfrac($numer,$denom)); });

# NOTE: Markup probably isn't right here....
DefMathML('Apply:?:AT', sub {
  my($op,$expr,$value)=@_;
  Row(Expr($expr),Node('msub',[Op('|'),Expr($value)])); });
# ================================================================================
1;
