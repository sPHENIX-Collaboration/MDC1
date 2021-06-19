#ifndef MACRO_G4TRACKING_C
#define MACRO_G4TRACKING_C

#include <GlobalVariables.C>
#include <QA.C>

#include <G4_Intt.C>
#include <G4_Micromegas.C>
#include <G4_Mvtx.C>
#include <G4_TPC.C>   // use the pass 2 version

#include <fun4all/Fun4AllServer.h>

#include <g4eval/SvtxEvaluator.h>

#include <trackreco/PHCASeeding.h>
#include <trackreco/PHHybridSeeding.h>
#include <trackreco/PHGenFitTrackProjection.h>
#include <trackreco/PHGenFitTrkFitter.h>
#include <trackreco/PHGenFitTrkProp.h>
#include <trackreco/PHHoughSeeding.h>
#include <trackreco/PHMicromegasTpcTrackMatching.h>
#include <trackreco/PHRaveVertexing.h>
#include <trackreco/PHSiliconTpcTrackMatching.h>
#include <trackreco/PHTpcTrackSeedVertexAssoc.h>
#include <trackreco/PHTrackSeeding.h>
#include <trackreco/PHTruthSiliconAssociation.h>
#include <trackreco/PHTruthTrackSeeding.h>
#include <trackreco/PHTruthVertexing.h>
#include <trackreco/PHTpcClusterMover.h>
#include <trackreco/PHTrackCleaner.h>

#if __cplusplus >= 201703L
#include <trackreco/MakeActsGeometry.h>
#include <trackreco/PHActsSiliconSeeding.h>
#include <trackreco/PHActsTrkFitter.h>
#include <trackreco/PHActsInitialVertexFinder.h>
#include <trackreco/PHActsVertexFinder.h>
#include <tpccalib/PHTpcResiduals.h>
#endif

#include <trackbase/TrkrHitTruthAssoc.h>

#include <phtpctracker/PHTpcTracker.h>

#include <qa_modules/QAG4SimulationTracking.h>
#include <qa_modules/QAG4SimulationUpsilon.h>
#include <qa_modules/QAG4SimulationVertex.h>

R__LOAD_LIBRARY(libg4eval.so)
R__LOAD_LIBRARY(libtrack_reco.so)
R__LOAD_LIBRARY(libPHTpcTracker.so)
R__LOAD_LIBRARY(libqa_modules.so)

namespace Enable
{
  bool TRACKING_TRACK = false;
  bool TRACKING_EVAL = false;
  int TRACKING_VERBOSITY = 0;
  bool TRACKING_QA = false;
}  // namespace Enable

namespace G4TRACKING
{
}  // namespace G4TRACKING

void TrackingInit()
{
#if __cplusplus < 201703L
  std::cout << std::endl;
  std::cout << "Cannot run tracking without gcc-8.3 (c++17) environment. Please run:" << std::endl;
  //
  // the following gymnastics is needed to print out the correct shell script to source
  // We have three cvmfs volumes:
  //          /cvmfs/sphenix.sdcc.bnl.gov (BNL internal)
  //          /cvmfs/sphenix.opensciencegrid.org (worldwide readable)
  //          /cvmfs/eic.opensciencegrid.org (Fun4All@EIC)
  // We support tcsh and bash
  //
  std::string current_opt = getenv("OPT_SPHENIX");
  std::string x8664_sl7 = "x8664_sl7";
  std::string gcc83 = "gcc-8.3";
  size_t x8664pos = current_opt.find(x8664_sl7);
  current_opt.replace(x8664pos, x8664_sl7.size(), gcc83);
  std::string setupscript = "sphenix_setup";
  std::string setupscript_ext = ".csh";
  if (current_opt.find("eic") != string::npos)
    setupscript = "eic_setup";
  std::string shell = getenv("SHELL");
  if (shell.find("tcsh") == string::npos)
    setupscript_ext = ".sh";
  std::cout << "source " << current_opt << "/bin/"
            << setupscript << setupscript_ext << " -n" << std::endl;
  std::cout << "to set it up and try again" << std::endl;
  gSystem->Exit(1);
#endif

  if (!Enable::MICROMEGAS)
  {
    G4MICROMEGAS::n_micromegas_layer = 0;
  }

  /// Build the Acts geometry
  Fun4AllServer* se = Fun4AllServer::instance();
  int verbosity = std::max(Enable::VERBOSITY, Enable::TRACKING_VERBOSITY);
  #if __cplusplus >= 201703L
  /// Geometry must be built before any Acts modules
  MakeActsGeometry* geom = new MakeActsGeometry();
  geom->Verbosity(0);
  geom->add_fake_surfaces(false);  // default is true
  geom->setMagField(G4MAGNET::magfield);
  geom->setMagFieldRescale(G4MAGNET::magfield_rescale);
  se->registerSubsystem(geom);
  #endif  

}

void Tracking_Reco()
{
  int verbosity = std::max(Enable::VERBOSITY, Enable::TRACKING_VERBOSITY);
  // processes the TrkrHits to make clusters, then reconstruct tracks and vertices

  //---------------
  // Fun4All server
  //---------------

  Fun4AllServer* se = Fun4AllServer::instance();

  // This pass 2 version runs final track fitting only, after the TPC clusters have been corrected for distortions (set in G4_TPC.C)
  // The track and vertex maps are already created, and are read in from the pass 1 output

  // Final fitting of tracks using Acts Kalman Filter
  //=====================================

  // move (dynamic) distortion corrected clusters to readout layer radii
  PHTpcClusterMover *clustermover = new PHTpcClusterMover();
  se->registerSubsystem(clustermover);
    
  std::cout << "   Using Acts track fitting " << std::endl;

  PHActsTrkFitter* actsFit = new PHActsTrkFitter("PHActsFirstTrkFitter");
  actsFit->Verbosity(verbosity);
  actsFit->doTimeAnalysis(false);
  actsFit->fitSiliconMMs(false);
  se->registerSubsystem(actsFit);

  
  // track cleaner
  PHTrackCleaner *cleaner= new PHTrackCleaner();
  cleaner->Verbosity(0);
  se->registerSubsystem(cleaner);
  
  
  PHActsVertexFinder *finder = new PHActsVertexFinder();
  finder->Verbosity(verbosity);
  se->registerSubsystem(finder);
  
  PHActsTrkFitter* actsFit2 = new PHActsTrkFitter("PHActsSecondTrKFitter");
  actsFit2->Verbosity(verbosity);
  actsFit2->doTimeAnalysis(false);
  actsFit2->fitSiliconMMs(false);
  se->registerSubsystem(actsFit2);
  
  return;
}

void Tracking_Eval(const std::string& outputfile)
{
}

void Tracking_QA()
{
}

#endif
