# /=====================================================================\ #
# |  LaTeXML:Box, LaTeXML:List...                                       | #
# | Digested objects produced in the Stomack                            | #
# |=====================================================================| #
# | Part of LaTeXML:                                                    | #
# |  Public domain software, produced as part of work done by the       | #
# |  United States Government & not subject to copyright in the US.     | #
# |---------------------------------------------------------------------| #
# | Bruce Miller <bruce.miller@nist.gov>                        #_#     | #
# | http://dlmf.nist.gov/LaTeXML/                              (o o)    | #
# \=========================================================ooo==U==ooo=/ #
package LaTeXML::Box;
use strict;
use LaTeXML::Global;
use LaTeXML::Object;
our @ISA = qw(LaTeXML::Object);

sub new {
  my($class,$string,$font,$locator)=@_;
  my $self=[$string,$font || Font(),$locator || $GULLET->getLocator];
  bless $self,$class; }

# Accessors
sub isaBox     { 1; }
sub getString  { $_[0][0]; }	# Return the string contents of the box
sub getFont    { $_[0][1]; }	# Return the font this box uses.
sub isMath     { 0; }		# Box is text mode.
sub getInitial { $_[0][0]; }	# Return the `initial', for indexing ops.
sub getLocator { $_[0][2]; }

# So a Box can stand in for a List
sub unlist     { ($_[0]); }	# Return list of the boxes

sub untex      { $_[0][0]; }
sub toString   { $_[0][0]; }

# Methods for overloaded operators
sub stringify {
  my($self)=@_;
  my $type = ref $self;
  $type =~ s/^LaTeXML:://;
  $type.'['.$$self[0].']'; }

# Should this compare fonts too?
sub equals {
  my($a,$b)=@_;
  (defined $b) && ((ref $a) eq (ref $b)) && ($$a[0] eq $$b[0]); }

sub beAbsorbed { $INTESTINE->openText($_[0][0],$_[0][1]); }

#**********************************************************************
# LaTeXML::MathBox
#**********************************************************************
package LaTeXML::MathBox;
use strict;
use LaTeXML::Global;
our @ISA = qw(LaTeXML::Box);

sub new {
  my($class,$string,$font,$locator)=@_;
  my $self=[$string,$font || MathFont(),$locator || $GULLET->getLocator];
  bless $self,$class; }

sub isMath { 1; }		# MathBoxes are math mode.

sub beAbsorbed { $INTESTINE->insertMathToken($_[0][0],font=>$_[0][1]); }

#**********************************************************************
# LaTeXML::Comment
#**********************************************************************
package LaTeXML::Comment;
use strict;
use LaTeXML::Global;
our @ISA = qw(LaTeXML::Box);

sub untex    { ''; }
sub toString { ''; }

sub beAbsorbed { $INTESTINE->insertComment($_[0][0]); }

#**********************************************************************
# LaTeXML::List
# A list of boxes or Whatsits
# (possibly evolve into HList, VList, MList)
#**********************************************************************
package LaTeXML::List;
use strict;
use LaTeXML::Global;
use LaTeXML::Object;
our @ISA = qw(LaTeXML::Box);

sub new {
  my($class,@boxes)=@_;
  bless [@boxes],$class; }

sub isMath     { 0; }			# List's are text mode
sub getFont    { (defined $_[0][0] ? $_[0][0]->getFont    : undef); }	# Return font of 1st box (?)
sub getInitial { (defined $_[0][0] ? $_[0][0]->getInitial : undef); }
sub getLocator { (defined $_[0][0] ? $_[0][0]->getLocator : ''); }

sub unlist { @{$_[0]}; }

sub untex {
  my($self)=@_;
  join('',map($_->untex,@$self)); }

sub toString {
  my($self)=@_;
  join('',map($_->toString,@$self)); }

# Methods for overloaded operators
sub stringify {
  my($self)=@_;
  my $type = ref $self;
  $type =~ s/^LaTeXML:://;
  $type.'['.join(',',map($_->toString,@$self)).']'; } # Not ideal, but....

sub equals {
  my($a,$b)=@_;
  return 0 unless (defined $b) && ((ref $a) eq (ref $b));
  my @a = @$a;
  my @b = @$b;
  while(@a && @b && ($a[0]->equals($b[0]))){
    shift(@a); shift(@b); }
  return !(@a || @b); }

sub beAbsorbed { map($INTESTINE->absorb($_), @{$_[0]}); }

#**********************************************************************
# LaTeXML::MathList
# A list of boxes or Whatsits
# (possibly evolve into HList, VList, MList)
#**********************************************************************
package LaTeXML::MathList;
use LaTeXML::Global;
our @ISA = qw(LaTeXML::List);

sub isMath { 1; }		# MathList's are math mode.

#**********************************************************************
# What about Kern, Glue, Penalty ...

#**********************************************************************
# LaTeXML Whatsit.
#  Some arbitrary object, possibly with arguments.
# Particularly as an intermediate representation for invocations of control
# sequences that do NOT get expanded or processed, but are taken to represent 
# some semantic something or other.
# These get preserved in the expanded/processed token stream to be
# converted into XML objects in the Intestines.
#**********************************************************************
package LaTeXML::Whatsit;
use strict;
use LaTeXML::Global;
use LaTeXML::Object;
our @ISA = qw(LaTeXML::Box);

# Specially recognized properties:
#  font    : The font object
#  locator : a locator string, where in the source this whatsit was created
#  isMath  : whether this is a math object
#  id
#  body
#  trailer
sub new {
  my($class,$defn,$args,%properties)=@_;
  $properties{font}    = $STOMACH->getFont   unless defined $properties{font};
  $properties{locator} = $GULLET->getLocator unless defined $properties{locator};
  $properties{isMath}  = $STOMACH->inMath    unless defined $properties{isMath};
  bless {definition=>$defn, args=>$args||[], properties=>{%properties}},$class; }

sub getDefinition { $_[0]{definition}; }
sub isMath        { $_[0]{properties}{isMath}; }
sub getFont       { $_[0]{properties}{font}; } # and if undef ????
sub setFont       { $_[0]{properties}{font} = $_[1]; }
sub getLocator    { $_[0]{properties}{locator}; }
sub getProperty   { $_[0]{properties}{$_[1]}; }
sub setProperty   { $_[0]{properties}{$_[1]}=$_[2]; return; }
sub getProperties { $_[0]{properties}; }
sub getArg        { $_[0]{args}->[$_[1]-1]; }
sub getArgs       { @{$_[0]{args}}; }
sub setArgs       { 
  my($self,@args)=@_;
  $$self{args} = [@args]; 
  return; }

sub getBody     { $_[0]{properties}{body}; }
sub setBody {
  my($self,@body)=@_;
  my $trailer = pop(@body);
  $$self{properties}{body} = ($self->isMath ? MathList(@body) : List(@body));
  $$self{properties}{trailer} = $trailer;
  return; }

sub getTrailer  { $_[0]{properties}{trailer}; }

# Return the `initial' of this object, for indexing.
sub getInitial { $_[0]->getDefinition->getCS->untex; }

# So a Whatsit can stand in for a List
sub unlist  { ($_[0]); }

sub untex {
  my($self)=@_;
  $$self{definition}->untex($self); }

sub toString { $_[0]->untex;}

# Methods for overloaded operators
sub stringify {
  my($self)=@_;
  my $string = "Whatsit[".join(',',$self->getDefinition->getCS->getCSName,
			       map(ToString($_),$self->getArgs));
  if(defined $$self{properties}{body}){
    $string .= $$self{properties}{body}->toString;
    $string .= $$self{properties}{trailer}->toString; }
  $string."]"; }

sub equals {
  my($a,$b)=@_;
  return 0 unless (defined $b) && ((ref $a) eq (ref $b));
  return 0 unless $$a{definition} eq $$b{definition}; # I think we want IDENTITY here, not ->equals
  my @a = @{$$a{args}};
  my @b = @{$$b{args}};
  while(@a && @b && ($a[0]->equals($b[0]))){
    shift(@a); shift(@b); }
  return !(@a || @b); }

sub beAbsorbed {
  my($self)=@_;
  &{$self->getDefinition->getConstructor}($self,$self->getArgs,$self->getProperties);}

#**********************************************************************
1;


__END__

=pod 

=head1 LaTeXML::Box, LaTeXML::MathBox, LaTeXML::Comment, LaTeXML::List, LaTeXML::MathList and LaTeXML::Whatsit.

=head2 DESCRIPTION

These represent various kinds of digested objects:
C<LaTeXML::Box> represents a text character in a particular font;
C<LaTeXML::MathBox> represents a math character in a particular font;
C<LaTeXML::List> represents a sequence of digested things in text;
C<LaTeXML::MathList> represents a sequence of digested things in math;
C<LaTeXML::Whatsit> represents a digested object that can generate
arbitrary elements in the XML Document.

See L<LaTeXML::Global> for convenient constructors for these objects.

=head2 Common Methods for all digested objects.

All these classes extend L<LaTeXML::Object> and so implement
the C<stringify> and C<equals> operations.

=over 4

=item C<< $font = $digested->getFont; >>

Returns the font used by C<$digested>.

=item C<< $boole = $digested->isMath; >>

Returns whether C<$digested> was created in math mode.

=item C<< $string = $digested->getInitial; >>

Returns the `initial' of C<$digested>; the initial letter
or control sequence. This is used to improve certain table lookups, 
such as finding relevant Filters.

=item C<< @boxes = $digested->unlist; >>

Returns a list of the boxes contained in C<$digested>.
It is also defined for the Boxes and Whatsit (which just
return themselves) so they can stand-in for a List.

=item C<< $string = $digested->toString; >>

Returns a string representing this C<$digested>.

=item C<< $string = $digested->untex; >>

Returns the TeX string that corresponds to this C<$digested>
in a form (hopefully) suitable for processing by TeX,
if needed.

=item C<< $string = $digested->getLocator; >>

Get a string describing the location in the original source that gave rise
to C<$digested>.

=item C<< $digested->beAbsorbed; >>

C<$digested> should get itself absorbed into the C<INTESTINE> in whatever way
is apppropriate.

=back

=head2 Methods specific of C<LaTeXML::Box> and C<LaTeXML::MathBox>

=over 4

=item C<< $string = $box->getString; >>

Returns the string part of the C<$box>.

=back

=head2 Methods specific to C<LaTeXML::Whatsit>

Note that the font is stored in the data properties under 'font'.

=over 4

=item C<< $defn = $whatsit->getDefinition; >>

Returns the L<LaTeXML::Definition> responsible for creating this C<$whatsit>.

=item C<< $value = $whatsit->getProperty($key); >>

Returns the value associated with C<$key> in the C<$whatsit>'s property list.

=item C<< $whatsit->setProperty($key,$value); >>

Sets the C<$value> associated with the C<$key> in the C<$whatsit>'s property list.

=item C<< $props = $whatsit->getProperties; >>

Returns the hash reference representing the property list of C<$whatsit>.

=item C<< $list = $whatsit->getArg($n); >>

Returns the C<$n>-th argument (starting from 1) for this C<$whatsit>.

=item C<< @args = $whatsit->getArgs; >>

Returns the list of arguments for this C<$whatsit>.

=item C<< $whatsit->setArgs(@args); >>

Sets the list of arguments for this C<$whatsit> to C<@args> (each arg should be
a C<LaTeXML::List> or C<LaTeXML::MathList>).

=item C<< $list = $whatsit->getBody; >>

Return the body for this C<$whatsit>. This is only defined for environments or
top-level math formula.  The body is stored in the properties under 'body'.

=item C<< $whatsit->setBody(@body); >>

Sets the body of the C<$whatsit> to the boxes in C<@body>.  The last C<$box> in C<@body>
is assumed to represent the `trailer', that is the result of the invocation
that closed the environment or math.  It is stored separately in the properties
under 'trailer'.

=item C<< $list = $whatsit->getTrailer; >>

Return the trailer for this C<$whatsit>. See C<setBody>.

=back

=cut
