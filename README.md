## Project Test Videos
- Due to YouTube's publishing policies, the full set of test videos could not be uploaded there. Instead, they are available in the following Google Drive folder:  
https://drive.google.com/drive/folders/1PA7n5LBGxDn2OwmkoXzPLhVssn8M6ggE

# PlutoOFDM

PlutoOFDM is a project developed to design and test OFDM communication systems with adaptive and non-adaptive frequency hopping methods using ADALM-Pluto SDR hardware in MATLAB, aiming to avoid jammer interference. This work is carried out by the Hub10 project team within the scope of the Teknofest Wireless Communication Competition as an academic project.

## Features
- OFDM frame generation, modulation, and transmission
- Real-time wireless communication with Pluto SDR
- Jammer detection and adaptive frequency hopping (FHSS)
- GMM-based SNR and jammer analysis mechanisms
- Structured directory of classes, scripts, and helper functions

## Project Structure
- **Classes/** → Main class files (e.g., `OFDMPlutoRX`, `OFDMPlutoTX`, `ModulationMapper`)
- **Scripts/** → Test and execution scripts (e.g., `ofdmPlutoTransmitter.m`, `ofdmPlutoReceiver.m`)
- **Config/** → System parameter files
- **Sim/** → Simulations (e.g., BPSK, QAM + convolutional coding)
- **Utils/** → Helper functions (e.g., GMM modeling)

## Requirements
- MATLAB R202x (with Communications Toolbox)
- 2–3 ADALM-Pluto SDR devices

## Usage
1️) Set up and connect your Pluto SDR devices.  
2️) Run `Scripts/ofdmPlutoTransmitter.m` for the transmitter.  
3️) Run `Scripts/ofdmPlutoReceiver.m` or `Scripts/ofdmPlutoReceiverMinimal.m` for the receiver.  
4️) Use the related scripts for jammer detection and FHSS (`jammerDetection.m`, `ofdmFHSSTestTX.m`, etc.).

## Note
This project does not include any license and has been developed solely for academic purposes.

## Contact
For any questions regarding the project, please [open an issue on GitHub](https://github.com/hub10com/PlutoOFDM/issues).
