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

#my $cmd = sprintf("cat %s/condor-0000000001-19*.log | grep 'Run Remote Usage' | awk '{print \$3}' | awk -F, '{print \$1}' > time",$logdir);
my $cmd = sprintf("find %s/ -name '*.log' |",$logdir);

my $runremlist = "runremote.list";

if (-f $runremlist)
{
    unlink $runremlist;
}

if (! -f $runremlist)
{
#    unlink $runremlist;


    open(F,"$cmd");
    open(F2,">$runremlist");
    while (my $file = <F>)
    {
	print "file: $file";
	chomp $file;
	my $fcmd = sprintf("cat %s | grep 'Run Remote Usage' | ",$file);
	open(F1,$fcmd);
	while (my $remline = <F1>)
	{
	    print F2 "$remline";
	}
	close(F1);
    }
    close(F);
    close(F2);
}

open(F,"$runremlist");
open(F1,">seconds.list");
while (my $line = <F>)
{
    chomp $line;
    $line =~ s/,//g;
    $line =~ s/\s+/ /g;
    $line =~ s/^\s+//;
    my @sp = split(/ /,$line);
    my $day = $sp[1]*24*3600;
    my @sp1 = split(/:/,$sp[2]);
    my $hour = $sp1[0]*3600;
    my $min = $sp1[1]*60;
    my $sec = $sp1[2];
    my $total = $day+$hour+$min+$sec;
#    print "$line is day: $sp[1], hours: $sp1[0], min: $sp1[1], sec: $sp1[2]\n"; 
    print F1 "$total\n";
}
close(F);
close(F1);

$cmd = sprintf("root.exe plottime.C\\(\\\"seconds.list\\\"\\)");

print "$cmd\n";

system($cmd);


