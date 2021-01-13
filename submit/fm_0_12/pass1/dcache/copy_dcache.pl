#!/usr/bin/perl

use strict;
use File::Basename;
use File::stat;
use Getopt::Long;

sub write_copyfile();

my $test;
GetOptions("test"=>\$test);

if ($#ARGV < 0)
{
    print "usage: copy_dcache.pl <number of files>\n";
    print "--test : dryrun - print stuff\n";
    exit(0);
}

my $maxcopy = $ARGV[0];
my $nfiles = 1000;
my $topdcachedir = "/pnfs/rcf.bnl.gov/sphenix/disk/MDC1";
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

my $ncopy = 0;
my $ncurfiles = 0;
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
#	    print "found dcfile $dcachefile with size $dcsize okay\n";
	    next;
	}
	else
	{
	    if (! defined $test)
	    {
		print "check size mismatch $lfn, gpfs size $origsize, dcache $dcsize\n";
	    }
	    else
	    {
		print "would delete size mismatch $lfn, gpfs size $origsize, dcache $dcsize\n";
	    }
	}
    }
    &write_copyfile($file,$dcachefile);
    $ncopy++;
    if ($ncopy >= $maxcopy)
    {
	print "reached $maxcopy copies\n";
	last;
    }
}
close(F);
if ($ncurfiles > 0)
{
    print F2 "print \"all done\\n\";\n";
    close(F2);
}
exit(0);

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
    print F2 "  system(\"date\");\n";
    print F2 "  system(\"echo -n \\\"begin unixdate \\\"\");\n";
    print F2 "  system(\"date +%s\");\n";
    print F2 "  system(\"date +%s\");\n";
    print F2 "  system(\"dccp -d7 -C 3600 $infile $dcfile\");\n";
    print F2 "  if (\$exit_value != 0)\n";
    print F2 "    {\n";
    print F2 "      die \"dccp failed for $infile\\n\";\n";
    print F2 "    }\n";
    print F2 "  system(\"date\");\n";
    print F2 "  system(\"echo -n \\\"end unixdate \\\"\");\n";
    print F2 "  system(\"date +%s\");\n";
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
