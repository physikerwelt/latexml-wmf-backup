package LaTeXML::Util::Texvc;

use strict;
use warnings;
use MIME::Base64;
use IO::CaptureOutput qw/capture_exec/;
use Time::HiRes qw( time );
#use Data::Dumper qw(Dumper);

sub checkTex {
	my($intex) = $_[1];
	my $passed = 0;
	my $outtex;

	#Hack to avoid wrong encoded output
	$intex =~ s/\\\\/\\/g;
	#$intex =~ s/\n/\\n/g;

	my @args = ("timeout",'5','texvc', $intex);
	#print Dumper @args;
	my $start = time();
	my($stdout, $sdterr, $success, $exit_code) = capture_exec( @args );
	my $duration = time() - $start;
	#print "\nin: $intex ->$stdout \n";
	my $status = substr($stdout,0,1);
	if( $status eq '+'){
		$passed = 1;
		$stdout =~ s/.(.+)/$1/;
	} 
	return (1,$intex,"\n\nTexvc-time:$duration\n.Fix texvc input not to much encoding");
	return ($passed,$stdout, "\n\nTexvc-time:$duration\n$intex -($status)> $stdout \n");
}
1;
__END__