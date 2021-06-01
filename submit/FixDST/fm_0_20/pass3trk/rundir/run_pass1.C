#ifndef MACRO_RUNPASS1_C
#define MACRO_RUNPASS1_C

#include <fixdstpass1/fixdstpass1.h>
#include <fun4all/Fun4AllServer.h>
#include <fun4all/Fun4AllDstInputManager.h>
#include <fun4all/Fun4AllDstOutputManager.h>

R__LOAD_LIBRARY(libfun4all.so)
R__LOAD_LIBRARY(libfixdstpass1.so)


void run_pass1(const std::string &infile, const int evts=5)
{
  gSystem->Load("libg4dst.so");
  gSystem->Load("libkfparticle_sphenix_io.so");
  Fun4AllServer* se = Fun4AllServer::instance();
  se->Verbosity(1);

  fixdstpass1 *p1 = new fixdstpass1();
  se->registerSubsystem(p1);

  Fun4AllInputManager *in = new Fun4AllDstInputManager("DSTin");
  se->registerInputManager(in);
  Fun4AllOutputManager *out = new Fun4AllDstOutputManager("DSTout","pass1out.root");

  out->StripNode("AssocInfoContainer");
  out->StripNode("TRKR_CLUSTER");
  out->StripNode("TRKR_CLUSTERHITASSOC");
  out->StripNode("TRKR_HITSET");
  out->StripNode("TRKR_HITTRUTHASSOC");

  se->registerOutputManager(out);
  se->fileopen("DSTin",infile);
  se->run(evts);
  se->End();
  delete se;
}

#endif
