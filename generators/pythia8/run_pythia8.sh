#!/usr/bin/bash

source /opt/sphenix/core/bin/sphenix_setup.sh -n mdc1.3

echo running: run_pythia8.sh $*

# arguments 
# $1: number of events
# $2: seed
# $3: output file
# $4: output dir

echo 'here comes your environment'
printenv

echo number of events \(arg1\): $1
echo output file \(arg2\): $2
echo seed \(arg3\): $3
echo output dir \(arg4\): $4

echo running /sphenix/u/sphnxpro/MDC1/generators/pythia8/eventgen 0 0 0 $1 $2 $3
if [[ -d $_CONDOR_SCRATCH_DIR ]]
then
  cd $_CONDOR_SCRATCH_DIR
fi
/sphenix/u/sphnxpro/MDC1/generators/pythia8/eventgen 0 0 0 $1 $2 $3
rsync -av $2 $4
