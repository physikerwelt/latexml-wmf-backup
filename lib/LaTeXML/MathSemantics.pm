package LaTeXML::MathSemantics;
use Data::Dumper;
# Startup actions: import the constructors
{ BEGIN{ use LaTeXML::MathParser qw(:constructors); 
#### $::RD_TRACE=1;
}}

sub first_arg {
  return $_[1] if ref $_[1];
  my ($lex,$id) = split(/:/,$_[1]);
  Lookup($id)||$lex;
}

sub infix_apply {
  my ( undef, $t1, $c, $op, $c2, $t2 , $lhs , $rhs) = @_;
  ApplyNary($op,$t1,$t2);
}

sub concat_apply {
 my ( undef, $t1, $c, $t2 , $lhs , $rhs) = @_;
  ApplyNary(New('Concatenation'),$t1,$t2);
}

sub set {
  my ( undef, undef, undef, $t, undef, undef, undef, $f ) = @_;
  Apply(New('Set'),$t,$f);
}

sub fenced {
  my (undef, $open, undef, $t, undef, $close) = @_;
  $open=~/^([^:]+)\:/; $open=$1;
  $close=~/^([^:]+)\:/; $close=$1;
  Fence($open,$t,$close);
}

sub fenced_empty {
  # TODO: Semantically figure out list/function/set context,
  # and place the correct OpenMath symbol instead!
 my (undef, $open, $c, $close) = @_;
 $open=~/^([^:]+)\:/; $open=$1;
 $close=~/^([^:]+)\:/; $close=$1;
 Fence($open,New('Empty'),$close);
}

1;
