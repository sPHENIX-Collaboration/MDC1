#!/usr/bin/bash
export HOME=/sphenix/u/${LOGNAME}
source /opt/sphenix/core/bin/sphenix_setup.sh -n ana.241
source /opt/sphenix/core/bin/setup_local.sh /opt/sphenix/core/FixDST/pass1/install

echo running: run_fixdst.sh $*

if [[ ! -z "$_CONDOR_SCRATCH_DIR" && -d $_CONDOR_SCRATCH_DIR ]]
then
    cd $_CONDOR_SCRATCH_DIR
#    rsync -av /sphenix/u/sphnxpro/MDC1/submit/FixDST/fm_0_20/pass3trk/rundir/* .
    rsync -av /sphenix/user/pinkenbu/MDC1/submit/FixDST/fm_0_20/pass4trk/rundir/* .
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
# $1: number of events
# $2: output file
# $3: output dir

echo 'here comes your environment'
printenv
echo arg1 \(input DST\) : $1
echo running root.exe -q -b run_pass1.C\(\"$1\"\)
root.exe -q -b run_pass1.C\(\"$1\"\)
echo "pass1 done"

if [[ ! -f "pass1out.root" ]]
then
 echo "pass1out.root missing"
 exit 1
fi

source /opt/sphenix/core/bin/sphenix_setup.sh -n ana.250
source /opt/sphenix/core/bin/setup_local.sh /opt/sphenix/core/FixDST/pass2/install

echo running root.exe -q -b run_pass2.C\(\"pass1out.root\",\"$2\",\"$3\"\)
root.exe -q -b run_pass2.C\(\"pass1out.root\",\"$2\",\"$3\"\)
echo "pass2 done"
