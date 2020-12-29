#include <sstream>

#include "Pythia8/FJcore.h"
#include "Pythia8/Pythia.h"
#include "Pythia8Plugins/HepMC2.h"

using namespace Pythia8;

int main(int argc, char *argv[]) {

  if (argc != 7) {

    std::cout << " usage: ./eventgen MODE PTHATMIN PTMIN NEVT FILENAMEOUT SEED" << std::endl;

    return 0;
  }

  // Generator. Process selection. LHC initialization. Histogram.
  Pythia pythia;

  int MODE = atoi( argv[1] );

  pythia.readString("Beams:eCM = 200.");
  if ( MODE == 0 ) pythia.readString("SoftQCD:all  = on");
  if ( MODE == 1 ) pythia.readString("HardQCD:all  = on");
  if ( MODE == 2 ) pythia.readString("PromptPhoton:all  = on");
  pythia.readString("Random:setSeed = on");


  if ( MODE > 0 ) // only set pThatmin for the hard processes
  {
    ostringstream ss; ss << "PhaseSpace:pTHatMin = " << argv[2] << ".";
    pythia.readString( ss.str().c_str() );
  }

  float ptmin = 0;
  if ( MODE > 0 ) {
    ptmin = atof( argv[3] );
  }

  int NEVT = atoi( argv[4] );

  HepMC::IO_GenEvent ascii_io( argv[5], std::ios::out );

  {
    ostringstream ss; ss << "Random:seed = " << argv[6] << ".";
    pythia.readString( ss.str().c_str() );
  }

  pythia.init();
  
  HepMC::Pythia8ToHepMC ToHepMC;

  SlowJet *antikT4 = new SlowJet(-1,0.4,10,5,2,1); 

  int nevt_written = 0;
  
  for (int iEvent = 0; iEvent < 1000000; ++iEvent) {
    if ( nevt_written == NEVT ) break;

    if (!pythia.next()) continue;

    antikT4->analyze(pythia.event);

    if ( iEvent % 1000 == 0 ) std::cout << iEvent << " events samples, " <<  nevt_written << " events written" << std::endl;

    bool write_event = false;

    if ( MODE == 0 ) {
      
      std::cout << " trigger on minimum bias event" << std::endl;
      write_event = true;

    } else if ( MODE == 1 ) {
      
      for (int i = 0; i < antikT4->sizeJet(); i++) {

	if (  antikT4->pT(i) > ptmin && fabs( antikT4->p(i).eta() ) < 1.1 ) {
	  std::cout << " trigger on R=0.4 jet pT = " << antikT4->pT(i) << ", eta = " << antikT4->p(i).eta() << std::endl;
	  write_event = true;
	  break;
	}
	
      }

    } else if ( MODE == 2 ) {

      for (int i = 0; i < pythia.event.size(); ++i) {
	if (!pythia.event[i].isFinal()) continue;
	if ( pythia.event[i].id() != 22) continue;

	if (pythia.event[i].pT() > ptmin && fabs( pythia.event[i].eta() ) < 1.1 ) {
	  std::cout << " trigger on photon pT = " << pythia.event[i].pT() << ", eta = " <<  pythia.event[i].eta() << std::endl;
	  write_event = true;
	  break;
	  
	}
	
      }
      
    }

    if ( write_event ) {
      std::cout << " filling event #" << nevt_written << ", events tried = " << iEvent << ", target # of events: " << NEVT << std::endl;

      HepMC::GenEvent* hepmcevt = new HepMC::GenEvent();
      ToHepMC.fill_next_event( pythia, hepmcevt );
      
      // Write the HepMC event to file. Done with it.                                                                                              
      ascii_io << hepmcevt;
      delete hepmcevt;

      nevt_written++;
    }


  }
  pythia.stat();
  
  return 0;
}
