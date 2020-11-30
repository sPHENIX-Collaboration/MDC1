#!/usr/bin/bash
source /opt/sphenix/core/bin/sphenix_setup.sh -n mdc1
# arguments 
# $1: number of events
# $2: calo g4hits input file
# $3: output file
# $4: output dir

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(calo g4hits file\): $2
echo arg3 \(output file\): $3
echo arg4 \(output dir\): $4
echo running root.exe -q -b Fun4All_G4_Calo.C\($1,\"$2\",\"$3\",\"$4\"\)
root.exe -q -b  Fun4All_G4_Calo.C\($1,\"$2\",\"$3\",\"$4\"\)
echo "script done"
