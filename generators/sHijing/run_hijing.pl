#!usr/bin/perl
#perl -V:randbits
use strict;
use File::Path;

my $evt_per_file = 10000;
my $total_events = 10000000;
my $condorlogdir = "/tmp/mdc1";
my $condoroutdir = "/sphenix/sim/sim01/sphnxpro/MDC1/log";
my $outputdir = sprintf("/sphenix/sim/sim01/sphnxpro/MDC1/sHijing_HepMC");
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
print "$maxnum, seeds : $nseeds\n";
my $segment = 0;
foreach my $seed (keys %used_seed)
{
    my $condorlog = sprintf("%s/sHijing_0-12fm_%05d.log",$condorlogdir,$segment);
    my $condorout = sprintf("%s/sHijing_0-12fm_%05d.out",$condoroutdir,$segment);
    my $condorerr = sprintf("%s/sHijing_0-12fm_%05d.err",$condoroutdir,$segment);
    my $datfile = sprintf("sHijing_0-12fm_%05d.dat",$segment);
    my $condorcmd = sprintf("condor_submit condor.job -a \"output = %s\" -a \"error = %s\"  -a \"Log = %s\" -a \"Arguments = %d %d %s %s\"",$condorout, $condorerr, $condorlog,$evt_per_file, $seed, $datfile, $outputdir);
    $segment++;
    print "$condorcmd\n";
    system($condorcmd);
}
