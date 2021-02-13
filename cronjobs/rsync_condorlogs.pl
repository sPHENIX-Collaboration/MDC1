#!/usr/bin/perl

use strict;
use warnings;

my $submitdir = "/sphenix/u/sphnxpro/MDC1/submit";
my %condorlogs = ();
my @fmrange = ();
push(@fmrange,"fm_0_488");
push(@fmrange,"fm_0_12");
push(@fmrange,"fm_0_20");

my @passes = ();
push(@passes,"pass1");
push(@passes,"pass2");
push(@passes,"pass2_50kHz_0_20fm");
push(@passes,"pass3trk");
push(@passes,"pass3trk_50kHz_0_20fm");
push(@passes,"pass3calo");
push(@passes,"pass3calo_50kHz_0_20fm");
push(@passes,"pass4trk");

foreach my $fm (sort @fmrange)
{
    foreach my $pass (sort @passes)
    {
	$condorlogs{sprintf("/tmp/%s/%s",$fm,$pass)} = sprintf("%s/%s/%s/condor/log",$submitdir,$fm,$pass);

    }
}

foreach my $condorlogdir (sort keys %condorlogs)
{
    if (-d $condorlogdir && -d $condorlogs{$condorlogdir})
    {
	my $rsynccmd = sprintf("rsync -av %s %s",$condorlogdir, $condorlogs{$condorlogdir});
	print "cmd: $rsynccmd\n";
	system($rsynccmd);
    }
}
