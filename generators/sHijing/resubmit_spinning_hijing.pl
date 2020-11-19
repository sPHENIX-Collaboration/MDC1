#!usr/bin/perl

use strict;
use File::Path;
use Getopt::Long;


my $submit;
GetOptions("submit"=>\$submit);

if ($#ARGV < 0)
{
    print "usage resubmit_spinning_hijing.pl <condor id>\n";
    print "parameters:\n";
    print "-submit : submit the job\n";
    exit(0);
}
my $condorid = $ARGV[0];

my $condorlogdir = "/tmp/mdc1";
my $condoroutdir = "/sphenix/sim/sim01/sphnxpro/MDC1/sHijing_HepMC/log";
my $outputdir = sprintf("/sphenix/sim/sim01/sphnxpro/MDC1/sHijing_HepMC/data");
my $maxnum=hex('0xFFFFFFFF');

open(F,"find $condoroutdir -maxdepth 1 -type f -name '*.out' | sort |");
my %used_seeds = ();
while (my $file = <F>)
{
    chomp $file;
    open(F1,"$file");
    while (my $line = <F1>)
    {
	chomp $line;
	if ($line =~ /seed:/)
	{
#	    print "$line\n";
	    my @sp1 = split(/ /,$line);
#	    print "seed = $sp1[1]\n";
	    $used_seeds{$sp1[1]} = 1;
	    last;
	}
    }
    close(F1);
}
close(F);

my $seed_ok = 0;
my $newseed;
while ($seed_ok == 0)
{
    $newseed = int(rand($maxnum));
    if (! exists $used_seeds{$newseed})
    {
	$seed_ok = 1;
    }
}

my $condorlog;
my $condorout;
my $condorerr;
my $arguments = "";
open(F,"condor_q -long $condorid |");
while (my $line = <F>)
{
    chomp $line;
#    print "$line";
    if ($line =~ /UserLog/)
    {
	my @sp1 = split(/ /,$line);
	$sp1[2] =~ s/\"//g;
	$condorlog = $sp1[2];
	print "userlog: $condorlog\n";
	if (! -f $condorlog)
	{
	    print "could not find condorlog $condorlog\n";
	    die;
	}
    }
    if ($line =~ /Out =/ && $line =~ /sphenix/)
    {
	my @sp1 = split(/ /,$line);
	$sp1[2] =~ s/\"//g;
	$condorout = $sp1[2];
	print "out: $condorout\n";
	if (! -f $condorout)
	{
	    print "could not find condorout $condorout\n";
	    die;
	}
    }
    if ($line =~ /Err =/ && $line =~ /sphenix/)
    {
	my @sp1 = split(/ /,$line);
	$sp1[2] =~ s/\"//g;
	$condorerr = $sp1[2];
	print "err: $condorerr\n";
	if (! -f $condorerr)
	{
	    print "could not find condorlog $condorerr\n";
	    die;
	}
    }
    if ($line =~ /Args =/)
    {
	$line =~ s/\"//g;
	my @sp1 = split(/ /,$line);
	for (my $i=2; $i<=$#sp1; $i++)
	{
	    if ($i == 3)
	    {
		$sp1[$i]= $newseed;
	    }
	    $arguments = sprintf("%s %s",$arguments,$sp1[$i]);
	}
	print "arguments: $arguments\n";

    }
}
close(F);
if (! defined $condorout)
{
    print "cannot find condor job $condorid\n";
    exit(1);
}
my $subcmd = sprintf("condor_submit condor.job -a \"output = %s\" -a \"error = %s\"  -a \"Log = %s\" -a \"Arguments = %s\"",$condorout,$condorerr, $condorlog,$arguments);
if (defined $submit)
{
    my $rmcmd = sprintf("condor_rm %s",$condorid);
    print "running $rmcmd\n";
    system($rmcmd);
    print "running $subcmd\n";
    system($subcmd);
}
else
{
    print "would run $subcmd\n";
}
