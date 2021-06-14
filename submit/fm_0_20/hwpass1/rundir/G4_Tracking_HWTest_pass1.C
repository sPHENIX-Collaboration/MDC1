#ifndef MACRO_G4TRACKING_C
#define MACRO_G4TRACKING_C

#include <GlobalVariables.C>
#include <QA.C>

#include <G4_Intt.C>
#include <G4_Micromegas.C>
#include <G4_Mvtx.C>
#include <G4_TPC.C>   // use the pass 1 version

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
  // space charge calibrations are done in pass1 only
  // Space Charge calibration flag
  bool SC_CALIBMODE = true;        // this is anded with G4TPC::ENABLE_DISTORTIONS in TrackingInit()
  double SC_COLLISIONRATE = 50e3;  // leave at 50 KHz for now, scaling of distortion map not implemented yet

  // Tracking reconstruction setup parameters and flags
  //=====================================

  // The normal (default) Acts tracking chain used in Pass 1:
  //   PHActsSiliconSeeding                    // make silicon track seeds
  //   PHActsInitialVertexing                    // event vertex from silicon track stubs
  //   PHCASeeding                                    // TPC track seeds
  //   PHTpcTrackSeedVertexAssoc    // Associates TPC track seeds with a vertex, refines phi and eta
  //   PHSiliconTpcTrackMatching      // match TPC track seeds to silicon track seeds
  //   PHMicromegasTpcTrackMatching   // associate Micromegas clusters with TPC track stubs
  //   PHActsTrkFitter (1)                         // Fits silicon + MMs clusters only

  // Possible variations - these are normally false
  //====================================
  // TPC seeding options
  bool use_PHTpcTracker_seeding = false;  // false for using the default PHCASeeding to get TPC track seeds, true to use PHTpcTracker
  bool use_hybrid_seeding = false;                  // false for using the default PHCASeeding, true to use PHHybridSeeding (STAR core, ALICE KF)
  std::string ResidualName = "TpcSpaceChargeMatrices.root";
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

  // Check for colliding switches
  if(G4TRACKING::use_hybrid_seeding && G4TRACKING::use_PHTpcTracker_seeding)
    {
      std::cerr << "***WARNING: MULTIPLE SEEDER OPTIONS SELECTED!***" << std::endl;
      std::cerr << "  Current config selects both PHTpcTracker and PHHybridSeeding." << std::endl;
      std::cerr << "  Revert to default...." << std::endl;
      G4TRACKING::use_hybrid_seeding = false;
      G4TRACKING::use_PHTpcTracker_seeding = false;
    }

  /// Build the Acts geometry
  Fun4AllServer* se = Fun4AllServer::instance();
  int verbosity = std::max(Enable::VERBOSITY, Enable::TRACKING_VERBOSITY);
  #if __cplusplus >= 201703L
  /// Geometry must be built before any Acts modules
  MakeActsGeometry* geom = new MakeActsGeometry();
  geom->Verbosity(0);
  geom->setMagField(G4MAGNET::magfield);
  geom->setMagFieldRescale(G4MAGNET::magfield_rescale);
  
  /// Need a flip of the sign for constant field in tpc tracker
  if(G4TRACKING::use_PHTpcTracker_seeding && 
     G4MAGNET::magfield.find(".root") == std::string::npos)
    {
      geom->setMagFieldRescale(-1 * G4MAGNET::magfield_rescale);
    }
  se->registerSubsystem(geom);
  #endif  

}

void Tracking_Reco()
{
  int verbosity = std::max(Enable::VERBOSITY, Enable::TRACKING_VERBOSITY);

  //---------------
  // Fun4All server
  //---------------

  Fun4AllServer* se = Fun4AllServer::instance();

  // This pass 1 version is used to reconstruct vertices and full track seeds
  // It then fits the silicon + MM's clusters and calculates TPC cluster residuals
  // The vertex map and track map are written out for use by pass 2

  // Assemble silicon clusters into track stubs - needed for initial vertex finding
  //============================================================

  PHActsSiliconSeeding* silicon_Seeding = new PHActsSiliconSeeding();
  silicon_Seeding->Verbosity(0);
  se->registerSubsystem(silicon_Seeding);
  
  // Initial vertex finding
  //=================================

  PHActsInitialVertexFinder* init_vtx = new PHActsInitialVertexFinder();
  init_vtx->Verbosity(verbosity);
  init_vtx->setSvtxTrackMapName("SvtxSiliconTrackMap");
  init_vtx->setSvtxVertexMapName("SvtxVertexMap");
  se->registerSubsystem(init_vtx);

  
  // TPC track seeding (finds all clusters in TPC for tracks)
  //============================================

  std::cout << "Using normal TPC track seeding " << std::endl;
  
  // TPC track seeding from data
  if (G4TRACKING::use_PHTpcTracker_seeding && !G4TRACKING::use_hybrid_seeding)
    {
      std::cout << "   Using PHTpcTracker track seeding " << std::endl;
      
      PHTpcTracker* tracker = new PHTpcTracker("PHTpcTracker");
      tracker->set_seed_finder_options(3.0, M_PI / 8, 10, 6.0, M_PI / 8, 5, 1);   // two-pass CA seed params
      tracker->set_seed_finder_optimization_remove_loopers(true, 20.0, 10000.0);  // true if loopers not needed
      tracker->set_track_follower_optimization_helix(true);                       // false for quality, true for speed
      tracker->set_track_follower_optimization_precise_fit(false);                // true for quality, false for speed
      tracker->enable_json_export(false);                                         // save event as json, filename is automatic and stamped by current time in ms
      tracker->enable_vertexing(false);                                           // rave vertexing is pretty slow at large multiplicities...
      tracker->Verbosity(verbosity);
      se->registerSubsystem(tracker);
    }
  else if(G4TRACKING::use_hybrid_seeding && !G4TRACKING::use_PHTpcTracker_seeding)
    {
      std::cout << "   Using PHHybridSeeding track seeding " << std::endl;
      
      PHHybridSeeding* hseeder = new PHHybridSeeding("PHHybridSeeding");
      hseeder->set_field_dir(G4MAGNET::magfield_rescale);
      hseeder->setSearchRadius(3.,6.); // mm (iter1, iter2)
      hseeder->setSearchAngle(M_PI/8.,M_PI/8.); // radians (iter1, iter2)
      hseeder->setMinTrackSize(10,5); // (iter1, iter2)
      hseeder->setNThreads(1);
      hseeder->Verbosity(verbosity);
      se->registerSubsystem(hseeder);
    }
  else
    {
      std::cout << "   Using PHCASeeding track seeding " << std::endl;
      
      auto seeder = new PHCASeeding("PHCASeeding");
      seeder->set_field_dir(G4MAGNET::magfield_rescale);  // to get charge sign right
      seeder->Verbosity(0);
      seeder->SetLayerRange(7, 55);
      seeder->SetSearchWindow(0.01, 0.02);  // (eta width, phi width)
      seeder->SetMinHitsPerCluster(2);
      seeder->SetMinClustersPerTrack(20);
      se->registerSubsystem(seeder);
    }

  // We have TPC track seeds with associated (distortion corrected) clusters
  // now move the distortion corrected clusters to the readout layer radii
  PHTpcClusterMover *clustermover = new PHTpcClusterMover();
  clustermover->Verbosity(0);
  se->registerSubsystem(clustermover);
    
  // Associate TPC track stubs with silicon and Micromegas
  //=============================================
  
  // This does not care which seeder is used
  // It refines the phi and eta of the TPC tracklet prior to matching with the silicon tracklet
  PHTpcTrackSeedVertexAssoc *vtxassoc = new PHTpcTrackSeedVertexAssoc();
  vtxassoc->Verbosity(0);
  se->registerSubsystem(vtxassoc);
      
  // Silicon cluster matching to TPC track seeds
  std::cout << "      Using stub matching for Si matching " << std::endl;
      
  // The normal silicon association methods
  // start with a complete TPC track seed from one of the CA seeders
      
  // Match the TPC track stubs from the CA seeder to silicon track stubs from PHSiliconTruthTrackSeeding
  PHSiliconTpcTrackMatching* silicon_match = new PHSiliconTpcTrackMatching();
  silicon_match->Verbosity(0);
  silicon_match->set_field(G4MAGNET::magfield);
  silicon_match->set_field_dir(G4MAGNET::magfield_rescale);
  // This is set only when we really have clusters that have SC distorted positions
  //silicon_match->set_sc_calib_mode(G4TRACKING::SC_CALIBMODE);
  if (G4TRACKING::SC_CALIBMODE)
    {
      silicon_match->set_collision_rate(G4TRACKING::SC_COLLISIONRATE);
      // search windows for initial matching with distortions
      // tuned values are 0.04 and 0.008 in distorted events
      //silicon_match->set_phi_search_window(0.04);
      //silicon_match->set_eta_search_window(0.008);
    }
  else
    {
      // after distortion corrections and rerunning clustering, default tuned values are 0.02 and 0.004 in low occupancy events
      silicon_match->set_phi_search_window(0.03);
      silicon_match->set_eta_search_window(0.005);
    }
  silicon_match->set_test_windows_printout(false);  // used for tuning search windows only
  se->registerSubsystem(silicon_match);


  // Associate Micromegas clusters with the tracks
  if (G4MICROMEGAS::n_micromegas_layer > 0)
    {
      std::cout << "      Using Micromegas matching " << std::endl;
	  
      // Match TPC track stubs from CA seeder to clusters in the micromegas layers
      PHMicromegasTpcTrackMatching* mm_match = new PHMicromegasTpcTrackMatching();
      mm_match->Verbosity(verbosity);
      mm_match->set_sc_calib_mode(G4TRACKING::SC_CALIBMODE);
      if (G4TRACKING::SC_CALIBMODE)
	{
	  // calibration pass with distorted tracks
	  mm_match->set_collision_rate(G4TRACKING::SC_COLLISIONRATE);
	  // configuration is potentially with different search windows
	  mm_match->set_rphi_search_window_lyr1(0.2);
	  mm_match->set_rphi_search_window_lyr2(13.0);
	  mm_match->set_z_search_window_lyr1(26.0);
	  mm_match->set_z_search_window_lyr2(0.2);
	}
      else
	{
	  // baseline configuration is (0.2, 13.0, 26, 0.2) and is the default
	  mm_match->set_rphi_search_window_lyr1(0.2);
	  mm_match->set_rphi_search_window_lyr2(13.0);
	  mm_match->set_z_search_window_lyr1(26.0);
	  mm_match->set_z_search_window_lyr2(0.2);
	}
      mm_match->set_min_tpc_layer(38);             // layer in TPC to start projection fit
      mm_match->set_test_windows_printout(false);  // used for tuning search windows only
      se->registerSubsystem(mm_match);
    }
      
  // Fitting of silicon + MM's tracks using Acts Kalman Filter
  //=========================================
      
  std::cout << "   Using Acts track fitting " << std::endl;

  PHActsTrkFitter* actsFit = new PHActsTrkFitter("PHActsFirstTrkFitter");
  actsFit->Verbosity(0);
  actsFit->doTimeAnalysis(false);
  /// If running with distortions, fit only the silicon+MMs first
  actsFit->fitSiliconMMs(G4TRACKING::SC_CALIBMODE);
  se->registerSubsystem(actsFit);

  if (G4TRACKING::SC_CALIBMODE)
    {
      /// run tpc residual determination with silicon+MM track fit
      PHTpcResiduals* residuals = new PHTpcResiduals();
      residuals->setOutputfile(G4TRACKING::ResidualName);
      residuals->Verbosity(0);
      se->registerSubsystem(residuals);
    } 
}

void Tracking_Eval(const std::string& outputfile)
{
}

void Tracking_QA()
{

}

#endif
