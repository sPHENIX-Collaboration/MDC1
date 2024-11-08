#!/usr/bin/bash

export HOME=/sphenix/u/${LOGNAME}

source /opt/sphenix/core/bin/sphenix_setup.sh -n mdc1.8

echo running: run_hepmc_pp.sh $*

# arguments 
# $1: number of events
# $2: hepmc input file
# $3: output file
# $4: no events to skip

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(hepmc file\): $2
echo arg3 \(output file\): $3
echo arg5 \(skip\): $4
echo arg6 \(output dir\): $5
echo running root.exe -q -b Fun4All_G4_Pass1_pp.C\($1,\"$2\",\"$3\",\"\",$4,\"$5\"\)
root.exe -q -b  Fun4All_G4_Pass1_pp.C\($1,\"$2\",\"$3\",\"\",$4,\"$5\"\)
echo "script done"
