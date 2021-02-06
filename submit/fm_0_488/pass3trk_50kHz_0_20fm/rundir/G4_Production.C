#ifndef MACRO_G4PRODUCTION_C
#define MACRO_G4PRODUCTION_C

#include <GlobalVariables.C>

namespace Enable
{
  bool PRODUCTION = false;
}

namespace PRODUCTION
{
  string SaveOutputDir = "./";
}

void Production_CreateOutputDir()
{
  PRODUCTION::SaveOutputDir = DstOut::OutputDir;
  string mkdircmd = "mkdir -p " + DstOut::OutputDir;
  gSystem->Exec(mkdircmd.c_str());
}

void Production_MoveOutput()
{
  if (Enable::DSTOUT)
  {
    string copyscript = "copyscript.pl";
    ifstream f(copyscript);
    bool scriptexists = f.good();
    f.close();
    string fulloutfile = DstOut::OutputFile;
    string mvcmd;
    if (scriptexists)
    {
      mvcmd = copyscript + " -outdir " + PRODUCTION::SaveOutputDir + " " + fulloutfile;
    }
    else
    {
      mvcmd = "mv " + fulloutfile + " " + PRODUCTION::SaveOutputDir;
    }
    cout << "mvcmd: " << mvcmd << endl;
    gSystem->Exec(mvcmd.c_str());
  }
}
#endif
