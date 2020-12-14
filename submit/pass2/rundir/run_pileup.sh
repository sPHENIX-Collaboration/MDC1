#!/usr/bin/bash
export HOME=/sphenix/u/${LOGNAME}
source /opt/sphenix/core/bin/sphenix_setup.sh -n mdc1.2

echo running: run_pileup.sh $*

# arguments 
# $1: number of output events
# $2: input file
# $3: background listfile
# $4: output directory

echo 'here comes your environment'
printenv
echo arg1 \(output events\) : $1
echo arg2 \(input file\): $2
echo arg3 \(background listfile\): $3
echo arg4 \(output dir\): $4
echo running root.exe -q -b Fun4All_G4_Pileup.C\($1,\"$2\",\"$3\",\"$4\"\)
root.exe -q -b  Fun4All_G4_Pileup.C\($1,\"$2\",\"$3\",\"$4\"\)
echo "script done"
