#!/usr/bin/bash
export HOME=/sphenix/u/${LOGNAME}
source /opt/sphenix/core/bin/sphenix_setup.sh -n mdc1.6

echo running: run_pass4trk.sh $*

# arguments 
# $1: number of events
# $2: truth input file
# $3: trkr cluster input file
# $4: output file
# $5: output dir

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(truth input file\): $2
echo arg3 \(trkr cluster input file\): $2
echo arg4 \(output file\): $3
echo arg5 \(output dir\): $4
echo running root.exe -q -b Fun4All_G4_Trkr.C\($1,\"$2\",\"$3\",\"$4\",\"$5\"\)
root.exe -q -b  Fun4All_G4_Trkr.C\($1,\"$2\",\"$3\",\"$4\",\"$5\"\)
echo "script done"
