# /=====================================================================\ #
# |  LaTeXML::Post::MathParser                                          | #
# | Postprocessor to parse math                                         | #
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
package LaTeXML::Post::MathParser;
use strict;
use Parse::RecDescent;
use LaTeXML::Util::LibXML;
use LaTeXML::Post::MathDictionary;
use Exporter;
use charnames ":full";
our @ISA = qw(Exporter);
our @EXPORT_OK = (qw(&Lookup &New &Apply &recApply &Annotate &InvisibleTimes
		     &NewFormulae &NewFormula &NewCollection  &ApplyFunction
		     &LeftRec
		     &Arg &Name &Content &Problem &MaybeFunction
		     &isMatchingClose &NewFenced));
our %EXPORT_TAGS = (constructors => [qw(&Lookup &New &Apply &recApply &Annotate &InvisibleTimes
					&NewFormulae &NewFormula &NewCollection  &ApplyFunction
					&LeftRec
					&Arg &Content &Problem &MaybeFunction 
					&isMatchingClose &NewFenced)]);

# ================================================================================
sub new {
  my($class,%options)=@_;

  # Hackery to recompile the grammar.
  my ($dir) = grep( -f "$_/LaTeXML/Post/MathGrammar", @INC);
  $dir .= "/LaTeXML/Post";
  if ((!-f "$dir/MathGrammar.pm") || (-M "$dir/MathGrammar" < -M "$dir/MathGrammar.pm")){
    system("cd $dir; perl -MParse::RecDescent - MathGrammar LaTeXML::Post::MathGrammar"); }

  require LaTeXML::Post::MathGrammar;
  my $internalparser = LaTeXML::Post::MathGrammar->new();
  die("Math Parser grammar failed") unless $internalparser;

  bless {internalparser => $internalparser,
	verbosity => $options{verbosity} || 0},$class;
  }

sub process {
  my($self,$doc,%options)=@_;
  my $pathname = $options{source};
  $$self{verbosity} = $options{verbosity}||0;

  $self->clear;			# Not reentrant!
  my $dict = LaTeXML::Post::MathDictionary::getDocumentDictionary($doc,$pathname);
  my @math =  $self->find_math_nodes($doc);
  $self->Msg(1,"Parsing ".scalar(@math)." formulae");
  foreach my $math (@math){
    $self->parse($math,$dict); }
  $self->summary;
  $doc; }

sub Msg {
  my($self,$level,$msg)=@_;
  print STDERR "".(ref $self).": $msg\n" if $$self{verbosity}>=$level; }

# ================================================================================
sub clear {
  my($self)=@_;
  $$self{math_passed}=0;
  $$self{math_failed}=0;
  $$self{arg_passed}=0;
  $$self{arg_failed}=0;
  $$self{wrap_passed}=0;
  $$self{wrap_failed}=0;
  $$self{unknowns}={};
  $$self{maybe_functions}={};
}
sub summary {
  my($self)=@_;
  return unless $$self{verbosity} >= 1;
  my $ntot = $$self{math_passed}+$$self{math_failed};
  my $ntotargs = $$self{arg_passed}+$$self{arg_failed};
  my $ntotwrap = $$self{wrap_passed}+$$self{wrap_failed};
  $self->Msg(1,"Math parsing succeeded\n"
  	     ."  $$self{math_passed}/$ntot top-level expressions\n"
	     ."  $$self{arg_passed}/$ntotargs subexpressions\n"
	     ."  $$self{wrap_passed}/$ntotwrap sloppy subexpressions."
	    ) if $ntot; 
  my @unk = keys %{$$self{unknowns}};
  if(@unk){
    print STDERR "Symbols assumed as simple identifiers (with # of occurences):\n   "
      .join(', ',map("'$_' ($$self{unknowns}{$_})",sort @unk))."\n"; 
    my @funcs = keys %{$$self{maybe_functions}};
    if(@funcs){
      print STDERR "Possibly used as functions? (with # suspicious usages/# of occurrences):\n  "
	.join(', ',map("'$_' ($$self{maybe_functions}{$_}/$$self{unknowns}{$_} times)",sort @funcs))."\n"; }}
}

sub note_unknown {
  my($self,$name)=@_;
  $$self{unknowns}{$name}++ unless $LaTeXML::Post::MathParser::NO_NOTES; }

# ================================================================================
# Some more XML utilities, but math specific (?)
sub getTokenName {
  my($node)=@_;
  $node->getAttribute('name') || $node->textContent;}

sub node_TeX {
  my($node)=@_;
  $node->getAttribute('tex') || $node->textContent;}

sub node_string {
  my(@nodes)=@_;
  my $x;
  join(' ',map( (defined ($x=$_->getAttribute('tex')) ? $x
		: (defined ($x=$_->getAttribute('name')) ? $x
		   : ( (($_->nodeName eq 'XMTok')&& (defined ($x=$_->textContent))) ? $x
		       : $_->nodeName))), @nodes)); }

sub node_location {
  my($node)=@_;
  my $n = $node;
  while($n && (ref $n ne 'XML::LibXML::Document')
	&& !$n->getAttribute('refnum') && !$n->getAttribute('label')){
    $n = $n->parentNode; }
  if($n && (ref $n ne 'XML::LibXML::Document')){
    my($r,$l)=($n->getAttribute('refnum'),$n->getAttribute('label'));
    ($r && $l ? "$r ($l)" : $r || $l); }
  else {
    'Unknown'; }}

# ================================================================================
# Customizable?

sub find_math_nodes {
  my($self,$doc)=@_;
  $doc->findnodes('.//XMath'); }

# ================================================================================
sub parse {
  my($self,$xnode,$dict)=@_;
  my $nodedict = $dict->getNodeDictionary($xnode);
  # Preset part of speech on all tokens w/o one.
  foreach my $token ($xnode->findnodes('.//XMTok[not(@POS)]')){
    my $name = getTokenName($token);
    my $POS = defined $name && $dict->getPartOfSpeech($name);
    $token->setAttribute('POS',$POS) if defined $POS; }

  $self->parse_args($xnode,$nodedict);
  my $result = $self->parse_internal($xnode,$nodedict,'Anything,');
  $$self{ ($result ? 'math_passed' : 'math_failed') }++;
  if($result){
    clear_node($xnode);
    map($xnode->removeChild($_),element_nodes($xnode));
    append_nodes($xnode,$result);

    $xnode->setAttribute('text',$self->text_form($result));
#print STDERR "Math : \"".$xnode->getAttribute('tex')."\"\n=>\"".$xnode->getAttribute('text')."\"\n";
  }}

# Depth first parsing of XMArg nodes.
sub parse_args {
  my($self,$node,$dict)=@_;
  foreach my $child (element_nodes($node)){
    $self->parse_args($child,$dict);
    if($child->nodeName eq 'XMArg'){
      $self->parse_arg($child,$dict); }
    elsif($child->nodeName eq 'XMWrap'){
      $self->parse_wrap($child,$dict); }
}}

our %pos_rule = (FUNCTION=>'QFunction', RELOP=>'QOp');
sub parse_arg {
  my($self,$arg,$dict)=@_;
  my $rule = $arg->getAttribute('rule') || 'Anything';
  my $result= $self->parse_internal($arg,$dict,$rule);
  $$self{ ($result ? 'arg_passed' : 'arg_failed') }++;
  $arg->parentNode->replaceChild($result,$arg) if $result; 
 }

# Parse `wrapped' sequences: things the author has asserted mave a 
# particular part-of-speech.
# We really don't expect to get good sense here, but they typically
# need _some_ sort of parsing to rewrite with sub/superscripts, at least.
# We probably need to associate a default rule (to parse the insides)
# that depends on the part of speech that the object plays on the outside.
sub parse_wrap {
  my($self,$arg,$dict)=@_;
  my $POS  = $arg->getAttribute('POS');
  my $rule = $arg->getAttribute('rule') || 'Anything';
  local $LaTeXML::Post::MathParser::NO_NOTES=1;
  my @nodes = element_nodes($arg);
  @nodes = grep( $_->nodeName ne 'XMHint', @nodes);
  # Don't even bother if a single item.
  my $result= (scalar(@nodes)==1 ? $nodes[0] : $self->parse_internal($arg,$dict,$rule));
  $$self{ ($result ? 'wrap_passed' : 'wrap_failed') }++;
  if($result){
    $result->setAttribute('POS',$POS) if defined $POS;
    $arg->parentNode->replaceChild($result,$arg); }
 }

# ================================================================================

sub parse_internal {
  my($self,$mathnode,$dict,$rule)=@_;
  #  Remove Hints!
  my @nodes = element_nodes($mathnode);
  @nodes = grep( $_->nodeName ne 'XMHint', @nodes);

  # Extract trailing punctuation, if rule allows it.
  my ($punct, $result,$textified);
  if($rule =~ s/,$//){
    my $x = $nodes[$#nodes];
    $punct =($x && ($x->nodeName eq 'XMTok') && defined($x = getTokenName($x))
	     && ($x = $dict->getPartOfSpeech($x)) && ($x eq 'PUNCT') ? pop(@nodes) : ''); }
  if(@nodes){
    # Generate a textual token for each node; The parser operates on this encoded string.
    local $LaTeXML::Post::MathParser::LEXEMES = {};
    my $i = 0;
    $textified='';
    foreach my $node (@nodes){
      my $tag = $node->nodeName;
      my $name = getTokenName($node);
      $name = 'Unknown' unless defined $name;
      my $POS = $node->getAttribute('POS');
      if(!defined $POS){
	$POS = $dict->getPartOfSpeech($name);
	# Hack: record UNKNOWN on Wrapped tokens, so we know they're not known!
	$POS = 'UNKNOWN' if (!defined $POS) &&($tag eq 'XMTok') && $LaTeXML::Post::MathParser::NO_NOTES;
	$node->setAttribute('POS',$POS) if defined $POS; }
      $POS = ($tag eq 'XMTok' ? 'UNKNOWN' : 'ATOM') unless defined $POS;
      my $id      = $POS.":".$name.":".++$i;
      $id =~ s/\s//g;
      if($POS eq 'UNKNOWN'){
	$self->note_unknown($name);
	if($name eq 'Unknown'){
	  print STDERR "MathParser: What is this: \"".$node->toString."\"?\n"; }}
      $$LaTeXML::Post::MathParser::LEXEMES{$id} = $node;
      $textified .= ' '.$id; }
    #print STDERR "MathParse Node:\"".node_string(@nodes)."\"\n => \"$textified\"\n";
    # Finally, apply the parser to the textified sequence.
    local $LaTeXML::Post::MathParser::PARSER = $self;
    $result = $$self{internalparser}->$rule(\$textified); }
  else {
    # Probably the wrong thing to do, but ...
    $result = New('Empty'); }
  # Failure: report on what/where
  if((! defined $result) || $textified){
    $textified =~ s/^\s*//;
    my @rest=split(/ /,$textified);
    my $pos = scalar(@nodes) - scalar(@rest);
    my $parsed  = node_string(@nodes[0..$pos-1]);
    my $toparse = node_string(@nodes[$pos..$#nodes]);
    my $id = node_location($nodes[$pos] || $nodes[$pos-1] || $mathnode);
    print STDERR "MathParser failed to match rule $rule for ".$mathnode->nodeName." at pos. $pos in $id at\n"
       . ($parsed ? $parsed."\n".(' ' x (length($parsed)-2)) : '')."> ".$toparse."\n";
    undef; }
  # Success!
  else {
    $result->setAttribute('punctuation',getTokenName($punct)) if $punct;
    $result; }}

# ================================================================================
# Conversion to a less ambiguous, mostly-prefix form.

sub text_form {
  my($self,$node)=@_;
  $self->textrec($node,0); }


our %PREFIX_ALIAS=(Superscript=>'^',Subscript=>'_',InvisibleTimes=>'*');
# Put infix, along with `binding power'
our %IS_INFIX = (METARELOP=>1, 
		 RELOP=>2, ARROW=>2,LARROW=>2,RARROW=>2,
		 ADDOP=>10,  SUBOP=>11,
		 MULOP=>100, DIVOP=>101,
		 POWEROP=>1000,
		 SUPERSCRIPT=>1000, SUBSCRIPT=>1000);
sub textrec {
  my($self,$node, $outer_bp)=@_;
  my $tag = $node->nodeName;
  if($tag eq 'XMApp') {
    my($op,@args) = element_nodes($node);
    my $name = (($op->nodeName eq 'XMTok') && getTokenName($op)) || 'unknown';
    my $POS  =  $op->getAttribute('POS') || 'Unknown';
    my ($bp,$string);
    if($bp = $IS_INFIX{$POS}){
      # Format as infix.
      $string = (scalar(@args) == 1 # unless a single arg; then prefix.
		  ? $self->textrec($op) .' '.$self->textrec($args[0],$bp)
		  : join(' '. $self->textrec($op) .' ',map($self->textrec($_,$bp), @args))); }
    elsif($POS eq 'POSTFIX'){
      $bp = 10000;
      $string = $self->textrec($args[0],$bp).$self->textrec($op); }
    elsif($name eq 'MultiRelation'){
      $bp = 2;
      $string = join(' ',map($self->textrec($_,$bp),@args)); }
    elsif($name eq 'Fenced'){
#      $bp = 0;
#      $string = " (" . join(', ',map($self->textrec($_),@args)) .") "; }
      $bp = -1;			# to force parentheses
      $string = join(', ',map($self->textrec($_),@args)); }
    else {
      $bp = 500;
      $string = $self->textrec($op,10000) .'@(' . join(', ',map($self->textrec($_),@args)). ')'; }
    ($bp < ($outer_bp||0) ? ' ('.$string.') ' : $string); }
  elsif($tag eq 'XMDual'){
    my($content,$presentation)=element_nodes($node);
    $self->textrec($content,$outer_bp); } # Just send out the semantic form.
  elsif($tag eq 'XMTok'){
    my $name = getTokenName($node);
    return 'Unknown' unless defined $name;
    $PREFIX_ALIAS{$name} || $name; }
  elsif($tag eq 'XMWrap'){
    # ??
    join('@',map($self->textrec($_), element_nodes($node))); }
  else {
    my $string = ($tag eq 'text' ? $node->textContent :     $node->getAttribute('tex') || '?');
      "[$string]"; }}

# ================================================================================
# Constructors for grammar
# All the tree construction in the grammar should come through these operations.
# We have to be _extremely_ careful about cloning nodes when using addXML::LibXML!!!
# If we add one node to another, it is _silently_ removed from any parent it may have had!
# ================================================================================

# ================================================================================
# Low-level accessors
sub Lookup {
  my($id)=@_;
  $$LaTeXML::Post::MathParser::LEXEMES{$id}; }

# Make a new Token node with given name, content, and attributes.
sub New {
  my($name,$content,%attribs)=@_;
  Annotate(new_node('XMTok',$content),name=>$name,%attribs); }

# Get n-th arg of an XMApp.
sub Arg {
  my($node,$n)=@_;
  my @args = element_nodes($node);
  $args[$n]; }			# will get cloned if/when needed.

sub Name { getTokenName($_[0]); }
sub Content { $_[0]->textContent; }

# Add more attributes to a node.
sub Annotate {
  my($node,%attribs)=@_;
  foreach my $attr (sort keys %attribs){
    my $value = $attribs{$attr};
    $value = getTokenName($value) if ref $value;
    $node->setAttribute($attr,$value) if defined $value; }
  $node; }

# ================================================================================
# Mid-level constructors
sub Apply {
  my($op,@args)=@_;
  new_node('XMApp', [$op,@args]); }

sub recApply {
  my(@ops)=@_;
  (scalar(@ops)>1 ? Apply(shift(@ops),recApply(@ops)) : $ops[0]); }

# Given  alternating expressions & separators (punctuation,...)
# extract the separators as a concatenated string,
# returning (separators, args...)
sub extract_separators {
  my(@stuff)=@_;
  my ($punct,@args);
  if(@stuff){
    push(@args,shift(@stuff));
    while(@stuff){
      $punct .= Content(shift(@stuff));
      push(@args,shift(@stuff)); }}
  ($punct,@args); }

# ================================================================================
# Some special cases 

sub InvisibleTimes {
  New('InvisibleTimes',undef,POS=>'MULOP'); }

sub ApplyFunction {
  my($op,@stuff)=@_;
  my $left=Content(shift(@stuff));
  my $right=Content(pop(@stuff));
  my ($seps,@args)=extract_separators(@stuff);
  Apply(Annotate($op,open=>$left, close=>$right, separators=>$seps),@args);}

# OK, what about \left. or \right. !!?!?!!?!?!?
# Make customizable?
# Should I just check left@right against enclose1 ?
our %balanced = ( '(' => ')', '['=>']', '{'=>'}', 
		  '|'=>'|', 'Parallel'=>'Parallel',
		  'LeftFloor'=>'RightFloor','LeftCeiling'=>'RightCeiling','LeftAngle'=>'RightAngle');
our %enclose1 = ( '(@)'=>'Fenced', '[@]'=>'Fenced', '{@}'=>'Set',
		  '|@|'=>'Abs', '||@||'=>'Abs', 'Parallel@Parallel'=>'Abs',
		  'LeftFloor@RightFloor'=>'Floor', 'LeftCeiling@RightCeiling'=>'Ceiling' );
our %enclose2 = ( '(@)'=>'OpenInterval', '[@]'=>'ClosedInterval',
		  '(@]'=>'OpenLeftInterval', '[@)'=>'OpenRightInterval',
		  '{@}'=>'Set',
		  # Nah, too weird.
		  #'{@}'=>'SchwarzianDerivative',
		  #'LeftAngle@RightAngle'=>'Distribution' 
		);
our %encloseN = ( '(@)'=>'Vector','{@}'=>'Set',);

sub isMatchingClose {
  my($open,$close)=@_;
  my $oname = Name($open);
  my $cname = Name($close);
  return 1 if $oname eq '.';
  my $expect = $balanced{$oname};
  warn "Unknown OPEN delimiter \"".Name($open)."\"" unless defined $expect;
  ($expect eq $cname) || ($cname eq '.'); }

# Convert Fenced things like open expr (punct expr)* close
# into the appropriate thing, depending on the specific open & close used.
sub NewFenced {
  my($open,@stuff)=@_;
  my $close= pop(@stuff);
  my $key = Name($open).'@'.Name($close);
  my $n = int(scalar(@stuff)+1)/2;
  my $op = (($n==1) && $enclose1{$key}) || (($n==2) && $enclose2{$key}) || (($n > 2) && $encloseN{$key})
    || 'Collection';
  my ($seps,@elements)=extract_separators(@stuff);
  Apply(New($op,undef,open=>$open->textContent, close=>$close->textContent,separators=>$seps,POS=>'FENCED'),
	@elements); }

# NOTE: It might be best to separate the multiple Formulae into separate XMath's???
# but only at the top level!
sub NewFormulae {
  my(@stuff)=@_;
  if(scalar(@stuff)==1){ $stuff[0]; }
  else { 
    my ($seps,@formula)=extract_separators(@stuff);
    Apply(New('Formulae',undef, separators=>$seps),@formula);}}

# A Formula is an alternation of expr (relationalop expr)*
# It presumably would be equivalent to (expr1 relop1 expr2) AND (expr2 relop2 expr3) ...
# But, I haven't figured out the ideal prefix form that can easily be converted to presentation.
sub NewFormula {
  my(@args)=@_;
  my $n = scalar(@args);
  if   ($n == 1){ $args[0];}
  elsif($n == 3){ Apply($args[1],$args[0],$args[2]); }
  else          { Apply(New('MultiRelation'),@args); }}

sub NewCollection {
  my(@stuff)=@_;
  if(@stuff == 1){ $stuff[0]; }
  else {
    my ($seps,@items)=extract_separators(@stuff);
    Apply(New('Collection',undef, separators=>$seps, POS=>'FENCED'),@items);}}

# Given alternation of expr (addop expr)*, compose the tree (left recursive),
# flattenning portions that have the same operator
# ie. a + b + c - c  =>  (- (+ a b c) d)
sub LeftRec {
  my($arg1,@more)=@_;
  if(@more){
    my $op = shift(@more);
    my $opname = Name($op);
    my @args = ($arg1,shift(@more));
    while(@more && ($opname eq Name($more[0]))){
      shift(@more);
      push(@args,shift(@more)); }
    LeftRec(Apply($op,@args),@more); }
  else {
    $arg1; }}

# ================================================================================
sub Problem { warn("MATH Problem? ",@_); }

# Note that an UNKNOWN token may have been used as a function.
# For simplicity in the grammar, we accept a token that has sub|super scripts applied.
sub MaybeFunction {
  my($token)=@_;
  my $self = $LaTeXML::Post::MathParser::PARSER;
  while($token->nodeName eq 'XMApp'){
    $token = Arg($token,1); }
  my $name = Name($token);
  $token->setAttribute('possibleFunction','yes');
  $$self{maybe_functions}{$name}++ 
    unless $LaTeXML::Post::MathParser::NO_NOTES or   $$self{suspicious_tokens}{$token};
  $$self{suspicious_tokens}{$token}=1; }

# ================================================================================
1;
