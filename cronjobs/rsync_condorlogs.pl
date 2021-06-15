#!/usr/bin/perl

use strict;
use warnings;

sub dir_is_empty;

my $submitdir = "/sphenix/u/sphnxpro/MDC1/submit";
my %condorlogs = ();
my @fmrange = ();
push(@fmrange,"fm_0_488");
push(@fmrange,"fm_0_12");
push(@fmrange,"fm_0_20");
push(@fmrange,"HF_pp200_signal");
push(@fmrange,"pythia8_pp_mb");
push(@fmrange,"FixDST");


my @passes = ();
push(@passes,"pass1");
push(@passes,"pass2");
push(@passes,"pass2_50kHz_0_20fm");
push(@passes,"pass3trk");
push(@passes,"pass3trk_test");
push(@passes,"pass3trk_50kHz_0_20fm");
push(@passes,"pass3calo");
push(@passes,"pass3calo_50kHz_0_20fm");
push(@passes,"pass4trk");
push(@passes,"pass4trk_50kHz_0_20fm");
push(@passes,"pass5trk");
push(@passes,"hwpass1");
# for FixDST
my @FixDSTpasses = ();
push(@FixDSTpasses,"HF_pp200_signal");
push(@FixDSTpasses,"fm_0_20");

foreach my $fm (sort @fmrange)
{
    if ($fm eq "HF_pp200_signal")
    {
	$condorlogs{sprintf("/tmp/%s",$fm)} = sprintf("%s/%s/condor/log",$submitdir,$fm);
    }
    elsif ($fm eq "FixDST")
    {
	foreach my $fixpass (sort @FixDSTpasses)
	{
	    if ($fixpass eq "HF_pp200_signal")
	    {
		$condorlogs{sprintf("/tmp/%s",$fm)} = sprintf("%s/%s/%s/condor/log",$submitdir,$fm,$fixpass);
	    }

	    foreach my $pass (sort @passes)
	    {

		$condorlogs{sprintf("/tmp/%s/%s/%s",$fm,$fixpass,$pass)} = sprintf("%s/%s/%s/%s/condor/log",$submitdir,$fm,$fixpass,$pass);

	    }
	}
    }
    else
    {
	foreach my $pass (sort @passes)
	{
	    $condorlogs{sprintf("/tmp/%s/%s",$fm,$pass)} = sprintf("%s/%s/%s/condor/log",$submitdir,$fm,$pass);

	}
    }
}

foreach my $condorlogdir (sort keys %condorlogs)
{
    print "checking $condorlogdir and $condorlogs{$condorlogdir}\n";
    if (-d $condorlogdir && -d $condorlogs{$condorlogdir})
    {
	if (&dir_is_empty($condorlogdir) == 1)
	{
	    my $rsynccmd = sprintf("rsync -av %s/* %s",$condorlogdir, $condorlogs{$condorlogdir});
	    print "cmd: $rsynccmd\n";
	    system($rsynccmd);
	}
	else
	{
	    print "$condorlogdir is empty\n";
	}
    }
}

sub dir_is_empty
{
    my $dirname = $_[0];
    my $iret = 0;
    opendir my $dir, $dirname or die $!;
    if( grep ! /^\.\.?$/, readdir $dir )
    {
	$iret = 1;
    }
    closedir($dir);
    return $iret;
}
