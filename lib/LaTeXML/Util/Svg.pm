package LaTeXML::Util::Svg;

use strict;
use warnings;
use strict;
use MIME::Base64;
use IO::CaptureOutput qw/capture_exec/;
#use Data::Dumper qw(Dumper);

sub createSVG {
	my($svgSource)=$_[1];
	#Hack to avoid wrong encoded output
	$svgSource =~ s/\\/\\\\/g;
	$svgSource =~ s/\n/\\n/g;

	my @args = ("timeout",'60','MediawikiTex2Svg', $svgSource);
	#print Dumper @args;
	my($svg, $svg_log, $success, $exit_code) = capture_exec( @args );

	@args = ("timeout",'60','MediawikiSvg2Png', $svg);
	my($png, $png_log, $success_png, $exit_code_png) = capture_exec( @args );
	$png = encode_base64($png);
	
	return ($svg, $png, $svg_log.'<!--PNG-->'.$png_log);
}
1;
__END__