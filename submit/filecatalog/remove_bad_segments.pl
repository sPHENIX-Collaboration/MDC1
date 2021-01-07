#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;

sub looparray;

my $topdir = "/sphenix/u/sphnxpro/MDC1/submit";

my $kill;
my $system = 0;
my $dsttype = "none";

GetOptions("kill"=>\$kill, "type:i"=>\$system, "dsttype:s"=>\$dsttype);

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfilename = $dbh->prepare("select filename from datasets where dsttype = ? and filename like ? and segment = ? order by filename") || die $DBI::error;
my $getfiles = $dbh->prepare("select full_file_path from files where lfn = ?");
my $deldataset = $dbh->prepare("delete from datasets where filename = ?");
my $delfcat = $dbh->prepare("delete from files where full_file_path = ?");
my %daughters = (
    "G4Hits" => [ "DST_BBC_G4HIT", "DST_CALO_G4HIT", "DST_TRKR_G4HIT", "DST_TRUTH_G4HIT", "DST_VERTEX" ],
    "DST_BBC_G4HIT" => [ "DST_CALO_G4HIT", "DST_TRKR_G4HIT", "DST_TRUTH_G4HIT", "DST_VERTEX" ],
    "DST_CALO_G4HIT" => [ "DST_BBC_G4HIT", "DST_TRKR_G4HIT", "DST_TRUTH_G4HIT", "DST_VERTEX", "DST_CALO_CLUSTER" ],
    "DST_TRKR_G4HIT" => [ "DST_BBC_G4HIT", "DST_CALO_G4HIT", "DST_TRUTH_G4HIT", "DST_VERTEX", "DST_TRKR_CLUSTER" ],
    "DST_TRUTH_G4HIT" => [ "DST_BBC_G4HIT", "DST_CALO_G4HIT", "DST_TRKR_G4HIT", "DST_VERTEX", "DST_TRKR_CLUSTER" ],
    "DST_VERTEX" => [ "DST_BBC_G4HIT", "DST_CALO_G4HIT", "DST_TRKR_G4HIT", "DST_TRUTH_G4HIT", "DST_CALO_CLUSTER" ],
    "DST_TRKR_CLUSTER" => [ "DST_TRACKS" ],
    "DST_TRACKS" => [ "" ],
    "DST_CALO_CLUSTER" => [ "" ]
    );

if ($#ARGV < 0)
{
    print "usage: remove_bad_segments.pl -dsttype <type> <segment>\n";
    print "parameters:\n";
    print "-kill : remove files for real\n";
    print "-type : production type\n";
    print "    1 : hijing 0-12fm\n";
    print "    2 : hijing 0-488fm\n";
    print "    3 : pythia8 mb\n";
    print "dsttypes:\n";
    foreach my $tp (sort keys %daughters)
    {
	print "$tp\n";
    }
    exit(0);
}

my $segment = $ARGV[0];

if( ! exists $daughters{$dsttype})
{
    print "bad dsttype, existing types:\n";
    foreach my $tp (sort keys %daughters)
    {
	print "$tp\n";
    }
    exit(0);
}
if ($system < 1 || $system > 3)
{
    print "use -type, valid values:\n";
    print "-type : production type\n";
    print "    1 : hijing 0-12fm\n";
    print "    2 : hijing 0-488fm\n";
    print "    3 : pythia8 mb\n";
    exit(0);
}

my $systemstring;
if ($system == 1)
{
    $systemstring = "sHijing_0_12fm";
    $topdir = sprintf("%s/fm_0_12",$topdir);
}
elsif ($system == 2)
{
    $systemstring = "sHijing_0_488fm";
    $topdir = sprintf("%s/fm_0_488",$topdir);
}
elsif ($system == 3)
{
    $systemstring = "pythia8_mb";
    $topdir = sprintf("%s/pythia8_pp_mb",$topdir);
}
else
{
    die "bad type $system\n";
}

my %productionsubdir = (
"DST_BBC_G4HIT" => "pass2",
"DST_CALO_CLUSTER" => "pass3calo",
"DST_CALO_G4HIT"=> "pass2",
"DST_TRACKS" => "pass4trk",
"DST_TRKR_CLUSTER" => "pass3trk",
"DST_TRKR_G4HIT" => "pass2",
"DST_TRUTH_G4HIT" => "pass2",
"DST_VERTEX" => "pass2",
"G4Hits" => "pass1"
    );

my %removethese = ();
$removethese{$dsttype} = 1;
&looparray($dsttype);
foreach my $rem (keys %removethese)
{
    my $condor_subdir = sprintf("%s/%s/condor/log",$topdir,$productionsubdir{$rem});
    my $condorjobfile = sprintf("%s/condor-%010d-%05d.job",$condor_subdir,1,$segment);
    my $condoroutfile = sprintf("%s/condor-%010d-%05d.out",$condor_subdir,1,$segment);
    my $condorerrfile = sprintf("%s/condor-%010d-%05d.err",$condor_subdir,1,$segment);
    my $lfn = sprintf("%s_%s-%010d-%05d.root",$rem,$systemstring,1,$segment);
    $getfilename->execute($rem,'%'.$systemstring.'%',$segment);
    if ($getfilename->rows == 1)
    {
	my @res = $getfilename->fetchrow_array();
	$getfiles->execute($res[0]);
	while (my @res2 = $getfiles->fetchrow_array())
	{
	    if (defined $kill)
	    {
		print "rm $res2[0], deleting from fcat\n";
		unlink $res2[0];
		$delfcat->execute($res2[0]);
	    }
	    else
	    {
		print "would rm $res2[0]\n";
	    }
	}
	if (defined $kill)
	{
	    print "removing $res[0] from datasets\n";
	    $deldataset->execute($res[0]);
	}
	else
	{
	    print "would remove $res[0] from datasets\n";
	}

    }
    if (-f $condorjobfile)
    {
	if (defined $kill)
	{
	    print "removing $condorjobfile, $condorerrfile, $condoroutfile\n";
	    unlink $condorjobfile;
	    unlink $condorerrfile;
	    unlink $condoroutfile;
	}
	else
	{
	    print "would remove $condorjobfile, $condorerrfile, $condoroutfile\n";
	}
    }
}


sub looparray
{
    my $thistype = $_[0];
    my @types = @{$daughters{$thistype}};
    foreach my $entry (@types)
    {
	if (exists $removethese{$entry})
	{
	    next;
	}
	if ($entry eq "")
	{
	    return;
	}
	$removethese{$entry} = 1;
 	&looparray($entry);
    }
}
