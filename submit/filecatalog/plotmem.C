#include <fstream>

void plotmem(const std::string &fname)
{
  int memoryuse;
  float maxmem = 0;
  vector<float> fmem;
  std::ifstream indata;
  indata.open(fname);
  indata >> memoryuse;
  while (! indata.eof())
  {
    float tmp =  memoryuse;
    if (tmp > maxmem)
    {
      maxmem = tmp;
    }
    if (tmp > 500)
    {
    fmem.push_back(tmp);
    }
    indata >> memoryuse;
  }
  TH1 *h1 = new TH1F("memuse","Memory Usage (in MB)",300,0.,maxmem+maxmem/10.);
  for (auto iter = fmem.begin(); iter != fmem.end(); ++iter)
  {
    std::cout << "filling with " << *iter << std::endl;
    h1->Fill(*iter);
  }
  h1->Draw();
}
