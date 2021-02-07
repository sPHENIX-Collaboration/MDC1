#!/usr/bin/perl

use strict;
use DBI;
use File::Basename;
use File::stat;
use Getopt::Long;

sub write_copyfile();

my $nfiles = 10000;

my $dcache = 0;
my $dsttype = "all";
my %dsthash = ();
GetOptions("dcache:i"=>\$dcache, "dsttype:s"=>\$dsttype);
if (! defined $dsttype)
{
    print "no dsttype given\n";
    exit(1);
}
if ($dsttype eq "all")
{
    $dsthash{"DST_HF_CHARM"} = 1;
    $dsthash{"DST_HF_BOTTOM"} = 1;
}
else
{
    $dsthash{"$dsttype"} = 1;
}

my @dcpath = ();
push(@dcpath,"/pnfs/rcf.bnl.gov/sphenix/disk/MDC1/HF_pp200_signal");
push(@dcpath,"/pnfs/rcf.bnl.gov/phenix/sphenixraw/MDC1/HF_pp200_signal");
if ($dcache > 1 || $dcache < 0)
{
    print "invalid dcache number $dcache\n";
    print "use -dcache=0 for $dcpath[0]\n";
    print "use -dcache=1 for $dcpath[1]\n";
    exit(1);
}
my $otherdcache;
if ($dcache == 0)
{
    $otherdcache = 1;
}
else
{
    $otherdcache = 0;
}

my %gpfsfiles = ();
my %myfiles = ();
my %otherfiles = ();

my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here

foreach my $dst (keys %dsthash)
{
    my $dstname = sprintf("%s_pythia8-",$dst);
    my $getmyfiles = $dbh->prepare("select lfn,full_file_path from files where lfn like '%$dstname%' and full_file_path like '$dcpath[$dcache]%' order by lfn");
    my $getgpfsfiles = $dbh->prepare("select lfn,full_file_path from files where lfn like '%$dstname%' and full_host_name = 'gpfs' order by lfn");
    my $getotherfiles = $dbh->prepare("select lfn,full_file_path from files where lfn like '%$dstname%' and full_file_path like '$dcpath[$otherdcache]%' order by lfn");

    $getmyfiles->execute();
    while (my @res = $getmyfiles->fetchrow_array())
    {
	$myfiles{$res[0]} = $res[1];
    }
    $getgpfsfiles->execute();
    while (my @res = $getgpfsfiles->fetchrow_array())
    {
	$gpfsfiles{$res[0]} = $res[1];
    }
    $getotherfiles->execute();
    while (my @res = $getotherfiles->fetchrow_array())
    {
	$otherfiles{$res[0]} = $res[1];
    }
    $getmyfiles->finish();
    $getgpfsfiles->finish();
    $getotherfiles->finish();
}

foreach my $lfn (keys %myfiles)
{
    delete($gpfsfiles{$lfn});
    delete($otherfiles{$lfn});
}
my $ncurfiles = 0;
foreach my $lfn (sort keys %otherfiles)
{
    if (-f $otherfiles{$lfn})
    {
	delete($gpfsfiles{$lfn});
	my $dcachoutfile = sprintf("%s/%s",$dcpath[$dcache],$lfn);
	&write_copyfile($otherfiles{$lfn},$dcachoutfile);
    }
    else
    {
	print "could not locate $otherfiles{$lfn}\n";
	die;
    }
}
foreach my $lfn (sort keys %gpfsfiles)
{
    if (-f $gpfsfiles{$lfn})
    {
	my $dcachoutfile = sprintf("%s/%s",$dcpath[$dcache],$lfn);
	&write_copyfile($gpfsfiles{$lfn},$dcachoutfile);
    }
    else
    {
	print "could not locate $gpfsfiles{$lfn}\n";
	die;
    }
}
my $ngpfs = keys %gpfsfiles;
my $ndcache = keys %otherfiles;
print "files in gpfs: $ngpfs, files in dcache: $ndcache\n";
if ($ncurfiles > 0)
{
    print F2 "print \"all done\\n\";\n";
    close(F2);
}
$dbh->disconnect;


sub write_copyfile()
{
    my $infile = $_[0];
    my $dcfile = $_[1];
    if ($ncurfiles == 0)
    {
	my $index = 0;
	my $scriptfile = sprintf("dccp_%02d.pl",$index);
	while(-f $scriptfile)
	{
	    $index++;
	    $scriptfile = sprintf("dccp_%02d.pl",$index);
	}
	open(F2,">$scriptfile");
	print F2 "#!/usr/bin/perl\n";

    }
    my $outdir = dirname($dcfile);
    print F2 "if (! -d \"$outdir\")\n";
    print F2 "{\n";
    print F2 "  system(\"mkdir -p $outdir\");\n";
    print F2 "}\n";
    print F2 "if (! -e \"$dcfile\")\n";
    print F2 "{\n";
    print F2 "  system(\"dccp -d7 -C 3600 $infile $dcfile\");\n";
    print F2 "if (\$exit_value != 0)\n";
    print F2    "{\n";
    print F2    "  die \"dccp failed for $infile\\n\";\n";
    print F2    "}\n";
    print F2 "}\n";
    $ncurfiles++;
    if ($ncurfiles >= $nfiles)
    {
	$ncurfiles = 0;

	print F2 "print \"all done\\n\";\n";
	close(F2);
    }
#    print "copy $infile to $dcfile\n";
}
