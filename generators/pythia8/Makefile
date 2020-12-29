all: eventgen

clean: 
	rm eventgen


HEPMC = /cvmfs/sphenix.sdcc.bnl.gov/gcc-8.3/opt/sphenix/core/HepMC-2.06.09
PYTHIA = /cvmfs/sphenix.sdcc.bnl.gov/gcc-8.3/opt/sphenix/core/pythia8303

eventgen: eventgen.cc
	g++ eventgen.cc $(PYTHIA)/lib/libpythia8.a -L$(HEPMC)/lib -o eventgen -I$(PYTHIA)/include -I$(HEPMC)/include -O2 -ansi -pedantic -W -Wall -Wshadow -std=c++11 -fPIC -Wl,-rpath,$(PYTHIA)/lib/libpythia8.a,$(HEPMC)/lib/libHepMC.so -ldl -lHepMC -lz
