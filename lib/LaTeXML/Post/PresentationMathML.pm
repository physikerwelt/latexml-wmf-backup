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
use charnames ":full";

sub new {
  my($class,%options)=@_;
  bless {
	 verbosity => $options{verbosity} || 0},$class; }

sub process {
  my($self,$doc,%options)=@_;
  $$self{verbosity}=$options{verbosity}||0;
  my @math = $self->find_math_nodes($doc);
  $self->Msg(1,"Converting ".scalar(@math)." formulae");
  foreach my $math (@math){
    my $mmath = $self->toMathML($math);
    $math->appendChild($mmath); }

# So we get the mathml.
# We could:
#   (1) add it to the XMath
#   (2) replace the XMath content
#   (3) or the whole XMath.
  $doc; }

sub Msg {
  my($self,$level,$msg)=@_;
  print STDERR "".(ref $self).": $msg\n" if $$self{verbosity}>$level; }

# ================================================================================
sub find_math_nodes {
  my($self,$doc)=@_;
  $doc->findnodes('.//XMath'); }

# ================================================================================

sub toMathML {
  my($self,$math)=@_;
  my $mode = $math->getAttribute('mode');
  my $mmath=new_node('m:math',[], 
		   'xmlns:m'=>"http://www.w3.org/1998/Math/MathML",
		   display=>($mode eq 'display' ? 'block' : 'inline'));
  my @nodes= element_nodes($math);
  append_nodes($mmath, map(Expr($_), @nodes));
  # Since Mozilla only breaks at top-level (not in mrows), possibly pull children up.
  # Could also want a sweeping mrow cleanup: mrow w/1 child -> child.
  my @n;
  while((@n = element_nodes($mmath)) && (scalar(@n)==1) && ($n[0]->nodeName eq 'm:mrow')){
    $mmath->removeChild($n[0]);
    map($mmath->appendChild($_), element_nodes($n[0])); }
  $mmath; }
# ================================================================================

sub getTokenName {
  my($node)=@_;
  my $m = $node->getAttribute('name') || $node->textContent;
  (defined $m ? $m : '?'); }


# ================================================================================
our $MMLTable={};

sub DefMathML {
  my($key,$sub) =@_;
  $$MMLTable{$key} = $sub; }

# Evolve to be more data-driven, and customizable.
sub Expr {
  my($node)=@_;
  my $p = $node->getAttribute('punctuation');
#  my $o = $node->getAttribute('open');
#  my $c = $node->getAttribute('close');
  my @result = Expr_internal($node);
#  if($o){
#    if($result[0]->nodeName eq 'm:mrow'){
#      $result[0]->prependChild(Op($o)); }
#    else {
#      unshift(@result,Op($o)); }}
#  if($c){
#    if($result[$#result]->nodeName eq 'm:mrow'){
#      $result[$#result]->appendChild(Op($c)); }
#    else {
#      push(@result,Op($c)); }}
  if($p){
    if($result[$#result]->nodeName eq 'm:mrow'){
      $result[$#result]->appendChild(Op($p)); }
    else {
      push(@result,Op($p)); }}
  @result; }

sub Expr_internal {
  my($node)=@_;
  return Node('m:merror',Node('m:mtext',"Missing Subexpression")) unless $node;
  my $tag = $node->nodeName;
  if($tag eq 'XMDual'){
    my($content,$presentation) = element_nodes($node);
    Expr($presentation); }
  elsif($tag eq 'XMWrap'){
    Row(grep($_,map(Expr($_),element_nodes($node)))); }
  elsif($tag eq 'XMApp'){
    my($op,@args) = element_nodes($node);
    return Node('m:merror',Node('m:mtext',"Missing Operator")) unless $op;
    my $name =  getTokenName($op);
    my $pos  =  $op->getAttribute('POS') || '?';

    my $sub = $$MMLTable{"Apply:$pos:$name"} || $$MMLTable{"Apply:?:$name"} 
      || $$MMLTable{"Apply:$pos:?"} || $$MMLTable{"Apply:?:?"};
    &$sub($op,@args); }
  elsif($tag eq 'XMTok'){
    my $name =  getTokenName($node);
    my $pos  =  $node->getAttribute('POS') || '?';
    my $sub = $$MMLTable{"Token:$pos:$name"} || $$MMLTable{"Token:?:$name"} 
      || $$MMLTable{"Token:$pos:?"} || $$MMLTable{"Token:?:?"};
    &$sub($node); }
  elsif($tag eq 'XMHint'){
    my $name =  getTokenName($node);
    my $sub = $$MMLTable{"Hint:$name"} || $$MMLTable{"Hint:?"};
    &$sub($node); }
  else {
#    Node('m:mtext',$node->untex); }}
#    Node('m:mtext',[$node->content]); }}
    Node('m:mtext',[$node->textContent]); }}

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
  new_node($tag,$content,%attr); }

sub Op { Node('m:mo',[@_]); }
sub Row { Node('m:mrow',[@_]); }

sub to_mi {
  my($node)=@_;
  my $font =  $node->getAttribute('font');
  my $variant = ($font && $mathvariants{$font})||'';
  my $content =  $node->textContent;
#  my $size = $node->getAttribute('size');
  if($content =~ /^.$/){	# Single char?
    if($variant eq 'italic'){ $variant = ''; } # Defaults to italic
    elsif(!$variant){ $variant = 'normal'; }}  # must say so explicitly.
  Node('m:mi',$content,($variant ? (mathvariant=>$variant) : ())); }

sub to_mo {
  my($node)=@_;
  my $font =  $node->getAttribute('font');
  my $variant = $font && $mathvariants{$font};
#  my $size = $node->getAttribute('size');
  Node('m:mo',$node->textContent,
       ($variant ? (mathvariant=>$variant) : ()),
       # If an operator has specifically located it's scripts, don't let mathml move them.
       (($node->getAttribute('stackscripts')||'no') eq 'yes' ? (movablelimits=>'false'):()) ); }

sub InfixOrPrefix {
  my($op,@list)=@_;
  return @list unless $op && @list;
  $op = Node('m:mo',$op) unless ref $op;
  if(scalar(@list) == 1){	# Infix with 1 arg is presumably Prefix!
    ($op,@list); }
  else {
    my @margs = (shift(@list));
    while(@list){
      push(@margs,$op->cloneNode(1));
      push(@margs,shift(@list)); }
    @margs; }}

sub Infix {
  my($op,@list)=@_;
  return @list unless $op && @list;
  $op = Node('m:mo',$op) unless ref $op;
  my @margs = (shift(@list));
  while(@list){
    push(@margs,$op->cloneNode(1));
    push(@margs,shift(@list)); }
  @margs; }

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
DefMathML('Token:SUBOP:?', \&to_mo);
DefMathML('Token:MULOP:?', \&to_mo);
DefMathML('Token:DIVOP:?', \&to_mo);
DefMathML('Token:RELOP:?', \&to_mo);
DefMathML('Token:PUNCT:?', \&to_mo);
DefMathML('Token:BIGOP:?', \&to_mo);
DefMathML('Token:OPERATOR:?', \&to_mo);
DefMathML('Token:OPEN:?', \&to_mo);
DefMathML('Token:CLOSE:?', \&to_mo);
DefMathML('Token:MIDDLE:?', \&to_mo);
DefMathML('Token:VERTBAR:?', \&to_mo);
DefMathML('Token:LARROW:?', \&to_mo);
DefMathML('Token:RARROW:?', \&to_mo);
DefMathML('Token:ARROW:?', \&to_mo);
DefMathML('Token:METARELOP:?', \&to_mo);

DefMathML('Token:NUMBER:?',sub { Node('m:mn',$_[0]->textContent); });
DefMathML('Token:?:Empty', sub { Node('m:none')} );
# ================================================================================
# Hints
DefMathML('Hint:?', sub { undef; });
DefMathML('Hint:ApplyFunction', sub { Op("\N{FUNCTION APPLICATION}"); });
DefMathML('Hint:InvisibleTimes', sub { Op("\N{INVISIBLE TIMES}"); });
# ================================================================================
# Applications.

# Generic
#DefMathML('Apply:?:?', sub {
#  my($op,@args)=@_;
#  Row(Expr($op),Op("\N{FUNCTION APPLICATION}"),
#      Row(Op($op->getAttribute('open')|| '('),
#	  separated_list($op->getAttribute('separators'),@args),
#	  Op($op->getAttribute('close') || ')'))); });
DefMathML('Apply:?:?', sub {
  my($op,@args)=@_;
  my @arglist  = separated_list($op->getAttribute('separators'),@args);
  unshift(@arglist,Op($op->getAttribute('open'))) if $op->getAttribute('open');
  push(@arglist,Op($op->getAttribute('close'))) if $op->getAttribute('close');
  Row(Expr($op),Op("\N{FUNCTION APPLICATION}"), Row(@arglist)); });

# Top level relations
DefMathML('Apply:?:Formulae',sub { 
  my($op,@elements)=@_;
  Row(separated_list($op->getAttribute('separators'),@elements)); });
DefMathML('Apply:?:MultiRelation',sub { 
  my($op,@elements)=@_;
  Row(map(Expr($_),@elements)); });

# Covered by POS=FENCED ??
#DefMathML('Apply:?:Collection',sub { 
#  my($op,@elements)=@_;
#  Row(separated_list($op->getAttribute('separators'),@elements)); });

DefMathML('Apply:RARROW:?',sub { 
  my($op,$var,$limit,$from)=@_;
  Row(Expr($var),Expr($op),Expr($limit),($from ? (Expr($from)) :())); });

# Defaults for various parts-of-speech

# For DUAL, just translate the presentation form.
DefMathML('Apply:?:DUAL', sub { Expr($_[2]); });

DefMathML('Apply:?:Superscript', sub {
  my($op,$base,$sup)=@_;
  Node(((($base->getAttribute('stackscripts')||'no') eq 'yes') ? 'm:mover' : 'm:msup'),
       [Expr($base),Expr($sup)]); });
DefMathML('Apply:?:Subscript',   sub {
  my($op,$base,$sub)=@_;
  Node(((($base->getAttribute('stackscripts')||'no') eq 'yes') ? 'm:munder' : 'm:msub'),
       [Expr($base),Expr($sub)]); });
DefMathML('Apply:?:SubSuperscript',   sub { 
  my($op,$base,$sub,$sup)=@_;
  Node(((($base->getAttribute('stackscripts')||'no') eq 'yes') ? 'm:munderover' : 'm:msubsup'),
       [Expr($base),Expr($sub),Expr($sup)]); });

DefMathML('Apply:POSTFIX:?',     sub { Node('m:mrow',[Expr($_[1]),Expr($_[0])]); });

DefMathML('Apply:OVERACCENT:?', sub {
  my($accent,$base)=@_;
  Node('m:mover', [Expr($base),Expr($accent)],accent=>'true'); });
DefMathML('Apply:UNDERACCENT:?', sub {
  my($accent,$base)=@_;
  Node('m:munder', [Expr($base),Expr($accent)],accent=>'true'); });

DefMathML('Apply:?:sideset', sub {
  my($op,$presub,$presup,$postsub,$postsup,$base)=@_;
  Node('m:mmultiscripts',[Expr($base),Expr($postsub),Expr($postsup), 
			  Node('m:mprescripts'),Expr($presub),Expr($presup)]); });

DefMathML('Apply:ADDOP:?', sub { Row(InfixOrPrefix(Expr($_[0]),map(Expr($_),@_[1..$#_]))); });
DefMathML('Apply:SUBOP:?', sub { Row(InfixOrPrefix(Expr($_[0]),map(Expr($_),@_[1..$#_]))); });
DefMathML('Apply:MULOP:?', sub { Row(Infix(Expr($_[0]),map(Expr($_),@_[1..$#_]))); });
DefMathML('Apply:DIVOP:?', sub { Row(Infix(Expr($_[0]),map(Expr($_),@_[1..$#_]))); });
DefMathML('Apply:RELOP:?', sub { Row(Infix(Expr($_[0]),map(Expr($_),@_[1..$#_]))); });
DefMathML('Apply:METARELOP:?', sub { Row(Infix(Expr($_[0]),map(Expr($_),@_[1..$#_]))); });

sub isEmpty { ($_[0]->nodeName eq 'XMTok') && (($_[0]->getAttribute('name')||'') eq 'Empty'); }

#DefMathML('Apply:INTOP:?', sub {
#  my($op,$low,$high,$integrand)=@_;
#  my $content = $op->textContent;
#  if(isEmpty($low)){
#    if(isEmpty($high)){
#      Row(Op($content),Expr($integrand)); }
#    else {
#      Row(Node('m:msup',[Op($content),Expr($high)]),Expr($integrand)); }}
#  elsif(isEmpty($high)){
#      Row(Node('m:msub',[Op($content),Expr($low)]),Expr($integrand)); }
#  else {
#    Row(Node('m:msubsup',[Op($content),Expr($low),Expr($high)]),Expr($integrand)); }});

#DefMathML('Apply:BIGOP:?', sub {
#  my($op,$low,$high,$summand)=@_;
#  my $content = $op->textContent;
#  if(isEmpty($low)){
#    if(isEmpty($high)){
#      Row(Op($content),Expr($summand)); }
#    else {
#      Row(Node('m:mover',[Op($content),Expr($high)]),Expr($summand)); }}
#  elsif(isEmpty($high)){
#      Row(Node('m:munder',[Op($content),Expr($low)]),Expr($summand)); }
#  else {
#    Row(Node('m:munderover',[Op($content),Expr($low),Expr($high)]),Expr($summand)); }});

#DefMathML('Apply:LIMITOP:?', sub {
#  my($op,$limit,$arg)=@_;
#  Row(Node('m:munder',[Expr($op),Expr($limit)]),Expr($arg)); });

DefMathML('Apply:FENCED:?',sub {
  my($op,@elements)=@_;
  Row(Op($op->getAttribute('open')),
      separated_list($op->getAttribute('separators'),@elements),
      Op($op->getAttribute('close'))); });

# Various specific formatters.
DefMathML('Apply:MULOP:InvisibleTimes', sub { 
  Row(Infix(Op("\N{INVISIBLE TIMES}"),map(Expr($_),@_[1..$#_]))); });
DefMathML('Apply:?:sqrt', sub { Node('m:msqrt',[Expr($_[1])]); });
DefMathML('Apply:?:root', sub { Node('m:mroot',[Expr($_[2]),Expr($_[1])]); });

# NOTE: Need to handle displaystyle
DefMathML('Apply:?:/', sub {
  my($op,$num,$den)=@_;
  my $style = $op->getAttribute('style') || '';
  Node('m:mfrac',[Expr($num),Expr($den)],($style eq 'over' ? () : (bevelled=>'true'))); });

DefMathML('Apply:?:deriv',  sub { mml_deriv("\N{DOUBLE-STRUCK ITALIC SMALL D}",@_); });
DefMathML('Apply:?:pderiv', sub { mml_deriv("\N{PARTIAL DIFFERENTIAL}",@_); });

DefMathML('Apply:?:LimitFrom', sub {
  my($op,$arg,$dir)=@_;
  Row(Expr($arg),Expr($dir)); });

# NOTE: Need to handle displaystyle
sub mml_deriv {
  my($diffop,$op,$expr,$var,$n)=@_;
  if($n){
    Node('m:mfrac',[ Row(Node('m:msup',[Op($diffop),Expr($n)]),Expr($expr)),
		     Node('m:msup',[Row(Op($diffop),Expr($var)),Expr($n)])],
	 (($op->getAttribute('style')||'') eq 'inline' ? (bevelled=>'true') : ())); }
  else {
    Node('m:mfrac',[ Row(Op($diffop),Expr($expr)),
		     Row(Op($diffop),Expr($var))],
	 (($op->getAttribute('style')||'') eq 'inline' ? (bevelled=>'true') : ())); }}

DefMathML('Apply:?:diff', sub {  
  my($op,$x,$n)=@_;
  if($n){
    Row(Node('m:msup',[Op("\N{DOUBLE-STRUCK ITALIC SMALL D}"),Expr($n)]),Expr($x)); }
  else {
    Row(Op("\N{DOUBLE-STRUCK ITALIC SMALL D}"),Expr($x)); }});
DefMathML('Apply:?:pdiff', sub {  
  my($op,$x,$n)=@_;
  if($n){
    Row(Node('m:msup',[Op("\N{PARTIAL DIFFERENTIAL}"),Expr($n)]),Expr($x)); }
  else {
    Row(Op("\N{PARTIAL DIFFERENTIAL}"),Expr($x)); }});

DefMathML('Apply:?:Cases', sub {
  my($op,@cases)=@_;
  Row(Op('{'), Node('m:mtable',[map(Expr($_),@cases)])); });

DefMathML('Apply:?:Case',sub {
  my($op,@cells)=@_;
  Node('m:mtr',[map(Node('m:mtd',[Expr($_)]),@cells)]); });

DefMathML('Apply:?:Array', sub {
  my($op,@rows)=@_;
  Node('m:mtable',[map(Expr($_),@rows)]); });
DefMathML('Apply:?:Matrix', sub {
  my($op,@rows)=@_;
  Row(Op('('), Node('m:mtable',[map(Expr($_),@rows)]),Op(')')); });
DefMathML('Apply:?:Row',sub {
  my($op,@cells)=@_;
  Node('m:mtr',[map(Expr($_),@cells)]); });
DefMathML('Apply:?:Cell',sub {
  my($op,@content)=@_;
  Node('m:mtd',[map(Expr($_),@content)]); });

DefMathML('Apply:?:binomial', sub {
  my($op,$over,$under)=@_;
  Row(Op('('),Node('m:mtable',[Node('m:mtr',[Node('m:mtd',[Expr($over)])]),
			       Node('m:mtr',[Node('m:mtd',[Expr($under)])])]), Op(')')); });
DefMathML('Apply:?:pochhammer',sub {
  my($op,$a,$b)=@_;
  Node('m:msub',[Row(Op('('),Expr($a),Op(')')),Expr($b)]); });

DefMathML('Apply:?:stacked', sub {
  my($op,$over,$under)=@_;
  Node('m:mtable',[Node('m:mtr',[Node('m:mtd',[Expr($over)])]),
		   Node('m:mtr',[Node('m:mtd',[Expr($under)])])]); });

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
    if($denomop->getAttribute('POS') =~ /ADDOP|SUBOP/){ # Is it a sum or difference?
      my $last = pop(@denomargs);			# Check last operand in denominator.
      # this is the current contribution to the cfrac (if we match the last term)
      my $curr = Node('m:mfrac',[Expr($numer),Row(Infix(map(Expr($_),$denomop,@denomargs)),Expr($denomop))]);
      if(getTokenName($last) eq 'CenterEllipsis'){ # Denom ends w/ \cdots
	return ($curr,Expr($last));}		   # bring dots up to toplevel
      elsif($last->nodeName eq 'XMApp'){	   # Denom ends w/ application --- what kind?
	my($lastop,@lastargs)=element_nodes($last);
	if(getTokenName($lastop) eq 'cfrac'){ # Denom ends w/ cfrac, pull it to toplevel
#	  return ($curr,do_cfrac(@lastargs)); }
	  return ($curr,Expr($last)); }
	elsif((getTokenName($lastop) eq 'InvisibleTimes')  # Denom ends w/ *
	      && (scalar(@lastargs)==2) && (getTokenName($lastargs[0]) eq 'CenterEllipsis')){
	  return ($curr,Expr($lastargs[0]),Expr($lastargs[1])); }}}}
  (Node('m:mfrac',[Expr($numer),Expr($denom)])); }

DefMathML('Apply:?:cfrac', sub {
  my($op,$numer,$denom)=@_;
  Row(do_cfrac($numer,$denom)); });

# NOTE: Markup probably isn't right here....
DefMathML('Apply:?:AT', sub {
  my($op,$expr,$value)=@_;
  Row(Expr($expr),Node('m:sub',[Op('|'),Expr($value)])); });
# ================================================================================
1;
