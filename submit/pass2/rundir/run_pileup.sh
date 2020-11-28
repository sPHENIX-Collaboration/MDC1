#!/usr/bin/bash
source /opt/sphenix/core/bin/sphenix_setup.sh -n mdc1

# arguments 
# $1: number of input events
# $2: number of output events
# $3: input file
# $4: output directory

echo 'here comes your environment'
printenv
echo arg1 \(input events\) : $1
echo arg2 \(output events\) : $2
echo arg3 \(input file\): $3
echo arg4 \(output dir\): $4
echo running root.exe -q -b Fun4All_G4_Pileup.C\($1,$2,\"$3\",\"$4\"\)
root.exe -q -b  Fun4All_G4_Pileup.C\($1,$2,\"$3\",\"$4\"\)
echo "script done"
