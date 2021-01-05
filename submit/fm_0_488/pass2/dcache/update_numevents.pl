#!/usr/bin/perl

use DBI;
use strict;
use warnings;
use File::Path;
use File::Basename;

sub getentries;
#write stupid macro to get events
open(F,">GetEntries.C");
print F "#ifndef MACRO_GETENTRIES_C\n";
print F "#define MACRO_GETENTRIES_C\n";
print F "#include <frog/FROG.h>\n";
print F "R__LOAD_LIBRARY(libFROG.so)\n";
print F "void GetEntries(const std::string &file)\n";
print F "{\n";
print F "  gSystem->Load(\"libFROG.so\");\n";
print F "  gSystem->Load(\"libg4dst.so\");\n";
print F "  // prevent root to start gdb-backtrace.sh\n";
print F "  // in case of crashes, it hangs the condor job\n";
print F "  for (int i = 0; i < kMAXSIGNALS; i++)\n";
print F "  {\n";
print F "     gSystem->IgnoreSignal((ESignals)i);\n";
print F "  }\n";
print F "  FROG *fr = new FROG();\n";
print F "  TFile *f = TFile::Open(fr->location(file));\n";
print F "  cout << \"Getting events for \" << file << endl;\n";
print F "  TTree *T = (TTree *) f->Get(\"T\");\n";
print F "  cout << \"Number of Entries: \" <<  T->GetEntries() << endl;\n";
print F "}\n";
print F "#endif\n";
close(F);

# first go over files in our gpfs output dir
my $indirfile = "../condor/outdir.txt";
if (! -f $indirfile)
{
    die "could not find $indirfile";
}
my $indir = `cat $indirfile`;
chomp $indir;
my $dbh = DBI->connect("dbi:ODBC:FileCatalog","phnxrc") || die $DBI::error;
$dbh->{LongReadLen}=2000; # full file paths need to fit in here
my $chkfile = $dbh->prepare("select events from datasets where filename = ?");
my $updateevents =  $dbh->prepare("update datasets set events=? where filename=?") || die $DBI::error;

open(F,"find $indir -maxdepth 1 -type f -name '*.root' | sort|");
while (my $file = <F>)
{
    chomp $file;
    my $filename = basename($file);
    $chkfile->execute($filename);
    if ($chkfile->rows > 0)
    {
	my @res = $chkfile->fetchrow_array();
	if ($res[0] < 0)
	{
	    my $entries = getentries($file);
	    if ($entries >= 0)
	    {
		print "updating $filename with $entries\n";
		$updateevents->execute($entries,$filename) || die $DBI::error;
	    }
	}
    }
}
#die;


my $getfiles = $dbh->prepare("select filename from datasets where (dsttype = 'DST_BBC_G4HIT' or dsttype ='DST_CALO_G4HIT' or dsttype ='DST_TRKR_G4HIT' or dsttype = 'DST_TRUTH_G4HIT' or dsttype ='DST_VERTEX') and (events is null or events < 0) order by filename") || die $DBI::error;

$getfiles->execute() || die $DBI::error;
while (my @res = $getfiles->fetchrow_array())
{
    my $file = $res[0];
    my $entries = getentries($file);
    if ($entries >= 0)
    {
	print "updating dcache $file with $entries\n";
	$updateevents->execute($entries,$file);
    }
}

$chkfile->finish();
$getfiles->finish();
$updateevents->finish();
$dbh->disconnect;

sub getentries
{
    my $file = $_[0];
    open(F2,"root.exe -q -b GetEntries.C\\(\\\"$file\\\"\\) 2>&1 |");
    my $checknow = 0;
    my $entries = -2;
    while(my $entr = <F2>)
    {
	chomp $entr;
#	print "$entr\n";
	if ($entr =~ /$file/)
	{
	    $checknow = 1;
	    next;
	}
	if ($checknow == 1)
	{
	    if ($entr =~ /Number of Entries/)
	    {
		my @sp1 = split(/:/,$entr);
		$entries = $sp1[$#sp1];
	        $entries =~ s/ //g; #just to be safe, strip empty spaces 
		last;
	    }
	}
    }
    close(F2);
    print "file $file, entries: $entries\n";
    return $entries;
}
