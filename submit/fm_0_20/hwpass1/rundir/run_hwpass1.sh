#!/usr/bin/bash
export HOME=/sphenix/u/${LOGNAME}
source /opt/sphenix/core/bin/sphenix_setup.sh -n ana.254

echo running: run_hwpass1.sh $*

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
    rsync -av /sphenix/u/sphnxpro/MDC1/submit/fm_0_20/hwpass1/rundir/* .
#    rsync -av /sphenix/user/pinkenbu/MDC1/submit/fm_0_20/hwpass1/rundir/* .

    getinputfiles.pl $1
    if [ $? -ne 0 ]
    then
	echo error from getinputfiles.pl $1, exiting
	exit -1
    fi
else
    echo condor scratch NOT set
fi
# arguments 
# $1: input file
# $2: output file
# $3: residual file
# $4: output dir

echo 'here comes your environment'
printenv
echo arg1 \(input DST\) : $1
echo arg2 \(output DST\) : $2
echo arg3 \(residual file\) : $3
echo arg4 \(output dir\) : $4

echo running root.exe -q -b Fun4All_G4_sPHENIX_HWTest_pass1.C\(0,\"$1\",\"$2\",\"$3\",\"$4\"\)
root.exe -q -b Fun4All_G4_sPHENIX_HWTest_pass1.C\(0,\"$1\"\,\"$2\",\"$3\",\"$4\"\)

