#ifndef MACRO_FUN4ALLG4PILEUP_C
#define MACRO_FUN4ALLG4PILEUP_C

#include <GlobalVariables.C>

#include <G4_OutputManager_Pileup.C>
#include <G4_Production.C>
#include <G4_Global.C>

#include <fun4all/Fun4AllDstOutputManager.h>
#include <fun4all/Fun4AllServer.h>
#include <fun4all/SubsysReco.h>
#include <fun4all/Fun4AllUtils.h>

#include <g4main/Fun4AllDstPileupInputManager.h>
#include <g4main/PHG4VertexSelection.h>
#include <phool/recoConsts.h>

R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libg4eval.so)
R__LOAD_LIBRARY(libg4testbench.so)

//________________________________________________________________________________________________
int Fun4All_G4_Pileup(
    const int nInputEvents = 100,
    const int nOutputEvents = 5,
    const string &inputFile = "/sphenix/data/data02/sphnxpro/MDC1/sHijing_HepMC/G4Hits/data/G4Hits_sHijing_0_12fm-0000000001-00573.root",
    const string &outdir = ".")
{
  // server
  auto se = Fun4AllServer::instance();
  se->Verbosity(1);

  auto rc = recoConsts::instance();
//  rc->set_IntFlag("RANDOMSEED", 1);

  // set up production relatedstuff
  Enable::PRODUCTION = true;
  Enable::DSTOUT = true;
  DstOut::OutputDir = outdir;

  Enable::GLOBAL_FASTSIM = true;

  //-----------------
  // Global Vertexing
  //-----------------

  if (Enable::GLOBAL_RECO && Enable::GLOBAL_FASTSIM)
  {
    cout << "You can only enable Enable::GLOBAL_RECO or Enable::GLOBAL_FASTSIM, not both" << endl;
    gSystem->Exit(1);
  }
  if (Enable::GLOBAL_RECO)
  {
    Global_Reco();
  }
  else if (Enable::GLOBAL_FASTSIM)
  {
    Global_FastSim();
  }

  pair<int, int> runseg = Fun4AllUtils::GetRunSegment(inputFile);
  int runnumber = runseg.first;
  int segment = abs(runseg.second);
  if (Enable::PRODUCTION)
  {
    Production_CreateOutputDir();
  }
  // input manager
  auto in = new Fun4AllDstPileupInputManager("DSTin");

  // vertex selection
  in->registerSubsystem(new PHG4VertexSelection);

  // generate bunch crossing list
  in->generateBunchCrossingList(nInputEvents, 5e4);

  // open file
  in->fileopen(inputFile);
  //  in->AddListFile(inputFile);
  se->registerInputManager(in);

  // output manager
  /* all the nodes from DST and RUN are saved to the output */
  //  auto out = new Fun4AllDstOutputManager("DSTOUT", outputFile);
  //  se->registerOutputManager(out);
  if (Enable::PRODUCTION)
  {
    CreateDstOutput(runnumber, segment);
  }
  // process events
  se->run(nOutputEvents);

  // terminate
  se->End();
  if (Enable::PRODUCTION)
  {
    DstOutput_move();
  }
  se->PrintTimer();
  std::cout << "All done" << std::endl;
  delete se;
  gSystem->Exit(0);
  return 0;
}

#endif
