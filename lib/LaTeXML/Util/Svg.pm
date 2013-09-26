package LaTeXML::Util::Svg;

use strict;
use warnings;
use MIME::Base64;
use IO::CaptureOutput qw/capture_exec/;
use Time::HiRes qw( time );
#use Data::Dumper qw(Dumper);

sub createSVG {
	my($svgSource)=$_[1];

	my @args = ("timeout",'60','MediawikiTex2Svg', $svgSource);
	#print Dumper @args;
	my $time = time();
	my($svg, $svg_log, $success, $exit_code) = capture_exec( @args );
	my $duration = time() - $time;
	$svg_log .= "\n\nSVG-time:$duration\n\n";

	@args = ("timeout",'60','MediawikiSvg2Png', $svg);

	$time = time();
	my($png, $png_log, $success_png, $exit_code_png) = capture_exec( @args );
	$duration = time() - $time;

	$png_log .= "\n\nPNG-time:$duration\n\n";
	$png = encode_base64($png);
	#print Dumper $svg_log;
	
	return ($svg, $png, $svg_log."\n\n<!--PNG-->\n\n".$png_log);
}
1;
__END__