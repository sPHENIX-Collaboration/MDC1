#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;
use File::Path;
use File::stat;
use Getopt::Long;
use DBI;
use Digest::MD5  qw(md5 md5_hex md5_base64);
use Env;

sub getmd5;

Env::import();
my $test;
my $filelist;
GetOptions("test"=>\$test, "filelist" => \$filelist);


my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $filelocation = $dbh->prepare("select full_file_path,md5,size from files where lfn = ? and full_host_name = 'dcache'") || die $DBI::error; 
my $updatemd5 = $dbh->prepare("update files set md5=? where full_file_path = ?");

my %inputfiles = ();

if (defined $filelist)
{
    open(F,"$ARGV[0]");
    while (my $lfn = <F>)
    {
	chomp $lfn;
	$inputfiles{$lfn} = 1;
    }
    close(F);
}
else
{
    $inputfiles{$ARGV[0]} = 1;
}

foreach my $file (keys %inputfiles)
{
  print "will copy $file\n";
}

foreach my $file (keys %inputfiles)
{
    $filelocation->execute($file);

    my @res = $filelocation->fetchrow_array();
#    print "full: $res[0]\n";
    if (! defined $res[1])
    {
	print "md5 needs recalc\n";
    }
#    else
#    {
#	print "md5: $res[1]\n";
#    }
#    print "size: $res[2]\n";

    my $copycmd = sprintf("env LD_LIBRARY_PATH=/usr/lib64:%s xrdcp --nopbar --retry 3 root://dcsphdoor02.rcf.bnl.gov:1095%s .", $LD_LIBRARY_PATH, $res[0]);
    print "executing $copycmd\n";

    system($copycmd);

    if (-f $file)
    {
        my $fsize =  stat($file)->size;
	if ($fsize != $res[2])
	{
	    print "size mismatch for $file, db: $res[2], on disk: $fsize\n";
	    die;
	}
	else
	{
	    print "size for $file matches $fsize\n";
	}
	my $recalcmd5 = &getmd5($file);
	if (defined $res[1])
	{
	    if ($res[1] ne $recalcmd5)
	    {
		print "md5 mismatch for $res[0], orig $res[1], recalc $recalcmd5\n";
		die;
	    }
	    else
	    {
		print "md5 for $res[0] matches: $recalcmd5\n";
	    }
	}
	else
	{
	    $updatemd5->execute($recalcmd5,$res[0]);
	}
    }
    else
    {
	print "local copy of $res[0] failed\n";
    }
}

sub getmd5
{
    my $fullfile = $_[0];
    my $hash;
    if (-f $fullfile)
    {
	open FILE, "$fullfile";
	my $ctx = Digest::MD5->new;
	$ctx->addfile (*FILE);
	$hash = $ctx->hexdigest;
	close (FILE);
#	printf("md5_hex:%s\n",$hash);
    }
    return $hash;
}
