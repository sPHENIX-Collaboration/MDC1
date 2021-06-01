#ifndef MACRO_RUNPASS2_C
#define MACRO_RUNPASS2_C

#include <G4_Intt.C>
#include <G4_Mvtx.C>

#include <fixdstpass2/fixdstpass2.h>

#include <g4mvtx/PHG4MvtxDigitizer.h>
#include <g4intt/PHG4InttDigitizer.h>
#include <g4tpc/PHG4TpcDigitizer.h>
#include <g4micromegas/PHG4MicromegasDigitizer.h>

#include <fun4all/Fun4AllServer.h>
#include <fun4all/Fun4AllDstInputManager.h>
#include <fun4all/Fun4AllDstOutputManager.h>

R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libfixdstpass2.so)

void Production_CreateOutputDir(const std::string &outdir);
void Production_MoveOutput(const std::string &outdir, const std::string &outfile);

void run_pass2(const std::string &infile, const std::string &outfile = "test3.root", const std::string &outdir = "/sphenix/user/pinkenbu", const int evts=0)
{
  gSystem->Load("libg4dst.so");
  gSystem->Load("libkfparticle_sphenix_io.so");
  Fun4AllServer* se = Fun4AllServer::instance();
  se->Verbosity(1);

  fixdstpass2 *p1 = new fixdstpass2();
  se->registerSubsystem(p1);


//=========

  int verbosity = 0;

  PHG4MvtxDigitizer* digimvtx = new PHG4MvtxDigitizer();
  digimvtx->Verbosity(verbosity);
  se->registerSubsystem(digimvtx);

//==========

  std::vector<double> userrange;  // 3-bit ADC threshold relative to the mip_e at each layer.
  userrange.push_back(0.0584625322997416);
  userrange.push_back(0.116925064599483);
  userrange.push_back(0.233850129198966);
  userrange.push_back(0.35077519379845);
  userrange.push_back(0.584625322997416);
  userrange.push_back(0.818475452196383);
  userrange.push_back(1.05232558139535);
  userrange.push_back(1.28617571059432);

  // new containers
  PHG4InttDigitizer* digiintt = new PHG4InttDigitizer();
  digiintt->Verbosity(verbosity);
  for (int i = 0; i < G4INTT::n_intt_layer; i++)
  {
    digiintt->set_adc_scale(G4MVTX::n_maps_layer + i, userrange);
  }
  se->registerSubsystem(digiintt);

//==========

  PHG4TpcDigitizer* digitpc = new PHG4TpcDigitizer();
  digitpc->SetTpcMinLayer(G4MVTX::n_maps_layer + G4INTT::n_intt_layer);
  double ENC = 670.0;  // standard
  digitpc->SetENC(ENC);
  double ADC_threshold = 4.0 * ENC;
  digitpc->SetADCThreshold(ADC_threshold);  // 4 * ENC seems OK
  digitpc->Verbosity(verbosity);
  se->registerSubsystem(digitpc);

//===========
  se->registerSubsystem(new PHG4MicromegasDigitizer);


  Fun4AllInputManager *in = new Fun4AllDstInputManager("DSTin");
  se->registerInputManager(in);
  Fun4AllOutputManager *out = new Fun4AllDstOutputManager("DSTout",outfile);

  out->StripNode("AssocInfoContainer_TMP");
  out->StripNode("TRKR_CLUSTER_TMP");
  out->StripNode("TRKR_CLUSTERHITASSOC_TMP");
  out->StripNode("TRKR_HITSET_TMP");
  out->StripNode("TRKR_HITTRUTHASSOC_TMP");

  se->registerOutputManager(out);
  se->fileopen("DSTin",infile);
  se->run(evts);
  se->End();
  delete se;
  Production_CreateOutputDir(outdir);
  Production_MoveOutput(outdir,outfile);
}

void Production_CreateOutputDir(const std::string &dirname)
{
  string mkdircmd = "mkdir -p " + dirname;
  gSystem->Exec(mkdircmd.c_str());
}

void Production_MoveOutput(const std::string &outdir, const std::string &outfile)
{
  string copyscript = "copyscript.pl";
  ifstream f(copyscript);
  bool scriptexists = f.good();
  f.close();
  string mvcmd;
  if (scriptexists)
  {
    mvcmd = copyscript + " -outdir " + outdir + " " + outfile;
  }
  else
  {
    mvcmd = "mv " + outfile + " " + outdir;
  }
  cout << "mvcmd: " << mvcmd << endl;
  gSystem->Exec(mvcmd.c_str());
}


#endif
