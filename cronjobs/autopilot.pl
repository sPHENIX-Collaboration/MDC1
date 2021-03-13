#!/usr/bin/perl

use strict;
use warnings;
use Cwd;

my $submittopdir = "/sphenix/u/sphnxpro/MDC1/submit";
my @submitdir = ("fm_0_488/pass2_50kHz_0_20fm/condor",
		 "fm_0_488/pass3calo_50kHz_0_20fm/condor",
		 "fm_0_488/pass3trk_50kHz_0_20fm/condor",
		 "fm_0_488/pass4trk_50kHz_0_20fm/condor",
		 "fm_0_20/pass2/condor",
		 "fm_0_20/pass3trk/condor",
		 "fm_0_20/pass3calo/condor",
		 "fm_0_20/pass4trk/condor"
);
foreach my $subdir (@submitdir)
{
    my $newdir = sprintf("%s/%s",$submittopdir,$subdir);
    if (! -d $newdir)
    {
	print "dir $newdir does not exist\n";
	next;
    }
    chdir $newdir;
    if (! -f "run_all.pl")
    {
	print "run_all.pl does not exist in $newdir\n";
	next;
    }
    my $submitcmd = sprintf("perl run_all.pl 1000 -inc");
    print "executing $submitcmd in $newdir\n";
    system($submitcmd);
}
