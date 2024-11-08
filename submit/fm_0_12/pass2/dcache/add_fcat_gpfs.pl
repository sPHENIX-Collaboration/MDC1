#!/usr/bin/perl

use strict;
use File::Basename;
use File::stat;
use DBI;
use Getopt::Long;

my $test;
GetOptions("test"=>\$test);

my $indirfile = "../condor/outdir.gpfs.txt";
if (! -f $indirfile)
{
    die "could not find $indirfile";
}
my $indir = `cat $indirfile`;
chomp $indir;
if ($indir =~ /pnfs/)
{
    print "indir contains pnfs - that is wrong\n";
    exit(1);
}

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc");
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $chkfile = $dbh->prepare("select size,full_file_path from files where lfn=? and full_host_name = 'gpfs'"); 
my $insertfile = $dbh->prepare("insert into files (lfn,full_host_name,full_file_path,time,size) values (?,'gpfs',?,'now',?)");
my $updatesize = $dbh->prepare("update files set size=? where lfn = ? and full_file_path = ?");
my $insertdataset = $dbh->prepare("insert into datasets (filename,runnumber,segment,size,dataset,dsttype) values (?,?,?,?,'mdc1',?)");
my $chkdataset = $dbh->prepare("select size from datasets where filename=? and dataset='mdc1'");
my $updatedataset = $dbh->prepare("update datasets set size = ? where filename=?");
open(F,"find $indir -maxdepth 1 -type f -name '*.root' | sort |");
while (my $file = <F>)
{
    chomp $file;
    my $fsize = stat($file)->size;
    if ($fsize == 0) # file being copied is zero size
    {
	next;
    }
    my $lfn = basename($file);
    my $needinsert = 1;
#    print "checking $lfn\n";

    $chkfile->execute($lfn);
    while(my @res = $chkfile->fetchrow_array())
    {
	if ($res[1] eq  $file)
	{
	    if ($fsize == $res[0])
	    {
		$needinsert = 0;
		next;
	    }
	    else
	    {
		if (! defined $test)
		{
		    $updatesize->execute($fsize,$lfn,$file);
		}
		else
		{
		    print "would update size for $lfn from $res[0] to $fsize\n";
		}
	    }
	}
    }
    if ($needinsert != 0)
    {
	if (! defined $test)
	{
	    print "inserting $lfn into filecatalog\n";
	    $insertfile->execute($lfn,$file,$fsize);
	}
	else
	{
	    print "would insert $lfn, $file, $fsize\n";
	}
    }    
    $chkdataset->execute($lfn);
    if ($chkdataset->rows == 0)
    {
	my $runnumber = 0;
	my $segment = -1;
	if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/)
	{
	    $runnumber = int($2);
	    $segment = int($3);
	}
	my @sp1 = split(/\_sHijing/,$lfn);
	if (! defined $test)
	{
	    $insertdataset->execute($lfn,$runnumber,$segment,$fsize,$sp1[0]);
	}
	else
	{
	    print "would insert $lfn, $runnumber, $segment, $fsize into datasets\n";
	}
    }
    else
    {
	while (my @res =  $chkdataset->fetchrow_array())
	{
	    if ($fsize != $res[0])
	    {
		if (! defined $test)
		{
		    $updatedataset->execute($fsize,$lfn);
		}
		else
		{
		    print "would update size for $lfn from $res[0] to $fsize\n";
		}
	    }
	}
    }
}

close(F);
