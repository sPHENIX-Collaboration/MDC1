#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my $count;

GetOptions("cnt:i"=>\$count);

if ($#ARGV < 0)
{
    print "usage: plot_memory.pl <condor logdir>\n";
    print "-cnt : max number of condor logs to analyze\n";
    exit(1);
}

my $logdir = $ARGV[0]; 

if (! -d $logdir)
{
    print "$logdir does not exist\n";
    exit(2);
}

#my $cmd = sprintf("cat %s/*.log | grep 'Memory (MB)          :' | awk '{print \$4}' | sort -n > memory",$logdir);

my $cmd = sprintf("find %s/ -name '*.log' |",$logdir);

my $runremlist = "memory.list";

if (-f $runremlist)
{
    unlink $runremlist;
}
my $cnt = 0;
open(F2,">$runremlist");
open(F,"$cmd");
while (my $file = <F>)
{
    print "file: $file";
    chomp $file;
    my $fcmd = sprintf("cat %s | grep 'Memory (MB)' | awk '{print \$4}' | ",$file);
    open(F1,$fcmd);
    while (my $remline = <F1>)
    {
	print F2 "$remline";
    }
    close(F1);
    $cnt++;
    if (defined $count &&  $cnt >= $count)
    {
	last;
    }
}
close(F);
close(F2);

$cmd = sprintf("root.exe plotmem.C\\(\\\"memory.list\\\"\\)");

print "$cmd\n";

system($cmd);
