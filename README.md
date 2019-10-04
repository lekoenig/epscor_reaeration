### epscor_reaeration

This repository contains data and scripts for analyzing Ar addition experiments in NH EPSCoR streams to estimate gas exchange.  
  



Steps:
1) From the downstream logged YSI data, calculate mean water travel time
2) In the ‘arsitedata’ file, add the appropriate metadata for each addition experiment (stage height, Q, width, reach length, travel time, temperature)
3) Using the MIMS data and the 01_ArN2_model.R script, calculate the armidk rate for each experiment.
4) Populate the arsitedata file with the armidk rate. The section at the bottom of Hilary’s script will then calculate K600 (/day) and K600 (m/day).

ReaerationSummary is an excel file that can be used to quickly visualize Q-K600 results by site.


Other notes:

File DCF_170629_inputdatafile_try.xlsx contains data from 3 sample locations along the study reach (resulting k = -0.87 m-1).
I used the DCF_170629_inputdatafile.xlsx to analyze the 6/29/2017 experiment at DCF because the model fit to the data was much better and the uncertainty around the parameter k was smaller.


