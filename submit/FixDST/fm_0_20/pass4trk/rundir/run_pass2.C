#ifndef MACRO_RUNPASS2_C
#define MACRO_RUNPASS2_C

#include <fixdstpass2/fixdstpass2.h>
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
  se->Verbosity(2);

  fixdstpass2 *p1 = new fixdstpass2();

  se->registerSubsystem(p1);

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
  cout << "all done" << endl;
  gSystem->Exit(0);
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
