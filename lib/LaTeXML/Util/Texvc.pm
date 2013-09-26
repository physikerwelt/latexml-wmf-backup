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
	#$intex =~ s/\\/\\\\/g;
	#$intex =~ s/\n/\\n/g;

	my @args = ("timeout",'5','texvc', $intex);
	#print Dumper @args;
	my $start = time();
	my($stdout, $sdterr, $success, $exit_code) = capture_exec( @args );
	my $duration = time() - $start;
	#print "\nin: $intex ->$stdout \n";
	if(substr($stdout,0,1) eq '+'){
		$passed = 1;
		$outtex = substr($stdout,1,-1);
	} else {
		$outtex = $stdout;
	}
	return ($passed,$outtex, "\n\nTexvc-time:$duration\n\n");
}
1;
__END__