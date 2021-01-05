#!/usr/bin/perl

use File::Basename;
use File::stat;
use strict;
use DBI;

use Getopt::Long;

sub checkdownstream;

my $fmrange = "0_488fm";
my %downfiles = ();
$downfiles{"DST_BBC_G4HIT"} = 1;
$downfiles{"DST_CALO_G4HIT"} = 1;
$downfiles{"DST_TRKR_G4HIT"} = 1;
$downfiles{"DST_TRUTH_G4HIT"} = 1;
$downfiles{"DST_VERTEX"} = 1;

my $dokill;
GetOptions('kill'=>\$dokill);
if ( $#ARGV < 0 )
{

    print "usage: safe_delete.pl <number of files, 0 = all>\n";
    print "flags:\n";
    print "-kill   remove file for real\n";
    exit(-1);
}

my $ndel = $ARGV[0];
my $delfiles = 0;
my $indirfile = "../condor/outdir.txt";
if (! -f $indirfile)
{
    die "could not find $indirfile";
}
my $indir = `cat $indirfile`;
chomp $indir;


if (! defined $dokill)
{
    print "TestMode, use -kill to delete files for real\n";
}

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getinfo = $dbh->prepare("select lfn,size,full_file_path,full_host_name,md5 from files where lfn = ? and full_host_name = 'dcache' and md5 is not null");
my $getdataset = $dbh->prepare("select runnumber,segment from datasets where filename=?");
my $checkdataset = $dbh->prepare("select filename from datasets where runnumber=? and segment = ? and dsttype=?");
my $delfcat = $dbh->prepare("delete from files where lfn=? and full_file_path=?");

open(F,"find $indir -maxdepth 1 -type f -name '*.root' | sort|");
while (my $file = <F>)
{
    if ($file !~ /$fmrange/)
    {
	next;
    }
    chomp $file;
    my $origsize = stat($file)->size;
    my $lfn = basename($file);
    $getinfo->execute($lfn);
    if ($getinfo->rows == 0)
    {
	next;
    }
    elsif ($getinfo->rows > 2)
    {
	print "more than two rows for $lfn in dcache check it\n";
	die;
    }
    my @res = $getinfo->fetchrow_array();
    if ($res[1] != $origsize)
    {
	print "size mismatch gpfs-dcache for $lfn:  $origsize, $res[1]\n";
	next;
    }
    my $dcachefile = $res[2];
    if (! -f $dcachefile)
    {
	print "dcache file $dcachefile does not exist\n";
	next;
    }
    my $dcsize = stat($dcachefile)->size;
    if ($dcsize != $origsize)
    {
	print "dcache size for $lfn: $dcsize not from file catalog: $res[1]\n";
	next;
    }
    my $isokay = checkdownstream($lfn);
    if ($isokay == 0)
    {
	next;
    }
    if (defined $dokill)
    {
	print "delete $file\n";
	$delfcat->execute($lfn, $file);
	unlink $file;
    }
    else
    {
	print "would delete $file\n";
    }
    $delfiles++;
    if ($ndel > 0 && $delfiles >= $ndel)
    {
	print "deleted $delfiles files, quitting\n";
	exit(0);
    }
}
close(F);

$getinfo->finish();
$getdataset->finish();
$checkdataset->finish();
$delfcat->finish();
$dbh->disconnect;

sub checkdownstream
{
    my $infile = basename($_[0]);
    $getdataset->execute($infile);
    my @res = $getdataset->fetchrow_array();
    foreach my $downfiletype (keys %downfiles)
    {
	$checkdataset->execute($res[0],$res[1],$downfiletype);
	if ($checkdataset->rows == 0)
	{
	    return 0;
	}
    }
    return 1;
}
