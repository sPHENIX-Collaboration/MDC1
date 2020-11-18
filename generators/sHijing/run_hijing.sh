#!/usr/bin/bash

source /opt/sphenix/core/bin/sphenix_setup.sh -n

# arguments 
# $1: number of events
# $2: seed
# $3: output file
# $4: output dir

echo running sHijing -n $1 -s $2 -o $3  /cvmfs/sphenix.sdcc.bnl.gov/gcc-8.3/MDC/MDC1/generators/sHijing/sHijing_0-12fm.xml
if [[ -d $_CONDOR_SCRATCH_DIR ]]
then
  cd $_CONDOR_SCRATCH_DIR
fi
sHijing -n $1 -s $2 -o $3 /cvmfs/sphenix.sdcc.bnl.gov/gcc-8.3/MDC/MDC1/generators/sHijing/sHijing_0-12fm.xml
rsync -av $3 $4
