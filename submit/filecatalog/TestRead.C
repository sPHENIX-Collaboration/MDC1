#include <fun4all/Fun4AllServer.h>
#include <fun4all/Fun4AllDstInputManager.h>
R__LOAD_LIBRARY(libfun4all.so)

void TestRead(const std::string &name)
{
gSystem->Load("libg4dst.so");
Fun4AllServer *se = Fun4AllServer::instance();
se->Verbosity(1);
Fun4AllDstInputManager *in = new Fun4AllDstInputManager("DSTin");
in->fileopen(name);
se->registerInputManager(in);
se->run();
se->End();
delete se;
gSystem->Exit(0);
}
