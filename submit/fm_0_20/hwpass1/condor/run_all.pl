#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;


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

my $hostname = `hostname`;
chomp $hostname;
if ($hostname !~ /phnxsub/)
{
    print "submit only from phnxsub01 or phnxsub02\n";
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

my $localdir=`pwd`;
chomp $localdir;
my $logdir = sprintf("%s/log",$localdir);
mkpath($logdir);

my $dsttype = "DSTNEW_TRKR_CLUSTER";
my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = '$dsttype' and filename like '%sHijing_0_20fm_50kHz_bkg_0_20fm%' order by filename") || die $DBI::error;
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::error;

my $nsubmit = 0;
$getfiles->execute() || die $DBI::error;
while (my @res = $getfiles->fetchrow_array())
{
    my $lfn = $res[0];
    print "found $lfn\n";
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
        my $prefix=$1;
	my $runnumber = int($2);
	my $segment = int($3);
	$prefix=~ s/$dsttype/DSTPASS1_TRACKS/g;
	my $outfilename = sprintf("%s-%010d-%05d.root",$prefix,$runnumber,$segment);
        $prefix=~ s/DSTPASS1_TRACKS/TpcSpaceChargeMatrices/g;
        my $outfilename2 = sprintf("%s-%010d-%05d.root",$prefix,$runnumber,$segment);
        my $exist_both = 0;
	$chkfile->execute($outfilename);
	if ($chkfile->rows > 0)
	{
	    $exist_both++;
	}
	$chkfile->execute($outfilename2);
	if ($chkfile->rows > 0)
	{
	    $exist_both++;
	}
	if ($exist_both == 2)
	{
	    next;
	}
	my $tstflag="";
	if (defined $test)
	{
	    $tstflag="--test";
	}
	my $subcmd = sprintf("perl run_condor.pl %s %s %s %s %d %d %s", $lfn, $outfilename, $outfilename2, $outdir, $runnumber, $segment, $tstflag);
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

$chkfile->finish();
$dbh->disconnect;
