#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use Getopt::Long;

my $test;
my $incremental;
GetOptions("test"=>\$test, "increment"=>\$incremental);
if ($#ARGV < 1)
{
    print "usage: run_all.pl <number of jobs> <\"Charm\" or \"Bottom\" production>\n";
    print "parameters:\n";
    print "--increment : submit jobs while processing running\n";
    print "--test : dryrun - create jobfiles\n";
    exit(1);
}


my $maxsubmit = $ARGV[0];
my $quarkfilter = $ARGV[1];
if ($quarkfilter  ne "Charm" && $quarkfilter  ne "Bottom")
{
    print "second argument has to be either Charm or Bottom\n";
    exit(1);
}
my $runnumber = 1;
my $events = 2000;
open(F,"outdir.txt");
my $outdir=<F>;
chomp  $outdir;
close(F);
mkpath($outdir);
my $localdir=`pwd`;
chomp $localdir;
my $logdir = sprintf("%s/log",$localdir);
my $nsubmit = 0;
my $njob = 0;
for (my $isub = 0; $isub < $maxsubmit; $isub++)
{
    my $jobfile = sprintf("%s/condor-%s-%010d-%05d.job",$logdir,$quarkfilter,$runnumber,$njob);
    while (-f $jobfile)
    {
	$njob++;
	$jobfile = sprintf("%s/condor-%s-%010d-%05d.job",$logdir,$quarkfilter,$runnumber,$njob);
    }
    print "using jobfile $jobfile\n";
    my $upperfilter = uc $quarkfilter;
    my $outfile = sprintf("DST_HF_%s_pythia8-%010d-%05d.root",$upperfilter,$runnumber,$njob);
    my $fulloutfile = sprintf("%s/%s",$outdir,$outfile);
    print "out: $fulloutfile\n";
    if (! -f $fulloutfile)
    {
	my $tstflag="";
	if (defined $test)
	{
	    $tstflag="--test";
	}
	system("perl run_condor.pl $events $quarkfilter $outdir $outfile $runnumber $njob $tstflag");
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
	$isub--;
    }
}
