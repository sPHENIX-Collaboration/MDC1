#!/usr/bin/bash
source /opt/sphenix/core/bin/sphenix_setup.sh -n
# arguments 
# $1: number of events
# $2: hepmc input file
# $3: output file
# $4: no events to skip

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(g4hits file\): $2
echo arg3 \(output file\): $3
echo arg4 \(skip\): $4
echo arg5 \(output dir\): $5
echo running root.exe -q -b Fun4All_G4_Pass2.C\($1,\"$2\",\"$3\",\"\",$4,\"$5\"\)
root.exe -q -b  Fun4All_G4_Pass2.C\($1,\"$2\",\"$3\",\"\",$4,\"$5\"\)
echo "script done"
