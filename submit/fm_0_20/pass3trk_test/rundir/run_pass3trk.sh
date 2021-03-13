#!/usr/bin/bash

export HOME=/sphenix/u/${LOGNAME}

source /opt/sphenix/core/bin/sphenix_setup.sh -n mdc1.5

echo running: run_pass3trk.sh $*

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av /sphenix/u/sphnxpro/MDC1/submit/fm_0_20/pass3trk/rundir/* .
    getinputfiles.pl $2
    if [ $? -ne 0 ]
    then
	echo error from getinputfiles.pl $2, exiting
	exit -1
    fi
    getinputfiles.pl $3
    if [ $? -ne 0 ]
    then
	echo error from getinputfiles.pl $2, exiting
	exit -1
    fi
else
    echo condor scratch NOT set
fi

# arguments 
# $1: number of events
# $2: track g4hits input file
# $3: truth g4hits input file
# $4: output file
# $5: output dir

echo 'here comes your environment'
printenv
echo arg1 \(events\) : $1
echo arg2 \(track g4hits file\): $2
echo arg3 \(truth g4hits file\): $3
echo arg4 \(output file\): $4
echo arg5 \(output dir\): $5
echo running root.exe -q -b Fun4All_G4_TrkrPrePass.C\($1,\"$2\",\"$3\",\"$4\",\"$5\"\)
root.exe -q -b  Fun4All_G4_TrkrPrePass.C\($1,\"$2\",\"$3\",\"$4\",\"$5\"\)
echo "script done"
