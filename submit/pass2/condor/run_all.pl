#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;

my $g4hitsdir = "/sphenix/sim/sim01/sphnxpro/MDC1/sHijing_HepMC/G4Hits";
my $outdir = `cat outdir.txt`;
chomp $outdir;
my $events = 0;
my $skip = 0;
my $test;
GetOptions("test"=>\$test);
open(F,"find $g4hitsdir -maxdepth 1 -type f -name 'G4Hits_sHijing*' -print | sort |");
while (my $file = <F>)
{
    chomp $file;
    my $lfn = basename($file);
       if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
        {
           my $runnumber = int($2);
	   my $segment = int($3);
	   print "file: $lfn, runnumber: $runnumber, segment: $segment\n";
	   my $outfile = sprintf("DST_sHijing_0_12fm-%010d-%05d.root",$runnumber, $segment);
	    my $tstflag="";
	    if (defined $test)
	    {
		$tstflag="--test";
	    }
	   my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %d %d %d %s",$events, $file, $outdir, $outfile, $skip, $runnumber, $segment, $tstflag);
	   print "cmd: $subcmd\n";
	   system($subcmd);
	}
}
