#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use Getopt::Long;
use DBI;

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

my $hostname = `hostname`;
chomp $hostname;
if ($hostname !~ /phnxsub/)
{
    print "submit only from phnxsub01 or phnxsub02\n";
    exit(1);
}

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::error;

my $maxsubmit = $ARGV[0];
my $hijing_runnumber = 1;
my $runnumber = 2;
my $events = 100;
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
    my $hijingdatfile = sprintf("/sphenix/sim/sim01/sphnxpro/MDC1/sHijing_HepMC/data/sHijing_0_20fm-%010d-%05d.dat",$hijing_runnumber, $segment);
    if (! -f $hijingdatfile)
    {
	print "could not locate $hijingdatfile\n";
	next;
    }
    my $sequence = $segment*100;
    for (my $n=0; $n<$nmax; $n+=$events)
    {
	my $outfile = sprintf("G4Hits_sHijing_0_20fm-%010d-%05d.root",$runnumber,$sequence);
	$chkfile->execute($outfile);
	if ($chkfile->rows == 0)
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
        $sequence++;
    }
}
