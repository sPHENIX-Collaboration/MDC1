#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use Getopt::Long;

my $runnumber = 1;
my $events = 100;
my $evtsperfile = 10000;
my $nmax = $evtsperfile;
open(F,"outdir.txt");
my $outdir=<F>;
chomp  $outdir;
close(F);
mkpath($outdir);
my $test;
GetOptions("test"=>\$test);
for (my $segment=0; $segment<1000; $segment++)
{
    my $hijingdatfile = sprintf("/sphenix/sim/sim01/sphnxpro/MDC1/sHijing_HepMC/data/sHijing_0_12fm-%010d-%05d.dat",$runnumber, $segment);
    if (! -f $hijingdatfile)
    {
	print "could not locate $hijingdatfile\n";
	next;
    }
    my $sequence = $segment*100;
    for (my $n=0; $n<$nmax; $n+=$events)
    {
        
	my $outfile = sprintf("G4Hits_sHijing_0_12fm-%010d-%05d.root",$runnumber,$sequence);
	my $fulloutfile = sprintf("%s/%s",$outdir,$outfile);
	print "out: $fulloutfile\n";
	if (! -f $fulloutfile)
	{
	    my $tstflag="";
	    if (defined $test)
	    {
		$tstflag="--test";
	    }
	    system("perl run_condor.pl $events $hijingdatfile $outdir $outfile $n $runnumber $sequence $tstflag");
	    my $exit_value  = $? >> 8;
	    if ($exit_value != 0)
	    {
		print "error from run_condor.pl\n";
		exit($exit_value);
	    }
	}
	else
	{
	    print "output file already exists\n";
	}
        $sequence++;
    }
}
