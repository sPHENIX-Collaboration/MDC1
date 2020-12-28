#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;

my $update;
GetOptions("update"=>\$update);
my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $getfiles = $dbh->prepare("select lfn,count(*) from files group by lfn having count(*) > 1 order by lfn") || die $DBI::error;
my $getthisfile = $dbh->prepare("select lfn,full_file_path,size,md5 from files where lfn = ?") || die $DBI::error;
my $updatemd5 = $dbh->prepare("update files set md5=? where lfn=? and full_file_path = ?") || die $DBI::error;

$getfiles->execute();

while (my @res = $getfiles->fetchrow_array())
{
    my $lfn = $res[0];
    $getthisfile->execute($lfn);
    my $size;
    my $md5sum;
    my %files_no_md5 = ();
    while (my @fres = $getthisfile->fetchrow_array())
    {
	if (! defined $size)
	{
	    $size = $fres[2];
	}
	else
	{
	    if ($size != $fres[2])
	    {
		print "file size mismatch for $lfn, $fres[1]\n";
		die;
	    }
	}
	if (! defined $fres[3])
	{
	    $files_no_md5{$fres[1]} = 1;
	    next;
	}
	if (! defined $md5sum) # first valid md5 sum is used for reference
	{
	    $md5sum = $fres[3];
	}
	else # md5sum defined by construction
	{
	    if ($md5sum ne  $fres[3])
	    {
		print "md5 sum mismatch for  $lfn, $fres[1]\n";
		die;
	    }
	}
    }
    if (keys %files_no_md5 == 0)
    {
	next;
    }
    if (! defined $md5sum)
    {
#	print "no md5sum for $lfn\n";
	next;
    }
    foreach my $entry (keys %files_no_md5)
    {
	if (defined $update)
	{
	    print "setting md5 for $entry to $md5sum\n";
	    $updatemd5->execute($md5sum,$lfn,$entry);
	}
	else
	{
	    print "would set md5 for $entry to $md5sum\n";
	}
    }
}
$getfiles->finish();
$getthisfile->finish();
$dbh->disconnect;
