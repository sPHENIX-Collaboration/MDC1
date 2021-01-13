#!/usr/bin/perl
# change priority: sed -i 's/Priority[[:space:]]*=\s20/Priority = 21/g' log/*.job

use strict;
use warnings;
use File::Basename;
use File::stat;
use Getopt::Long;

my $submit;
GetOptions("submit"=>\$submit);

print "usage: restart_crashed.pl\n";
print "--submit:  submit condor jobs\n";

my $topdcachedir = "/pnfs/rcf.bnl.gov/phenix/sphenixraw/MDC1";
my $indirfile = sprintf("outdir.txt");
if (! -f $indirfile)
{
    print "could not find file with input directory $indirfile\n";
    exit(1);
}
my $indir = `cat $indirfile`;
chomp $indir;
my $dcachedir = dirname($indir);
my @sp1 = split(/MDC1\//,$dcachedir);
$dcachedir = sprintf("%s/%s",$topdcachedir,$sp1[1]);
print "$dcachedir\n";


my $maxjob = `ls -1 log/*.job | tail -1`;
chomp $maxjob;
#print "$maxjob\n";
my $maxnum;
my $runnumber;
if ($maxjob =~ /(\S+)-(\d+)-(\d+).*\..*/ )
{
    $runnumber = int($2);
    $maxnum = int($3);
}
else
{
    die;
}
print "max jobnum: $maxnum\n";

my %running = ();
open(F,"condor_q | grep hepmc | awk '{print \$12}' |");
while(my $outfile = <F>)
{
    chomp $outfile;
    if ($outfile =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
        my $segment = int($3);
	$running{$segment} = $outfile;
    }
    else
    {
	die "could not decode $outfile\n";
    }
}
close(F);

open(F,"find $indir -maxdepth 1 -type f -name '*.root' |");
while (my $file = <F>)
{
    chomp $file;
    my $lfn = basename($file);
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
	my $segment = int($3);
	if (! exists $running{$segment})
	{
	    $running{$segment} = $lfn;
#	    print "adding $segment\n";
	}
    }
}
close(F);

open(F,"find $dcachedir -maxdepth 1 -type f -name '*.root' |");
while (my $file = <F>)
{
    chomp $file;
    my $lfn = basename($file);
    if ($lfn =~ /(\S+)-(\d+)-(\d+).*\..*/ )
    {
	my $segment = int($3);
	if (! exists $running{$segment})
	{
	    $running{$segment} = $lfn;
#	    print "adding $segment\n";
	}
    }
}
close(F);

for(my $ijob = 0; $ijob<= $maxnum; $ijob++)
{
    if (exists $running{$ijob})
    {
#	print "condor running for $ijob\n";
	next;
    }
# check condor file
    my $condorfile = sprintf("log/condor-%010d-%05d.job",$runnumber,$ijob);
    if (! -f $condorfile)
    {
	print "$condorfile missing\n";
    }
#    print "need to rerun $condorfile\n";
    my $gpfsfile = sprintf("%s/G4Hits_sHijing_0_12fm-%010d-%05d.root",$indir,$runnumber,$ijob);
    if (! -f $gpfsfile)
    {
	my $dcachefile = sprintf("%s/G4Hits_sHijing_0_12fm-%010d-%05d.root",$dcachedir,$runnumber,$ijob);
	if (! -f $dcachefile)
	{
#	    print "no $gpfsfile\n";
#	    print "no $dcachefile\n";
#	    print "need to rerun $condorfile\n";
	    my $condorsub = sprintf("condor_submit %s",$condorfile);
	    if (defined $submit)
	    {
		system($condorsub);
	    }
	    else
	    {
		print "would run $condorsub\n";
	    }
#	    die;
	}
    }

}
