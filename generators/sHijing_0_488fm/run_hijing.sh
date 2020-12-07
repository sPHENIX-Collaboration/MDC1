#!/usr/bin/bash

source /opt/sphenix/core/bin/sphenix_setup.sh -n

# arguments 
# $1: number of events
# $2: seed
# $3: output file
# $4: output dir

echo number of events \(arg1\): $1
echo seed \(arg2\): $2
echo output file \(arg3\): $3
echo output dir \(arg4\): $4

echo running sHijing -n $1 -s $2 -o $3  /cvmfs/sphenix.sdcc.bnl.gov/gcc-8.3/MDC/MDC1/generators/sHijing/sHijing_0_488fm.xml
if [[ ! -f /cvmfs/sphenix.sdcc.bnl.gov/gcc-8.3/MDC/MDC1/generators/sHijing/sHijing_0_488fm.xml ]]
then
echo could not find /cvmfs/sphenix.sdcc.bnl.gov/gcc-8.3/MDC/MDC1/generators/sHijing/sHijing_0_488fm.xml
exit 1
fi
if [[ -d $_CONDOR_SCRATCH_DIR ]]
then
  cd $_CONDOR_SCRATCH_DIR
fi
sHijing -n $1 -s $2 -o $3 /cvmfs/sphenix.sdcc.bnl.gov/gcc-8.3/MDC/MDC1/generators/sHijing/sHijing_0_488fm.xml
rsync -av $3 $4
