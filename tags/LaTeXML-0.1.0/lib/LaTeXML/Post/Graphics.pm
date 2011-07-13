# /=====================================================================\ #
# |  LaTeXML::Post::Graphics                                            | #
# | Graphics postprocessing for LaTeXML                                 | #
# |=====================================================================| #
# | Part of LaTeXML:                                                    | #
# |  Public domain software, produced as part of work done by the       | #
# |  United States Government & not subject to copyright in the US.     | #
# |---------------------------------------------------------------------| #
# | Bruce Miller <bruce.miller@nist.gov>                        #_#     | #
# | http://dlmf.nist.gov/LaTeXML/                              (o o)    | #
# \=========================================================ooo==U==ooo=/ #
#======================================================================
# Adapted from graphics-support.perl of LaTeX2HTML (which I had rewritten)
#======================================================================
package LaTeXML::Post::Graphics;
use strict;
use DB_File;
use XML::LibXML;
use LaTeXML::Util::Pathname;
use Image::Magick;
use POSIX;

#======================================================================
# Options:
#   dpi : dots per inch for target medium.
#   ignore_options  : list of graphicx options to be ignored.
#   warn_options    : list of graphicx options to cause warning if used.
#   trivial_scaling : If true, web images that only need scaling will be used as-is
#                     assuming the user agent scale the image.
#   background      : background color when filling or transparency.
#   type_map        : hash of types=>hash.
#        The hash for each type can have the following 
#           type   : the type to convert the file to.
#           transparent : if true, the background color will be made transparent.
#           quality     : the `quality' used for the image.
#           ncolors     : the image will be quantized to ncolors.
sub new {
  my($class,%options)=@_;
  bless {dppt               => (($options{dpi}||100)/72.0), # Dots per point.
	 ignore_options     => $options{ignore_options}   || [],
	 trivial_scaling    => $options{trivial_scaling}  || 1,
	 source_types       => $options{source_types}     || [qw(png gif jpg jpeg eps ps)],
	 type_map           => $options{type_map} || { ps  =>{type=>'png', transparent=>1},
						       eps =>{type=>'png', transparent=>1},
						       jpg =>{type=>'jpg'},
						       jpeg=>{type=>'jpeg'},
						       gif =>{type=>'gif', transparent=>1},
						       png =>{type=>'png', transparent=>1}},
	 background         => $options{background}       || "#FFFFFF",
	 verbosity            => $options{verbosity}||0,
	},$class; }

sub process {
  my($self,$doc,%options)=@_;
  $self=$self->new() unless ref $self; # Allow non-OO call; we'll create our own $self!!
  $$self{sourceDirectory} = $options{sourceDirectory} || '.';
  $$self{destinationDirectory} = $options{destinationDirectory} || '.';
  $$self{search_paths} = [$$self{sourceDirectory}];
  $$self{verbosity} = $options{verbosity}||0;

  $self->find_graphicspaths($doc);
  $self->Msg(2,"Using graphicspaths: ".join(', ',@{$$self{search_paths}}));

  my @nodes = $self->select_graphics_nodes($doc);
  $self->Msg(1,scalar(@nodes)." graphics nodes to process");
  foreach my $node (@nodes){
    $self->process_graphic($node); }
  $doc; }

#======================================================================
sub ignore_scaling  { push(@{$_[0]->{ignore_options}}, qw(width height totalheight scale)); }
sub ignore_rotation { push(@{$_[0]->{ignore_options}}, qw(angle)); }
sub ignore_clipping { push(@{$_[0]->{ignore_options}}, qw(trim clip)); }

#======================================================================
# Potentially customizable operations.
# find graphics file
#  Need to deal with source directory, as well as graphicspath.

# Extract any graphicspath PI's from the document and return a reference 
# to a list of search paths.
sub find_graphicspaths {
  my($self,$doc)=@_;
  foreach my $pi ($doc->findnodes('.//processing-instruction("latexml")')){
    if($pi->textContent =~ /^\s*graphicspath\s*=\s*([\"\'])(.*?)\1\s*$/){
      my $value=$2;
      while($value=~ s/^\s*\{(.*?)\}//){
	$self->add_searchpath($1); }}}}

# Return a list of ZML nodes which have graphics that need processing.
sub select_graphics_nodes {
  my($self,$doc)=@_;
  $doc->findnodes('.//graphics'); }

# Return the `name' of the graphics file for this node.
# (not necessarily a complete pathname)
sub get_name {
  my($self,$node)=@_;
   $node->getAttribute('graphic'); }

# Return a list of file types that would be acceptable for this node.
sub get_types {
  my($self,$node)=@_;
  $$self{source_types}; }

# Return the options for this node.
sub get_options {
  my($self,$node)=@_;
  $node->getAttribute('options'); }

# Return the parsed options (a transform) for this node.
sub get_transform {
  my($self,$node,$options)=@_;
  ($options ? $self->parse_options($options) : []); }

# Get a hash of the image processing properties to be applied to this image.
sub get_type_map {
  my($self,$source,$options)=@_;
  my($dir,$name,$type)=pathname_split($source);
  $$self{type_map}{$type}; }

# Set the attributes of the graphics node to record the image file name,
# width and height.
sub set_graphics_src {
  my($self,$node,$src,$width,$height)=@_;
  $node->setAttribute('src',$src);
  $node->setAttribute('width',$width);
  $node->setAttribute('height',$height);
}

sub postprocess_image {
  my($self,$image,$map)=@_;
  $image->Quantize(colors=>$$map{ncolors}) if $$map{ncolors}; # Or a factor*original colors?
  $image->Transparent($$self{background}) if $$map{transparent};
  $image->Set('quality',$$map{quality}) if $$map{quality};
  $image; }

sub Error {
  my($self,$msg)=@_;
  die "".(ref $self)." Error: $msg"; }

sub Msg {
  my($self,$level,$msg)=@_;
  print STDERR "".(ref $self).": $msg\n" if $$self{verbosity}>$level; }

#======================================================================
sub to_absolute {
  my($self,$path)=@_;
  (pathname_is_absolute($path) ? $path : pathname_absolute($path,$$self{sourceDirectory})); }

sub add_searchpath {
  my($self,$path)=@_;
  push(@{$$self{search_paths}},$self->to_absolute($path)); }

sub find_file {
  my($self,$name,$types)=@_;
  pathname_find($name,paths=>$$self{search_paths},types=>$types); }

# Given a source pathname, presumably relative to the source document's directory,
# create a corresponding sub-directory in the destination directory.
# Return a pair: (absolute dest dir,  relative dest dir)
sub make_relative_subdirectory {
  my($self,$source)=@_;
  my ($reldir,$name,$type) = pathname_split(pathname_relative($source,$$self{sourceDirectory}));
  my $destdirrel = pathname_concat($$self{destinationDirectory},$reldir);
  pathname_mkdir($destdirrel) 
    or return $self->Error("Could not create relative directory $destdirrel: $!");
  ($destdirrel,$reldir); }

#======================================================================

sub process_graphic {
  my($self,$node)=@_;
  # Collect all required information.
  my $gname      = $self->get_name($node);
  return warn "No graphic name for ".$node->toString unless $gname;
  my $source    = $self->find_file($gname,$self->get_types($node));
  return warn "Couldn't find graphic source for $gname " unless $source;
  my $transform = $self->get_transform($node,$self->get_options($node));
  my $map       = $self->get_type_map($source,$transform);
  return warn "Don't know what to do with graphics file format $source" unless $map;

  my($ignore,$name,$type) = pathname_split($source);
  my($destdir,$reldir) = $self->make_relative_subdirectory($source);

  my %DB=();
  my $dbfile = pathname_make(dir=>$destdir, name=>'LTXGraphics', type=>'db');
#  tie %DB, 'DB_File', [$dbfile,  O_RDWR|O_CREAT, 0666, $DB_HASH]
  tie %DB, 'DB_File', $dbfile,  O_RDWR|O_CREAT
    or return $self->Error("Couldn't attach DB $dbfile for $name: $!");
  $DB{_max_image_}=0 unless $DB{_max_image_};

  my $key = join('|',"$name.$type",map(join(',',grep($_,@$_)),@$transform));
  $self->Msg(2,"Processing $key");
  my($newname,$newtype,$width,$height) = ($name,$$map{type} || $type, 0,0);
  if(my $prev = $DB{$key}){	# Image was processed on previous run?
    $prev =~ /^(.*?)\.(\w+)\|(\d+)\|(\d+)$/;
    ($newname,$newtype,$width,$height)=($1,$2,$3,$4); 
    $self->Msg(2,">> Reuse $newname.$newtype $width x $height"); }
  # Trivial scaling case: Use original image with different width & height.
  elsif($$self{trivial_scaling} && ($newtype eq $type) && !grep(!($_->[0]=~/^scale/),@$transform)){
    ($width,$height)=$self->trivial_scaling($source,$transform);
    $self->Msg(2,">> Trivial scaling: Copy $source to $destdir");
    pathname_copy($source, pathname_make(dir=>$destdir,name=>$name,type=>$type))
      or warn("Couldn't copy image $source to $destdir: $!");
    $DB{$key}="$newname.$newtype|$width|$height"; }
  else {
    my $image;
    ($image,$width,$height) =$self->complex_transform($source,$transform);
    $image = $self->postprocess_image($image,$map);
    $newname = "$name-GEN". ++$DB{_max_image_};
    my $dest = pathname_make(dir=>$destdir,name=>$newname,type=>$newtype);
    $self->Msg(2,">> Transform to $dest $width x $height");
    $image->Write(filename=>$dest) and warn "Couldn't write image $dest: $!";
    $DB{$key}="$newname.$newtype|$width|$height"; }

  $self->set_graphics_src($node,pathname_make(dir=>$reldir,name=>$newname,type=>$newtype),$width,$height);
}

#======================================================================
# Compute the desired image size (width,height)
sub trivial_scaling {
  my($self,$source,$transform)=@_;

  my $image = Image::Magick->new(); 
  if(!$image->Read($source)){}	# ????
  my($w,$h) = $image->Get('width','height');

  foreach my $trans (@$transform){
    my($op,$a1,$a2,$a3,$a4)=@$trans;
    if($op eq 'scale'){		# $a1 => scale
      ($w,$h)=(ceil($w*$a1),ceil($h*$a1)); }
    elsif($op eq 'scale-to'){	# $a1 => width, $a2 => height, $a3 => preserve aspect ratio.
      if($a3){ # If keeping aspect ratio, ignore the most extreme request
	if($a1/$w < $a2/$h) { $a2 = $h*$a1/$w; }
	else                { $a1 = $w*$a2/$h; }}
      ($w,$h)=(ceil($a1*$$self{dppt}),ceil($a2*$$self{dppt})); }}
  return ($w,$h); }

# Transform the image, returning (image,width,height);
sub complex_transform {
  my($self,$source,$transform)=@_;
  my $image = Image::Magick->new(); 
  $image->Set(antialias=>1);
  if(!$image->Read($source)){
# ?????? Seems to have read it???
#    warn("Failed to read image $source"); 
#    return; 
}
  my ($w,$h) = $image->Get('width','height');
  my @transform = @$transform;
  # But for postscript, we want to do as much scaling as possible BEFORE loading.
  if($source =~ /\.e?ps$/){
    my($w0,$h0)=($w,$h);
    $w *=$$self{dppt}; $h *=$$self{dppt};		# Force to desired dpi ??
    while(@transform && ($transform[0]->[0] =~ /^scale/)){
      my($op,$a1,$a2,$a3,$a4)=@{shift(@transform)};
      if($op eq 'scale'){	# $a1 => scale
	($w,$h)=(ceil($w*$a1),ceil($h*$a1)); }
      elsif($op eq 'scale-to'){ 
	# $a1 => width, $a2 => height, $a3 => preserve aspect ratio.
	if($a3){ # If keeping aspect ratio, ignore the most extreme request
	  if($a1/$w < $a2/$h) { $a2 = $h*$a1/$w; }
	  else                { $a1 = $w*$a2/$h; }}
	($w,$h)=(ceil($a1*$$self{dppt}),ceil($a2*$$self{dppt})); }}
    if(($w != $w0) || ($h != $h0)){
      my($xr,$yr)=($image->Get('x-resolution')||72,$image->Get('y-resolution')||72);
      $image = Image::Magick->new(); 
      $image->Set(antialias=>1);
      $image->Set(density=>int($w*$xr/$w0).'x'.int($h*$yr/$h0)); 
      $image->Read($source); }}	# RELOAD!!!

  foreach my $trans (@transform){
    my($op,$a1,$a2,$a3,$a4)=@$trans;
    if($op eq 'scale'){		# $a1 => scale
      ($w,$h)=(ceil($w*$a1),ceil($h*$a1));
      $image->Scale(width=>$w,height=>$h); }
    elsif($op eq 'scale-to'){ 
      # $a1 => width, $a2 => height, $a3 => preserve aspect ratio.
      if($a3){ # If keeping aspect ratio, ignore the most extreme request
	if($a1/$w < $a2/$h) { $a2 = $h*$a1/$w; }
	else                { $a1 = $w*$a2/$h; }}
      ($w,$h)=(ceil($a1*$$self{dppt}),ceil($a2*$$self{dppt}));
      $image->Scale(width=>$w,height=>$h); }
    elsif($op eq 'rotate'){
      $image->Rotate(degrees=>-$a1,color=>$$self{background});
      ($w,$h) = $image->Get('width','height'); }
    # In the following two, note that TeX's coordinates are relative to lower left corner,
    # but ImageMagick's coordinates are relative to upper left.
    elsif(($op eq 'trim') || ($op eq 'clip')){
      my($x0,$y0,$ww,$hh);
      if($op eq 'trim'){ # Amount to trim: a1=left, a2=bottom, a3=right, a4=top
	($x0,$y0,$ww,$hh)=( floor($a1*$$self{dppt}),             floor($a4*$$self{dppt}),
			    ceil($w - ($a1 + $a3)*$$self{dppt}), ceil($h - ($a4 + $a2)*$$self{dppt})); }
      else {			# BBox: a1=left, a2=bottom, a3=right, a4=top
	($x0,$y0,$ww,$hh)=( floor($a1*$$self{dppt}),        floor($h - $a4*$$self{dppt}),
			    ceil(($a3 - $a1)*$$self{dppt}), ceil(($a4 - $a2)*$$self{dppt})); }
      if(($x0 > 0) || ($y0 > 0) || ($x0+$ww < $w) || ($y0+$hh < $h)){
	my $x0p=max($x0,0); $x0 = min($x0,0);
	my $y0p=max($y0,0); $y0 = min($y0,0);
	$image->Crop(x=>$x0p, width =>min($ww,$w-$x0p),
		     y=>$y0p, height=>min($hh,$h-$y0p));
	$w = min($ww+$x0, $w-$x0p);
	$h = min($hh+$y0, $h-$y0p); }
      if(($x0 < 0) || ($y0 < 0) || ($ww > $w) || ($hh > $h)){
	# No direct `padding' operation in ImageMagick
	my $nimage = Image::Magick->new();
	$nimage->Set('size',"$ww x $hh");
	$nimage->Read("xc:$$self{background}");
	$nimage->Composite(image=>$image, compose=>'over', x=>-$x0, y=>-$y0);
	$image=$nimage; 
	($w,$h)=($ww,$hh);
      }
  }}
  ($image,$w,$h); }

sub min { ($_[0] < $_[1] ? $_[0] : $_[1]); }
sub max { ($_[0] > $_[1] ? $_[0] : $_[1]); }

#**********************************************************************
# Note that viewport is supposed to be relative to bounding box,
# and EITHER ONE can cause clipping, if clip=true.
# However, apparently the INTENT of bounding box is simply to 
# supply one, if one can't be found, in order to determine the image size.
# In our case, we may end up getting a gif, jpeg, etc, whose origin is always 0,0,
# and whose size is clear; also postscript figures sizes will be determined
# by ghostview(?).  Another use of setting a bounding box, when clip=false,
# is to make the image lay ontop of neighboring text.  This isn't quite
# possible in HTML, other than possibly through some tricky CSS.
# Besides, I'd like to avoid reading the bb file, if I can.
# --- So, for all these reasons, we simply ignore bounding box here.

sub parse_options {
  my($self,$options)=@_;
  local $_;
  # --------------------------------------------------
  # Parse options
  my ($v,$clip,$trim,$width,$height,$scale,$aspect,$a,$rotfirst,@bb,@vp,)
    =('', '',   '',   0,    0,   0,    '',      0, '',        0);
  my @unknown=();
  foreach (split(',',$options||'')){
    /^\s*(\w+)(=\s*(.*))?\s*$/;  $_=$1; $v=$3||'';
    my $op = $_;
    if(grep($op eq $_, @{$$self{ignore_options}})){  } # Ignore this option
    elsif(/^bb$/)               { @bb = map(to_bp($_),split(' ',$v)); }
    elsif(/^bb(ll|ur)(x|y)$/)   { $bb[2*/ur/ + /y/] = to_bp($v); }
    elsif(/^nat(width|height)$/){ $bb[2 + /width/] = to_bp($v); }
    elsif(/^viewport$/)         { @vp = map(to_bp($_),split(' ',$v)); $trim=0;}
    elsif(/^trim$/)             { @vp = map(to_bp($_),split(' ',$v)); $trim=1;}
    elsif(/^clip$/)             { $clip = !($v eq 'false'); }
    elsif(/^keepaspectratio$/)  { $aspect = !($v eq 'false'); }
    elsif(/^width$/)            { $width = to_bp($v); }
    elsif(/^(total)?height$/)   { $height = to_bp($v); }
    elsif(/^scale$/)            { $scale = $v; }
    elsif(/^angle$/)            { $a = $v; $rotfirst = !($width||$height||$scale); }
    elsif(/^origin$/)           { } # ??
    else { push(@unknown,[$op,$v]); }}
  # --------------------------------------------------
  # Now, compile the options into a sequence of `transformations'.
  # Note: the order of rotation & scaling is significant,
  # but the order of various clipping options w.r.t rotation or scaling is not.
  my @transform=();
  # We ignore viewport & trim if clip isn't set, since in that case we shouldn't 
  # actually remove anything from the image (and there's no way to have the image
  # overlap neighboring text, etc, in current HTML).
  push(@transform, [($trim ? 'trim' : 'clip'), @vp]) if(@vp && $clip);
  push(@transform,['rotate',$a]) if($rotfirst && $a); # Rotate before scaling?
  if($width && $height){ push(@transform,['scale-to',$width,$height,$aspect]); }
  elsif($width)        { push(@transform,['scale-to',$width,999999,1]); }
  elsif($height)       { push(@transform,['scale-to',999999,$height,1]); }
  elsif($scale)        { push(@transform,['scale',$scale]); }
  push(@transform,['rotate',$a]) if(!$rotfirst && $a);  # Rotate after scaling?
  #  ----------------------
  [@transform,@unknown]; }

our %BP_conversions=(pt=>72/72.27, pc=>12/72.27, in=>72, bp=>1,
		     cm=>72/2.54, mm=>72/25.4, dd=>(72/72.27)*(1238/1157),
		     cc=>12*(72/72.27)*(1238/1157),sp=>72/72.27/65536);
sub to_bp { 
  my($x)=@_;
  $x =~ /^\s*([+-]?[\d\.]+)(\w*)\s*$/;
  my($v,$u)=($1,$2);
  $v*($u ? $BP_conversions{$u} : 1); }


#======================================================================
1;