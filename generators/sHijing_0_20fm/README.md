# Hijing
Area for the sHijing 0-20fm production
  * condor.job : jobfile
  * run_hijing.pl : perl script to submit hijing production. Modify files/event and number of events for adjustments
  * to generate perl run_hijing.pl <number new files> 0_20fm
  * run_hijing.sh : shell script to run the sHijing binary with parameters
The script checks the old logs and makes sure it does not reuse any seed
