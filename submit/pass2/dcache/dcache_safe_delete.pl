#!/usr/bin/perl

use File::Basename;
use File::stat;
use strict;
use DBI;

use Getopt::Long;

my %downfiles = ();
my $sourcedir = "/pnfs/rcf.bnl.gov/phenix/sphenixraw/MDC1/sHijing_HepMC/PileUp";
my $targetdir = "/pnfs/rcf.bnl.gov/sphenix/disk/MDC1/sHijing_HepMC/PileUp";


my $dokill;
GetOptions('kill'=>\$dokill);
if ( $#ARGV < 0 )
{

    print "usage: dcache_safe_delete.pl <number of files, 0 = all>\n";
    print "flags:\n";
    print "-kill   remove file for real\n";
    exit(-1);
}

my $ndel = $ARGV[0];
my $delfiles = 0;
my %sourcefiles = ();
my %targetfiles = ();

opendir(DIR, $sourcedir) or die "Could not open $sourcedir\n";
while (my $filename = readdir(DIR)) 
{
    if ($filename !~ /\.root/)
    {
	next;
    }
    $sourcefiles{$filename} = sprintf("%s/%s",$sourcedir,$filename);
}
closedir(DIR);

opendir(DIR, $targetdir) or die "Could not open $targetdir\n";
while (my $filename = readdir(DIR)) 
{
    if ($filename !~ /\.root/)
    {
	next;
    }
    $targetfiles{$filename} = sprintf("%s/%s",$targetdir,$filename);
}
closedir(DIR);

if (! defined $dokill)
{
    print "TestMode, use -kill to delete files for real\n";
}

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $delfcat = $dbh->prepare("delete from files where full_file_path=?");
my $checksize = $dbh->prepare("select size from files where full_file_path=?");
foreach my $lfn (sort keys %sourcefiles)
{
    if (exists $targetfiles{$lfn})
    {
#	print "lfn: $lfn\n";
#	print "target: $targetfiles{$lfn}\n";
#	print "source: $sourcefiles{$lfn}\n";
	my $sourcesize = stat($sourcefiles{$lfn})->size;
	my $targetsize = stat($targetfiles{$lfn})->size;
# check source file size in filecatalog
	if ($sourcesize == $targetsize)
	{
	    $checksize->execute($sourcefiles{$lfn});
	    if ( $checksize->rows > 0)
	    {
		my @res = $checksize->fetchrow_array();
		if ($sourcesize != $res[0])
		{
		    print "mismatch between stored size  $res[0] and actual size $sourcesize for source $sourcefiles{$lfn}\n";
		    next;
		}
	    }
# check target file size in file catalog
	    $checksize->execute($targetfiles{$lfn});
	    if ( $checksize->rows > 0)
	    {
		my @res = $checksize->fetchrow_array();
		if ($targetsize != $res[0])
		{
		    print "mismatch between stored size  $res[0] and actual size $targetsize for target $targetfiles{$lfn}\n";
		    next;
		}
	    }
	    if ($ndel == 0 || $delfiles < $ndel)
	    {
		if (defined $dokill)
		{
		    print "unlink $sourcefiles{$lfn}\n";
		    unlink $sourcefiles{$lfn};
		    print "deleting $sourcefiles{$lfn} from fcat\n";
		    $delfcat->execute($sourcefiles{$lfn});
		}
		else
		{
		    print "would unlink $sourcefiles{$lfn}\n";
		    print "would delete $sourcefiles{$lfn} from fcat\n";
		}
		$delfiles++;
	    }
	    else
	    {
		print "$delfiles files deleted, all done\n";
		exit(0);
	    }
	}
    }
}

$delfcat->finish();
$checksize->finish();
$dbh->disconnect;
