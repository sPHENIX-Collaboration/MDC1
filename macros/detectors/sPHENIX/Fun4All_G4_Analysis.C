// these include guards are not really needed, but if we ever include this
// file somewhere they would be missed and we will have to refurbish all macros
#ifndef MACRO_FUN4ALLANALYSIS_C
#define MACRO_FUN4ALLANALYSIS_C

#include <fun4all/Fun4AllInputManager.h>
#include <fun4all/Fun4AllDstInputManager.h>
#include <fun4all/Fun4AllServer.h>

R__LOAD_LIBRARY(libfun4all.so)

void Fun4All_G4_Analysis(
    const int nEvents = 1,
    const string &inputFileTracks = "DST_TRACKS_sHijing_0_12fm-0000000001-00000.root",
    const string &inputFileClusters = "DST_CALO_CLUSTER_sHijing_0_12fm-0000000001-00000.root"
)
{
// this convenience library knows all our i/o objects so you don't
// have to figure out what is in each dst type 
  gSystem->Load("libg4dst.so");
  Fun4AllServer *se = Fun4AllServer::instance();
  se->Verbosity(1);

// here you create and register your analysis module like:
// MyModule *mod = new MyModule();
//  se->registerSubsystem(mod);


   Fun4AllInputManager *in = new Fun4AllDstInputManager("DSTTrks");
   in->fileopen(inputFileTracks);
   se->registerInputManager(in);

   in = new Fun4AllDstInputManager("DSTClusters");
   in->fileopen(inputFileClusters);
   se->registerInputManager(in);

   se->run(nEvents);
   se->End();
   delete se;
   gSystem->Exit(0);
}

#endif //MACRO_FUN4ALLANALYSIS_C
