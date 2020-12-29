#!usr/bin/perl

use strict;
use File::Path;
use Getopt::Long;

my $submit;
GetOptions("submit"=>\$submit);

my $runnumber = 1;
my $evt_per_file = 100000;
my $total_events = 10000000;
my $condorlogdir = "/tmp/mdc1/pythia8hepmc";
my $condoroutdir = "/sphenix/sim/sim01/sphnxpro/MDC1/pythia8_HepMC/log";
my $outputdir = sprintf("/sphenix/sim/sim01/sphnxpro/MDC1/pythia8_HepMC/data");
mkpath($condorlogdir);
mkpath($condoroutdir);
mkpath($outputdir);
my $maxnum=hex('0xFFFFFFFF');
my %used_seed = ();

while ((keys %used_seed) < $total_events/$evt_per_file)
{
    $used_seed{int(rand($maxnum))} = 1;
}
my $nseeds = keys %used_seed;
my $segment = 0;
foreach my $seed (keys %used_seed)
{
    my $condorlog = sprintf("%s/pythia8_mb-%010d-%05d.log", $condorlogdir,$runnumber,$segment);
    my $condorout = sprintf("%s/pythia8_mb-%010d-%05d.out",$condoroutdir,$runnumber,$segment);
    my $condorerr = sprintf("%s/pythia8_mb-%010d-%05d.err",$condoroutdir,$runnumber,$segment);
    my $datfile = sprintf("pythia8_mb-%010d-%05d.dat",$runnumber, $segment);
    my $condorcmd = sprintf("condor_submit condor.job -a \"output = %s\" -a \"error = %s\"  -a \"Log = %s\" -a \"Arguments = %d %s %d %s\"",$condorout, $condorerr, $condorlog, $evt_per_file, $datfile, $seed, $outputdir);
    $segment++;
    if (! defined $submit)
    {
	print "would issue $condorcmd\n";
    }
    else
    {
	print "$condorcmd\n";
	system($condorcmd);
    }
}
if (! defined $submit)
{
    print "\n\nuse perl run_pythia8.pl -submit to submit condor jobs\n\n";
}
