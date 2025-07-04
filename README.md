# OmniSTORM

OmniSTORM is a MATLAB app for STORM super-resolution microscopy, featuring a GUI and GPU acceleration.

The GPU acceleration only supports Windows platform and Nvidia GPUs.


## Install

OmniSTORM requires MATLAB R2024a or higher.

Download `OmniSTORM-vXX.mlappinstall` from Releases and run it.


## Run from Source

1. Add `Functions` and `ThirdParty` and subfolders to MATLAB PATH
2. Double-click OmniSTORM.mlapp in the file explorer, or open it in MATLAB.
3. Click "Load Image" if the raw image is a single file; Click "Load Multi-File Image" if the image are multiple files in a folder. Supported format: TIFF and DCIMG.
4. Click "Run".
5. If the number of emitters are too many or too few, adjust the `Threshold`.


## Credits

OmniSTORM is based on the following research and open-source projects:

- [WindSTORM: Robust online image processing for high-throughput nanoscopy](https://pubmed.ncbi.nlm.nih.gov/31032419/)
- [Toward drift-free high-throughput nanoscopy through adaptive intersection maximization (AIM)](https://www.science.org/doi/10.1126/sciadv.adm7765)
- [Parameter-free image resolution estimation based on decorrelation analysis](https://www.nature.com/articles/s41592-019-0515-7)
- [Single image Fourier Ring Correlation (1frc)](https://pubmed.ncbi.nlm.nih.gov/38859523/)
- [cellSTORM - Cost-effective Super-Resolution on a Cellphone using dSTORM](https://arxiv.org/abs/1804.06244)

OmniSTORM also depends on the following GitHub repositories developed by the author:
- [dcimg-reader](https://github.com/bluerose73/dcimg-reader): DCIMG image reader MEX function
- [sonic-cuda](https://github.com/bluerose73/sonic-cuda): GPU-accelerated localization-based super-resolution MEX function