#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use Getopt::Long;

my $test;
my $incremental;
GetOptions("test"=>\$test, "increment"=>\$incremental);
if ($#ARGV < 0)
{
    print "usage: run_all.pl <number of jobs> <\"Charm\" or \"Bottom\" production>\n";
    print "parameters:\n";
    print "--increment : submit jobs while processing running\n";
    print "--test : dryrun - create jobfiles\n";
    exit(1);
}


my $maxsubmit = $ARGV[0];
my $quarkfilter = $ARGV[1];
my $runnumber = 1;
my $events = 2000;
my $evtsperfile = 10000;
my $nmax = $evtsperfile;
open(F,"outdir.txt");
my $outdir=<F>;
chomp  $outdir;
close(F);
mkpath($outdir);
my $nsubmit = 0;
for (my $segment=0; $segment<1000; $segment++)
{
    my $sequence = $segment*100;
    for (my $n=0; $n<$nmax; $n+=$events)
    {
    my $upperfilter = uc $quarkfilter;
	my $outfile = sprintf("DST_HF_%s_pythia8-%010d-%05d.root",$upperfilter,$runnumber,$sequence);
	my $fulloutfile = sprintf("%s/%s",$outdir,$outfile);
	print "out: $fulloutfile\n";
	if (! -f $fulloutfile)
	{
	    my $tstflag="";
	    if (defined $test)
	    {
		$tstflag="--test";
	    }
	    system("perl run_condor.pl $events $quarkfilter $outdir $outfile $n $runnumber $sequence $tstflag");
	    my $exit_value  = $? >> 8;
	    if ($exit_value != 0)
	    {
		if (! defined $incremental)
		{
		    print "error from run_condor.pl\n";
		    exit($exit_value);
		}
	    }
	    else
	    {
		$nsubmit++;
	    }
	    if ($nsubmit >= $maxsubmit)
	    {
		print "maximum number of submissions reached, exiting\n";
		exit(0);
	    }
	}
	else
	{
	    print "output file already exists\n";
	}
        $sequence++;
    }
}
