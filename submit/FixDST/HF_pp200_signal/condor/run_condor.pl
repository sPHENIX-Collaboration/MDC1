#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Path;

my $test;
GetOptions("test"=>\$test);
if ($#ARGV < 3)
{
    print "usage: run_condor.pl <infile> <outfile> <outdir> <runnumber> <sequence> <quarkfilter>\n";
    print "options:\n";
    print "-test: testmode - no condor submission\n";
    exit(-2);
}

my $localdir=`pwd`;
chomp $localdir;
my $rundir = sprintf("%s/../rundir",$localdir);
my $executable = sprintf("%s/run_fixdst.sh",$rundir);
my $infile = $ARGV[0];
my $dstoutfile = $ARGV[1];
my $dstoutdir = $ARGV[2];
my $runnumber = $ARGV[3];
my $sequence = $ARGV[4];
my $quarkfilter = $ARGV[5];

my $suffix = sprintf("%010d-%05d",$runnumber,$sequence);
my $logdir = sprintf("%s/log",$localdir);
mkpath($logdir);
my $condorlogdir = sprintf("/tmp/FixDST/HF_pp200_signal");
mkpath($condorlogdir);
my $jobfile = sprintf("%s/condor-%s-%s.job",$logdir,$quarkfilter,$suffix);
if (-f $jobfile)
{
    print "jobfile $jobfile exists, possible overlapping names\n";
    exit(1);
}
my $condorlogfile = sprintf("%s/condor-%s-%s.log",$condorlogdir,$quarkfilter,$suffix);
if (-f $condorlogfile)
{
    unlink $condorlogfile;
}
my $errfile = sprintf("%s/condor-%s-%s.err",$logdir,$quarkfilter,$suffix);
my $outfile = sprintf("%s/condor-%s-%s.out",$logdir,$quarkfilter,$suffix);
print "job: $jobfile\n";
open(F,">$jobfile");
print F "Universe 	= vanilla\n";
print F "Executable 	= $executable\n";
print F "Arguments       = \"$infile $dstoutfile $dstoutdir\"\n";
print F "Output  	= $outfile\n";
print F "Error 		= $errfile\n";
print F "Log  		= $condorlogfile\n";
print F "Initialdir  	= $rundir\n";
print F "PeriodicHold 	= (NumJobStarts>=1 && JobStatus == 1)\n";
print F "accounting_group = group_sphenix.prod\n";
print F "request_xferslots = 2\n";
print F "request_memory = 1GB\n";
print F "Priority 	= 28\n";
print F "job_lease_duration = 3600\n";
print F "Queue 1\n";
close(F);
if (defined $test)
{
    print "would submit $jobfile\n";
}
else
{
    system("condor_submit $jobfile");
}
