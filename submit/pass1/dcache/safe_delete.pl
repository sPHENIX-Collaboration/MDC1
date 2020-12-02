#!/usr/bin/perl

use File::Basename;
use File::stat;
use strict;

use Getopt::Long;

sub checkdownstream;

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
my $topdcachedir = "/pnfs/rcf.bnl.gov/phenix/sphenixraw/MDC1";
my $indirfile = "../condor/outdir.txt";
if (! -f $indirfile)
{
    die "could not find $indirfile";
}
my $indir = `cat $indirfile`;
chomp $indir;
my $dcachedir = dirname($indir);
my @sp1 = split(/MDC1\//,$dcachedir);
$dcachedir = sprintf("%s/%s",$topdcachedir,$sp1[1]);
print "$dcachedir\n";

my $downstreamdir;
my %downfiles = ();

if (! defined $dokill)
{
    print "TestMode, use -kill to delete files for real\n";
}


open(F,"find $indir -maxdepth 1 -type f -name '*.root' | sort|");
while (my $file = <F>)
{
    chomp $file;
    my $origsize = stat($file)->size;
    my $lfn = basename($file);
    my $dcachefile = sprintf("%s/%s",$dcachedir,$lfn);
    if (-f $dcachefile)
    {
	my $dcsize = stat($dcachefile)->size;
	if ($dcsize == $origsize)
	{
	    my $okay = &checkdownstream($file);
	    if ($okay == 0)
	    {
		if (defined $dokill)
		{
		    print "delete $file\n";
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
	    else
	    {
		print "downstream files missing\n";
	    }

	    next;
	}
	else
	{
	    if ( $dcsize > 0)
	    {
		print "will not delete $file with dc size $dcsize\n";
	    }
	}
    }
}
close(F);

sub checkdownstream
{
    my $infile = basename($_[0]);
    if (! defined $downstreamdir)
    {
	my $downstreamfile = "../../pass2/condor/outdir.txt";
	if (! -f $downstreamfile)
	{
	    die "could not find $downstreamfile";
	}
	my $downstreamdir = `cat $downstreamfile`;
	chomp $downstreamdir;
	$downfiles{"DST_BBC_G4HIT"} = $downstreamdir;
	$downfiles{"DST_CALO_G4HIT"} = $downstreamdir;
	$downfiles{"DST_TRKR_G4HIT"} = $downstreamdir;
	$downfiles{"DST_TRUTH_G4HIT"} = $downstreamdir;
    }

    my @sp1 = split(/_sHijing/,$infile);
    foreach my $outf (keys %downfiles)
    {
	my $tstfile = sprintf("%s/%s_sHijing%s",$downfiles{$outf},$outf,$sp1[1]);
	if (! -f $tstfile)
	{
	    print "cannot find $tstfile\n";
	    return -1;
	}
	else
	{
#	    print "found $tstfile\n";
	}
    }
    return 0;
}

