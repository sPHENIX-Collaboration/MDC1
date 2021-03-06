#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;


my $outevents = 0;
my $test;
my $incremental;
GetOptions("test"=>\$test, "increment"=>\$incremental);
if ($#ARGV < 0)
{
    print "usage: run_all.pl <number of jobs>\n";
    print "parameters:\n";
    print "--increment : submit jobs while processing running\n";
    print "--test : dryrun - create jobfiles\n";
    exit(1);
}

my $maxsubmit = $ARGV[0];
if (! -f "outdir.txt")
{
    print "could not find outdir.txt\n";
    exit(1);
}
my $outdir = `cat outdir.txt`;
chomp $outdir;
mkpath($outdir);

my $indirfile = sprintf("../../pass4trk/condor/outdir.txt");
if (! -f $indirfile)
{
    print "could not find file with input directory $indirfile\n";
    exit(1);
}
my $indir = `cat $indirfile`;
chomp $indir;

my $caloindirfile = sprintf("../../pass3calo/condor/outdir.txt");
if (! -f $caloindirfile)
{
    print "could not find file with input directory $caloindirfile\n";
    exit(1);
}
my $caloindir = `cat $caloindirfile`;
chomp $caloindir;

my $nsubmit = 0;
open(F,"find $indir -maxdepth 1 -type f -name 'DST_TRACKS*.root' | sort |");
while (my $file = <F>)
{
    chomp  $file;
    my $lfn = basename($file);
    my $clusterfile = sprintf("%s/%s",$caloindir,$lfn);
    $clusterfile =~ s/DST_TRACKS/DST_CALO_CLUSTER/;
    if (! -f $clusterfile)
    {
	print "did not find $clusterfile\n";
	next;
    }
    print "found $clusterfile\n";
    print "found $file\n";
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
	my $runnumber = int($2);
	my $segment = int($3);
	my $outfilename = sprintf("DST_JETS_sHijing_0_12fm-%010d-%05d.root",$runnumber,$segment);

	my $tstflag="";
	if (defined $test)
	{
	    $tstflag="--test";
	}
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %d %d %s", $outevents, $file, $clusterfile, $outfilename, $outdir, $runnumber, $segment, $tstflag);
	print "cmd: $subcmd\n";
	system($subcmd);
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
}
close(F);
