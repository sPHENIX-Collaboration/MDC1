#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;

my $system = 0;

GetOptions("type:i"=>\$system);

if ($system < 1 || $system > 8)
{
    print "use -type, valid values:\n";
    print "-type : production type\n";
    print "    1 : hijing (0-12fm) pileup 0-12fm\n";
    print "    2 : hijing (0-4.88fm) pileup 0-12fm\n";
    print "    3 : pythia8 pp MB\n";
    print "    4 : hijing (0-20fm) pileup 0-20fm\n";
    print "    5 : hijing (0-12fm) pileup 0-20fm\n";
    print "    6 : hijing (0-4.88fm) pileup 0-20fm\n";
    print "    7 : HF pythia8 Charm\n";
    print "    8 : HF pythia8 Bottom\n";
    exit(0);
}

my $systemstring;
my $gpfsdir = "sHijing_HepMC";
if ($system == 1)
{
    $systemstring = "sHijing_0_12fm_50kHz_bkg_0_12fm";
}
elsif ($system == 2)
{
    $systemstring = "sHijing_0_488fm_50kHz_bkg_0_12fm";
}
elsif ($system == 3)
{
    $systemstring = "pythia8_mb";
    $gpfsdir = "pythia8_pp";
}
elsif ($system == 4)
{
    $systemstring = "sHijing_0_20fm";
}
elsif ($system == 5)
{
    $systemstring = "sHijing_0_12fm_50kHz_bkg_0_20fm";
}
elsif ($system == 6)
{
    $systemstring = "sHijing_0_488fm_50kHz_bkg_0_20fm";
}
elsif ($system == 7)
{
    $systemstring = "DST_HF_CHARM_pythia8-";
    $gpfsdir = "HF_pp200_signal";
}
elsif ($system == 8)
{
    $systemstring = "DST_HF_BOTTOM_pythia8-";
    $gpfsdir = "HF_pp200_signal";
}
else
{
    die "bad type $system\n";
}

open(F,">missing.files");
my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getdsttypes = $dbh->prepare("select distinct(dsttype) from datasets where filename like '%$systemstring%' order by dsttype");

my %topdcachedir = ();
$topdcachedir{sprintf("/pnfs/rcf.bnl.gov/sphenix/disk/MDC1/%s",$gpfsdir)} = 1;
#$topdcachedir{"/pnfs/rcf.bnl.gov/phenix/sphenixraw/MDC1/sHijing_HepMC"} = 1;

if ($#ARGV < 0)
{
    print "available types:\n";

    $getdsttypes->execute();
    while (my @res = $getdsttypes->fetchrow_array())
    {
	print "$res[0]\n";
    }
    exit(1);
}


my $type = $ARGV[0];
my $getsegments = $dbh->prepare("select segment,filename from datasets where dsttype = ? and  filename like '%$systemstring%' order by segment")|| die $DBI::error;
my $getlastseg = $dbh->prepare("select max(segment) from datasets where dsttype = ? and filename like '%$systemstring%'")|| die $DBI::error;

$getlastseg->execute($type)|| die $DBI::error;;
my @res = $getlastseg->fetchrow_array();
my $lastseg = $res[0];
$getsegments->execute($type);
my %seglist = ();
while (my @res = $getsegments->fetchrow_array())
{
    $seglist{$res[0]} = $res[1];
}
my $nsegs_gpfs = keys %seglist;
print "number of segments processed:  $nsegs_gpfs\n";
foreach my $dcdir (keys  %topdcachedir)
{
 my $getsegsdc = $dbh->prepare("select lfn from files where lfn like '$type%' and lfn like '%$systemstring%' and full_file_path like '$dcdir/$type/$type%'");
 $getsegsdc->execute();
 my $rows = $getsegsdc->rows;
 print "entries for $dcdir: $rows\n";
 $getsegsdc->finish();
}
my $chklfn = $dbh->prepare("select lfn from files where lfn = ? and full_file_path like '/pnfs/rcf.bnl.gov/sphenix/disk/MDC1/$gpfsdir/%'");
#my $chklfn = $dbh->prepare("select lfn from files where lfn = ? and full_file_path like '/pnfs/rcf.bnl.gov/phenix/sphenixraw/MDC1/sHijing_HepMC/%'");
for (my $iseg = 0; $iseg <= $lastseg; $iseg++)
{
    if (!exists $seglist{$iseg})
   {
	print "segment $iseg missing\n";
	next;
   }
    else
    {
	$chklfn->execute($seglist{$iseg});
	if ($chklfn->rows == 0)
	{
	    print F "$seglist{$iseg}\n";
	    print "$seglist{$iseg} missing\n";
	}
    }
}
close(F);
$chklfn->finish();
$getsegments->finish();
$getlastseg->finish();
$getdsttypes->finish();
$dbh->disconnect;
