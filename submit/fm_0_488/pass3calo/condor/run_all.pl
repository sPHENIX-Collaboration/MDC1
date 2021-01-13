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

my $maxsubmit = $ARGV[0];
if (! -f "outdir.txt")
{
    print "could not find outdir.txt\n";
    exit(1);
}
my $outdir = `cat outdir.txt`;
chomp $outdir;
mkpath($outdir);


my %calohash = ();
my %vtxhash = ();

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_CALO_G4HIT' and filename like '%sHijing_0_488fm%' order by filename") || die $DBI::error;
my $chkfile = $dbh->prepare("select lfn from files where lfn=?") || die $DBI::error;
my $getvtxfiles = $dbh->prepare("select filename,segment from datasets where dsttype = 'DST_VERTEX' and filename like '%sHijing_0_488fm%'");
my $nsubmit = 0;
$getfiles->execute() || die $DBI::error;
my $ncal = $getfiles->rows;
while (my @res = $getfiles->fetchrow_array())
{
    $calohash{$res[1]} = $res[0];
}
$getfiles->finish();
$getvtxfiles->execute() || die $DBI::error;
my $nvtx = $getvtxfiles->rows;
while (my @res = $getvtxfiles->fetchrow_array())
{
    $vtxhash{$res[1]} = $res[0];
}
$getvtxfiles->finish();
print "input files: $ncal, vtx: $nvtx\n";
foreach my $segment (sort keys %calohash)
{
    if (! exists $vtxhash{$segment})
    {
	next;
    }

    my $lfn = $calohash{$segment};
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
	my $runnumber = int($2);
	my $segment = int($3);
	my $outfilename = sprintf("DST_CALO_CLUSTER_sHijing_0_488fm-%010d-%05d.root",$runnumber,$segment);
	$chkfile->execute($outfilename);
	if ($chkfile->rows > 0)
	{
	    next;
	}
	my $tstflag="";
	if (defined $test)
	{
	    $tstflag="--test";
	}
	my $subcmd = sprintf("perl run_condor.pl %d %s %s %s %s %d %d %s", $outevents, $lfn, $vtxhash{$segment}, $outfilename, $outdir, $runnumber, $segment, $tstflag);
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
