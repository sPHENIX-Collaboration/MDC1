#include <fstream>

void plotmem(const std::string &fname)
{
  TH1 *h1 = new TH1F("memuse","Memory Usage (in MB)",300,0.,30000.);
  int memoryuse;
  std::ifstream indata;
  indata.open(fname);
  indata >> memoryuse;
  while (! indata.eof())
  {
    float tmp =  memoryuse;
    std::cout << "filling with " << tmp << std::endl;
    h1->Fill(tmp);
    indata >> memoryuse;
  }
  h1->Draw();
}
