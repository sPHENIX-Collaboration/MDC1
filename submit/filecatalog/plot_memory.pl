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

my $cmd = sprintf("cat %s/*.log | grep 'Memory (MB)          :' | awk '{print \$4}' | sort -n > memory",$logdir);

print "$cmd\n";

system($cmd);

$cmd = sprintf("root.exe plotmem.C\\(\\\"memory\\\"\\)");

print "$cmd\n";

system($cmd);
