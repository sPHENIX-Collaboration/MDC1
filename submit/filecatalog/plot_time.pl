#!/usr/bin/perl

use strict;
use warnings;

if ($#ARGV < 0)
{
    print "usage: plot_memory.pl <condor logdir>\n";
    exit(1);
}

my $logdir = $ARGV[0]; 

if (! -d $logdir)
{
    print "$logdir does not exist\n";
    exit(2);
}

my $cmd = sprintf("cat %s/*.log | grep 'Run Remote Usage' | awk '{print \$3}' | awk -F, '{print \$1}' > time",$logdir);

print "$cmd\n";

system($cmd);

open(F,"time");
open(F1,">seconds.list");
while (my $line = <F>)
{
    chomp $line;
    my @sp1 = split(/:/,$line);
    my $hour = $sp1[0]*3600;
    my $min = $sp1[1]*60;
    my $sec = $sp1[2];
    my $total = $hour+$min+$sec;
    print F1 "$total\n";
}
close(F);
close(F1);

$cmd = sprintf("root.exe plottime.C\\(\\\"seconds.list\\\"\\)");

print "$cmd\n";

system($cmd);


