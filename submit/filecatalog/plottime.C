#include <fstream>

void plottime(const std::string &fname)
{
  int memoryuse;
  float maxtime = 0;
  vector<float> data;
  std::ifstream indata;
  indata.open(fname);
  indata >> memoryuse;
  while (! indata.eof())
  {
    float tmp =  memoryuse;
    data.push_back(tmp);
    if (tmp> maxtime)
    {
      maxtime = tmp;
    }
    std::cout << "filling with " << tmp << std::endl;
    indata >> memoryuse;
  }
  TH1 *h1 = new TH1F("time","Time in secs",300,0.,maxtime+maxtime/10.);
  for (auto iter = data.begin(); iter != data.end(); ++iter)
  {
    h1->Fill(*iter);
  }
  h1->Draw();
}
