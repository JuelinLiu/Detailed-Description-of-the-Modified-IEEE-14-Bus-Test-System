# Modified IEEE 14-Bus Test System for Koopman-Based DSR Learning

This repository provides the test-system and dataset-construction description supporting the numerical study in **Learning Dynamic Security Regions of Power Systems with Koopman Mode Decomposition**.

The description supplements the main paper and documents the settings used for Koopman mode decomposition (KMD)-based damping labeling and machine-learning-based dynamic security region (DSR) construction.

## System description

See **[Detailed Test System Description](Detailed_Test_System_Description.pdf)** for:

- System configuration, network parameters, and synchronous-generator and controller parameters.
- Base-case load and generator operating data.
- The contingency sequence applied to the sampled operating points.
- Operating-point sampling, trajectory generation, signal preprocessing, and the training/test split.

The study uses a modified IEEE 14-bus system implemented in the Power System Analysis Toolbox (PSAT), with a system base of 100 MVA and 60 Hz. The active-power outputs at Buses 2 and 6 define the operating-point parameter space. A total of 10,000 operating points are sampled independently and uniformly, with the two outputs ranging over [0, 1.4] p.u. and [0, 1.0] p.u., respectively. The reported comparisons use 9,999 valid samples.

For each operating point, a three-phase fault is applied at Bus 4 at 0 s and cleared at 0.02 s. Branch 12, connecting Buses 3 and 2, is opened at 1.2 s. The simulated response spans 50 s. The learned DSR is specific to this contingency and the selected damping requirement.

## Scope

This repository serves as an online reference for the system description. The PDF documents the model parameters and experimental settings; it does not by itself constitute an executable simulation package.

## Citation

When referring to the test-system description, cite the PDF using its public repository URL. Replace the bracketed fields below with the actual author names, publication year, access date, and URL before using the reference:

> [Authors], “Detailed description of the modified IEEE 14-bus test system,” GitHub, [year]. Accessed: [Month day, year]. [Online]. Available: [URL]

For the KMD-based labeling, label correction, and DSR-learning methodology, please cite the associated paper once its bibliographic details are available.
