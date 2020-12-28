# Reminder of usage:
# ./eventgen MODE PTHATMIN PTMIN NEVT FILENAMEOUT SEED

# below, the random seed is set to "17" each time just for
# illustrative purposes - you can set this to the sequence number for
# example

# generate 50 minimum bias events
./eventgen 0  0  0 50 output/MB_nevt50.hepmc 17

# generate 50 QCD events with pThatmin = 30 GeV that have a >40 GeV
# R=0.4 jet within |eta| < 1.1
./eventgen 1 30 40 50 output/jet40_nevt50.hepmc 17

# generate 50 gamma+jet events with pThatmin = 25 GeV that have a >30
# GeV photon within |eta| < 1.1
./eventgen 1 25 30 50 output/photon30_nevt50.hepmc 17

