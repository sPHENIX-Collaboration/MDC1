#!/usr/bin/perl

use strict;
use warnings;
use File::Path;
use File::Basename;
use Getopt::Long;
use DBI;
use Digest::MD5  qw(md5 md5_hex md5_base64);

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here

my $getfiles = $dbh->prepare("select filename from datasets,files where datasets.dsttype = 'G4Hits' and datasets.filename = files.lfn and files.md5 is null order by filename");
my $updatemd5 = $dbh->prepare("update files set md5=? where lfn=?");
my $indirfile = "../condor/outdir.txt";
if (! -f $indirfile)
{
    die "could not find $indirfile";
}
my $indir = `cat $indirfile`;
chomp $indir;
$getfiles->execute()|| die $DBI::error;
while (my @res = $getfiles->fetchrow_array())
{
    my $fullfile = sprintf("%s/%s",$indir,$res[0]);
    if (-f $fullfile)
    {
	print "handling $fullfile\n";
	open FILE, "$fullfile";
	my $ctx = Digest::MD5->new;
	$ctx->addfile (*FILE);
	my $hash = $ctx->hexdigest;
	close (FILE);
	printf("md5_hex:%s\n",$hash);
	$updatemd5->execute($hash,$res[0]);
    }
}
$getfiles->finish();
$dbh->disconnect;
