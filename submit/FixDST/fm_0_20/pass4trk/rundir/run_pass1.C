#ifndef MACRO_RUNPASS1_C
#define MACRO_RUNPASS1_C

#include <fixdstpass1/fixdstpass1.h>
#include <fun4all/Fun4AllServer.h>
#include <fun4all/Fun4AllDstInputManager.h>
#include <fun4all/Fun4AllDstOutputManager.h>

R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libfixdstpass1.so)


void run_pass1(const std::string &infile, const int evts=0)
{
  gSystem->Load("libg4dst.so");
  gSystem->Load("libkfparticle_sphenix_io.so");
  Fun4AllServer* se = Fun4AllServer::instance();
  se->Verbosity(2);
  fixdstpass1 *p1 = new fixdstpass1();

  se->registerSubsystem(p1);

  Fun4AllInputManager *in = new Fun4AllDstInputManager("DSTin");
  in->Verbosity(3);
  in->BranchSelect("hitmap*",0);
  in->BranchSelect("particlemap*",0);
  in->BranchSelect("vtxmap*",0);
  in->BranchSelect("showermap*",0);
  in->BranchSelect("m_hitmap*",0);

  se->registerInputManager(in);

  Fun4AllOutputManager *out = new Fun4AllDstOutputManager("DSTout","pass1out.root");

  out->StripNode("AssocInfoContainer");
  out->StripNode("TRKR_CLUSTER");
  out->StripNode("TRKR_CLUSTERHITASSOC");
  out->StripNode("TRKR_HITSET");
  out->StripNode("TRKR_HITTRUTHASSOC");


  out->StripNode("G4HIT_BH_1");
  out->StripNode("G4TruthInfo");
  out->StripNode("PHHepMCGenEventMap");
  out->StripNode("TRKR_HITSET_TMP");
  out->StripNode("TRKR_HITTRUTHASSOC_TMP");

  se->registerOutputManager(out);
  se->fileopen("DSTin",infile);
  se->run(evts);
  se->End();
  delete se;
  cout << "all done" << endl;
  gSystem->Exit(0);
}

#endif
