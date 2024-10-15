This repository contains Matlab code associated with the paper:

> Bernd Rieger, Isabel Droste, Fabian Gerritsma, Tip ten Brink, and Sjoerd Stallinga, *"Single image Fourier Ring Correlation"*, in review.

It consists of a set of Matlab scripts, associated with the Figures in the paper:

- `demo.m`: A demo script that shows the main idea and how to apply 1FRC. Here we use one widefield image that is provided together with the code.  
- [`simulator_1FRC.m`](simulator_1FRC.m): Simulates sensitivity of 1FRC on gain/offset/readout noise estimation.
- [`singleimageFRC_WFdataset.m`](singleimageFRC_WFdataset.m): Analyses 1FRC on widefield bead data.
- [`singleimageFRC_WF2024dataset.m`](singleimageFRC_WF2024dataset.m): Analyses 1FRC on widefield test slide data.
- [`singleimageFRC_STEDdataset.m`](singleimageFRC_STEDdataset.m): Analyses 1FRC on STED data.
- [`singleimageFRC_ISMdataset.m`](singleimageFRC_ISMdataset.m): Analyses 1FRC on ISM data.
- [`singleimageFRC_RCMdataset.m`](singleimageFRC_RCMdataset.m): Analyses 1FRC on RCM data.
- [`singleimageFRC_TEMdataset.m`](singleimageFRC_TEMdataset.m): Analyses 1FRC on TEM data.

The relevant data can be found at <https://doi.org/10.4121/3f285c07-93c0-4a8a-bbcd-bc60ed749c88>

The core of the numerical procedure, the random binomial data splitting, is coded in [`cBinomialSplit.c`](cBinomialSplit.c), which must be compiled to a mex file depending on the computer architecture. Build with `mex -O BinomialSplit.c` in Matlab.

All code was developed and tested in Matlab R2023a, and needs:
- **DIPimage**, which can be downloaded at <https://diplib.org/>
- the single image gain/offset estimation **pcfo**, which can be downloaded at <ftp://qiftp.tudelft.nl/rieger/outgoing/pcfo> for SIM and RC data (the required functions are included here for convineance).
- the package **EMIODist2** for TEM data IO, which can be downloaded at <https://nl.mathworks.com/matlabcentral/fileexchange/27021-imagic-mrc-dm-and-star-file-i-o>

