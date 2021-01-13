#!/usr/bin/bash
export HOME=/sphenix/u/${LOGNAME}
source /opt/sphenix/core/bin/sphenix_setup.sh -n mdc1.4

echo running: run_hfprod.sh $*

# arguments 
# $1: number of events
# $2: charm or bottom production
# $3: output file
# $4: no events to skip
# $5: output dir

echo 'here comes your environment'
#printenv
echo arg1 \(events\) : $1
echo arg2 \(charm or bottom\): $2
echo arg3 \(output file\): $3
echo arg5 \(skip\): $4
echo arg6 \(output dir\): $5
echo running root.exe -q -b Fun4All_G4_HF_pp_signal.C\($1,\"$2\",\"$3\",\"\",$4,\"$5\"\)
root.exe -q -b Fun4All_G4_HF_pp_signal.C\($1,\"$2\",\"$3\",\"\",$4,\"$5\"\)
echo "script done"
