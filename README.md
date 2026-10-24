# Modified IEEE 14-Bus Test System for Koopman-Based DSR Learning

This repository contains the MATLAB code, precomputed labels, and test-system data supporting the numerical study in **Learning Dynamic Security Regions of Power Systems with Koopman Mode Decomposition**. It covers Koopman mode decomposition (KMD)-based oscillatory-stability labeling, mislabeled-sample correction, and machine-learning-based dynamic security region (DSR) construction on a modified IEEE 14-bus system.

The accompanying system description is available in [Detailed Description of the Modified IEEE 14-Bus Test System.pdf](Detailed%20Description%20of%20the%20Modified%20IEEE%2014-Bus%20Test%20System.pdf).

## Overview

For each operating point, the active-power outputs at two generator buses form the two-dimensional parameter vector

```text
p = [P_G2, P_G6].
```

Post-disturbance rotor-angle and rotor-speed trajectories are analyzed using KMD. A binary damping label is then assigned:

- `1`: the specified damping requirement is satisfied (inside the DSR);
- `0`: the specified damping requirement is violated (outside the DSR).

The repository supports the following tasks:

1. Inspect the modified IEEE 14-bus model and contingency settings.
2. Use the included KMD and time-domain-simulation (TDS) labels.
3. Correct locally inconsistent KMD labels using a K-nearest-neighbor (KNN) rule in the operating-point parameter space.
4. Train a classifier and construct an ML-based DSR.
5. Compare KMD implementations and observation windows.
6. Generate the principal numerical tables and figures used in the study.

## Repository contents

| File or folder | Purpose |
| --- | --- |
| `Detailed Description of the Modified IEEE 14-Bus Test System.pdf` | Network, dynamic-model, sampling, contingency, and simulation settings. |
| `case14_L.m` | Modified IEEE 14-bus power-flow data in MATPOWER case format. |
| `d_014_dyn_l10_mdl526.m` | PSAT dynamic model, controllers, fault, and breaker data. |
| `simulation_datasssa_2genP1003.m` | Generates operating points and post-disturbance trajectories using PSAT. |
| `pfdatatestHankelparameter_1224_0.m` | Noise-free Hankel-DMD/KMD labeling and benchmark generation from trajectory data. |
| `pfdatatestHankelparameter_1224_noise.m` | Hankel-DMD/KMD labeling with measurement noise. |
| `evaluate_KNN_mislabeled_sample_correction_0624.m` | Evaluates KNN-based label correction against the TDS benchmark. |
| `build_ML_DSR_test_assessment_0625.m` | Corrects labels, trains the classifier, constructs the DSR, and evaluates the held-out test set. |
| `plot_DSR_threshold_and_trajectory_polished_0625.m` | Plots DSR boundaries for different damping thresholds and representative trajectories. |
| `pfdatatestHankelparameter_KMDvalidation_publication_0622.m` | Validates representative unstable, poorly damped, and sufficiently damped trajectories. |
| `pfdatatestHankelparameter_KMDvalidation_publication_0629.m` | Produces representative trajectories for different damping thresholds. |
| `export_KMD_implementation_labels_and_distributions_0622.m` | Exports sample-level labels and plots distributions for three KMD implementations. |
| `KMD_implementation_evaluation_0622/` | Precomputed Exact DMD (`K1`), Companion DMD (`K2`), and Hankel DMD (`K3`) evaluation results. |
| `KMD_implementation_evaluation_0622.zip` | Compressed copy of the precomputed KMD implementation results. Extract it in the repository root if the folder above is not present. |
| `parameter_*.mat` | Precomputed operating-point parameters and binary labels under different settings. |
| `TDS_benchmark_labels.mat` | Stored TDS benchmark-label data. |
| `testforknnlightGBthreshold_DSRfilled.m` | Legacy script for filled DSR plots; it contains a machine-specific output path and is not the recommended entry point. |

## Software requirements

### Required for the included-data workflow

- MATLAB R2020a or later is recommended.
- Statistics and Machine Learning Toolbox, used by `knnsearch`, `fitcensemble`, `templateTree`, and related functions.

### Optional Python classifier

`build_ML_DSR_test_assessment_0625.m` first attempts to use LightGBM through MATLAB's Python interface. Install the Python packages with

```bash
python -m pip install numpy lightgbm
```

Then verify the Python interpreter visible to MATLAB:

```matlab
pyenv
```

If necessary, configure it explicitly:

```matlab
pyenv('Version', 'C:\path\to\python.exe');
```

If LightGBM is unavailable, `build_ML_DSR_test_assessment_0625.m` automatically falls back to MATLAB bagged decision trees. In contrast, `plot_DSR_threshold_and_trajectory_polished_0625.m` directly calls Python LightGBM and therefore requires both NumPy and LightGBM.

### Additional requirements for regenerating trajectories

- Power System Analysis Toolbox (PSAT), available on the MATLAB path.
- MATPOWER is recommended for inspecting or regenerating MATPOWER-format operating-point data.
- The external files listed in [Regenerating the complete dataset](#regenerating-the-complete-dataset).

## Quick start using the included data

The fastest reproducible route uses the precomputed `parameter_*.mat` files and does not require rerunning 10,000 time-domain simulations.

Clone the repository and make it the MATLAB working directory:

```bash
git clone https://github.com/JuelinLiu/Detailed-Description-of-the-Modified-IEEE-14-Bus-Test-System.git
cd Detailed-Description-of-the-Modified-IEEE-14-Bus-Test-System
```

In MATLAB:

```matlab
repoDir = pwd;
addpath(repoDir);
```

For the main label-correction and DSR-learning results, the minimum workflow is:

```matlab
run('evaluate_KNN_mislabeled_sample_correction_0624.m');
run('build_ML_DSR_test_assessment_0625.m');
```

The KMD implementation comparison in Step 1 below is independent of these two scripts and can be run separately.

### Step 1: Export and inspect the KMD implementation results

```matlab
run('export_KMD_implementation_labels_and_distributions_0622.m');
```

This script reads the completed result files in `KMD_implementation_evaluation_0622/` and exports sample-level CSV, XLSX, and MAT files together with label-distribution figures. It compares:

- `K1`: Exact DMD;
- `K2`: Companion DMD;
- `K3`: Hankel DMD;
- 15-s and 50-s observation windows.

Outputs are written to:

```text
KMD_implementation_evaluation_0622/label_distributions_0622/
```

### Step 2: Evaluate KNN-based label correction

```matlab
run('evaluate_KNN_mislabeled_sample_correction_0624.m');
```

The script uses `parameter_30_50.mat` as the TDS benchmark and evaluates four KMD-label conditions:

| Condition | Input file |
| --- | --- |
| 50 s, noise-free | `parameter_3_50_0.mat` |
| 50 s, 50% noise | `parameter_3_noise_0.5_50.mat` |
| 15 s, noise-free | `parameter_3_15_0.mat` |
| 15 s, 50% noise | `parameter_3_noise_0.5_15.mat` |

The default correction settings are

```text
neighbor fraction r = 0.0075
majority threshold rho = 0.60
K = round(r N)
```

Outputs are written to:

```text
KNN_correction_support_0624/
```

The output folder includes correction metrics, corrected labels, and benchmark error maps.

### Step 3: Train the classifier and construct the DSR

```matlab
run('build_ML_DSR_test_assessment_0625.m');
```

This script:

1. loads the TDS benchmark and KMD-derived labels;
2. applies the KNN correction;
3. makes a stratified 80/20 training-test split;
4. trains LightGBM, or MATLAB bagged trees when LightGBM is unavailable;
5. evaluates learning accuracy against corrected KMD labels;
6. independently evaluates benchmark accuracy against TDS labels; and
7. plots the learned secure and insecure regions.

The random seed is fixed in the script for repeatable data splitting. The main outputs are:

```text
ML_DSR_test_assessment_metrics.csv
ML_DSR_test_assessment_metrics.xlsx
ML_DSR_test_assessment_results.mat
ML_DSR_learned_regions_with_benchmark_metrics.*
```

The current script writes these files to a sibling `PES-LETTER/ML_DSR_test_assessment_0625` directory determined from the repository location. To keep all outputs inside the repository, change the definition of `outputDir` near the beginning of the script to, for example,

```matlab
outputDir = fullfile(baseDir, 'outputs', 'ML_DSR_test_assessment_0625');
```

## Program-by-program usage

This section describes how each MATLAB file is intended to be used. Run scripts from the repository root unless stated otherwise.

### `case14_L.m`

**Purpose:** Stores the modified IEEE 14-bus steady-state network in MATPOWER case format.

**How to use:** This is a model-definition file, not a main experiment. It is loaded by the trajectory-generation workflow. Users may also open it to inspect bus, generator, branch, and generator-cost data.

**Requires:** MATLAB; MATPOWER is only needed if the case is used directly with MATPOWER functions.

**Output:** A MATPOWER case structure when called by the simulation workflow. It does not write result files.

### `d_014_dyn_l10_mdl526.m`

**Purpose:** Defines the PSAT dynamic model, including buses, lines, synchronous machines, exciters, turbine governors, loads, fault, and breaker settings.

**How to use:** Do not run it as an independent analysis. `simulation_datasssa_2genP1003.m` loads it through the variable `Filedata_input`.

**Requires:** PSAT when used for simulation.

**Output:** PSAT model variables in the MATLAB workspace.

### `simulation_datasssa_2genP1003.m`

**Purpose:** Samples operating points, initializes PSAT power flows, runs 50-s time-domain simulations, and stores rotor-angle and rotor-speed trajectories.

**Run:**

```matlab
run('simulation_datasssa_2genP1003.m');
```

**Required inputs:**

- `d_014_dyn_l10_mdl526.m`;
- `case14_L.m`;
- PSAT on the MATLAB path;
- `s14.mat` and `modifyfile.m`, which are referenced by the script but are not included in the current repository.

**Important settings:**

- `n = 10000`: number of operating points processed;
- `Settings.tf = 50`: simulation duration in seconds;
- `Settings.tstep = 0.05`: nominal time step in seconds.

The active-power outputs sampled in the code correspond to the generators at Buses 2 and 6. For a short test, reduce `n` before running the full dataset.

**Output:**

```text
simulation_data_14_493_breaker_1003_2.mat
```

This file contains `Saveopt`, `time_set1`, `delta_set1`, `omega_set1`, and related simulation quantities. It is large and is not included in the repository.

### `pfdatatestHankelparameter_1224_0.m`

**Purpose:** Applies Hankel-DMD/KMD to the noise-free trajectories, calculates critical damping information, generates TDS reference labels, and produces KMD-derived labels.

**Run:**

```matlab
run('pfdatatestHankelparameter_1224_0.m');
```

**Required input:** `simulation_data_14_493_breaker_1003_2.mat` in the repository root.

**Main settings:**

```matlab
tdmd2 = 50;   % observation window in seconds
rset  = 25;   % retained rank
Ded   = 60;   % number of Hankel delays
```

**Principal outputs:**

```text
parameter_30_50.mat       % parameters and TDS labels (index0)
parameter_3_50_0.mat      % parameters and KMD labels (index)
damping_0.mat
position_0.mat
```

The script contains a machine-specific `exportPath`. Change it before exporting figures on another computer. Other threshold/window datasets supplied in the repository were generated by changing the corresponding observation-window, damping-threshold, and output-file settings.

### `pfdatatestHankelparameter_1224_noise.m`

**Purpose:** Repeats Hankel-DMD/KMD labeling after adding Gaussian measurement noise to the normalized trajectory observables.

**Run:**

```matlab
run('pfdatatestHankelparameter_1224_noise.m');
```

**Required input:** `simulation_data_14_493_breaker_1003_2.mat`.

**Main settings:**

```matlab
tdmd2      = 15;    % observation window in seconds
rset       = 25;    % retained rank
Ded        = 60;    % number of Hankel delays
noise_level = 0.2;  % Gaussian-noise level
```

**Default output in the current script:**

```text
parameter_3_noise_0.2_15_0.005.mat
```

Change the output filename whenever `noise_level`, `tdmd2`, or the damping threshold is changed so that the encoded condition remains correct. Change the machine-specific `exportPath` before saving figures.

### `pfdatatestHankelparameter_KMDvalidation_publication_0622.m`

**Purpose:** Generates representative validation plots containing normalized trajectories, continuous-time Koopman eigenvalues, the critical oscillatory mode, frequency, damping ratio, and reconstruction error.

**Run:**

```matlab
run('pfdatatestHankelparameter_KMDvalidation_publication_0622.m');
```

**Required input:** `simulation_data_14_493_breaker_1003_2.mat`.

**Editable settings near the beginning:**

```matlab
sampleIndex       = [703, 4571, 6756];
beta              = [0, 0, 0.01];
observationWindow = 50;
samplingInterval  = 0.05;
truncationRank    = 25;
hankelDelays      = 60;
```

**Outputs:** Publication figures plus CSV, XLSX, and MAT summaries in `KMD_representative_validation_publication_0622/`.

### `pfdatatestHankelparameter_KMDvalidation_publication_0629.m`

**Purpose:** Uses the same validation procedure as the `_0622` version but selects representative points associated with different damping-threshold cases.

**Run:**

```matlab
run('pfdatatestHankelparameter_KMDvalidation_publication_0629.m');
```

**Required input:** `simulation_data_14_493_breaker_1003_2.mat`.

**Default sample selection:**

```matlab
sampleIndex = [4571, 9402, 6756];
```

Edit `sampleIndex`, `beta`, and `caseType` together when selecting different representative cases. The script currently writes to the same output folder as the `_0622` version, so move or rename earlier results if both scripts are run.

### `export_KMD_implementation_labels_and_distributions_0622.m`

**Purpose:** Post-processes completed KMD evaluations. It does not recalculate KMD.

**Preparation:** If `KMD_implementation_evaluation_0622/` is absent, extract `KMD_implementation_evaluation_0622.zip` into the repository root. The resulting directory must directly contain files such as `results_K1_15s.mat` and `results_K3_50s.mat`.

**Run:**

```matlab
run('export_KMD_implementation_labels_and_distributions_0622.m');
```

**Outputs:** Sample-level CSV/XLSX/MAT files, individual distribution figures, combined comparison figures, and a summary MAT file under:

```text
KMD_implementation_evaluation_0622/label_distributions_0622/
```

### `evaluate_KNN_mislabeled_sample_correction_0624.m`

**Purpose:** Detects locally inconsistent KMD labels in the two-dimensional operating-point space and corrects them using the neighborhood majority.

**Run:**

```matlab
run('evaluate_KNN_mislabeled_sample_correction_0624.m');
```

**Required inputs:** `parameter_30_50.mat` and the four KMD-label files listed in Step 2 above.

**Editable settings:**

```matlab
neighborFraction       = 0.0075;
majorityRatioThreshold = 0.60;
```

**Outputs:** Accuracy and error statistics before and after correction, corrected labels, CSV/XLSX tables, and error-map figures under `KNN_correction_support_0624/`.

### `build_ML_DSR_test_assessment_0625.m`

**Purpose:** Performs KNN correction, creates a stratified training/test split, trains an ML classifier, evaluates it, and visualizes the learned DSR.

**Run:**

```matlab
run('build_ML_DSR_test_assessment_0625.m');
```

**Required inputs:** The same five MAT files used by the KNN evaluation script.

**Classifier:** LightGBM is used when MATLAB can access Python NumPy and LightGBM. If that attempt fails, the script automatically uses MATLAB bagged trees.

**Editable settings:**

```matlab
neighborFraction       = 0.0075;
majorityRatioThreshold = 0.60;
testRatio              = 0.20;
```

**Outputs:** Test-set metrics, trained model data, grid probabilities, and learned-DSR figures in `ML_DSR_test_assessment_0625/` at the path constructed by the script.

### `plot_DSR_threshold_and_trajectory_polished_0625.m`

**Purpose:** Produces two publication figures: DSR boundaries under three damping thresholds and representative post-disturbance trajectories near those boundaries.

**Run:**

```matlab
run('plot_DSR_threshold_and_trajectory_polished_0625.m');
```

**Inputs for the boundary figure:**

```text
parameter_3_15_0.mat
parameter_3_15_0.005.mat
parameter_3_15_0.01.mat
```

**Additional input for the trajectory figure:** `simulation_data_14_493_breaker_1003_2.mat`.

**Requires:** Python NumPy and LightGBM through MATLAB.

**Outputs:** Boundary-summary CSV/XLSX files and publication figures in `DSR_threshold_polished_0625/` at the path constructed by the script. If the raw trajectory file is unavailable, only the first figure can be regenerated; the script will stop when it reaches the second section.

### `testforknnlightGBthreshold_DSRfilled.m`

**Purpose:** Legacy alternative for plotting filled DSR regions and representative boundary points for `beta = 0`, `0.005`, and `0.01`.

**Before running:** Replace the absolute `exportPath` near the beginning of the file with a valid local directory.

**Run:**

```matlab
run('testforknnlightGBthreshold_DSRfilled.m');
```

**Requires:** The three threshold MAT files, Statistics and Machine Learning Toolbox, and Python NumPy/LightGBM.

For new reproductions, prefer `plot_DSR_threshold_and_trajectory_polished_0625.m`, because it uses unified paths, correction settings, and figure formatting.

## Damping-threshold comparison

To compare the learned DSR boundaries for `beta = 0`, `0.005`, and `0.01`, run

```matlab
run('plot_DSR_threshold_and_trajectory_polished_0625.m');
```

The boundary plot uses the included files:

```text
parameter_3_15_0.mat
parameter_3_15_0.005.mat
parameter_3_15_0.01.mat
```

The later trajectory-plotting section also loads `simulation_data_14_493_breaker_1003_2.mat`, which is not included in the present repository. Without that file, the DSR boundary portion can be run, but the representative-trajectory portion cannot be regenerated.

## Regenerating the complete dataset

The intended full workflow is

```text
operating-point sampling
        -> PSAT time-domain simulation
        -> post-disturbance trajectories
        -> KMD damping labels
        -> KNN label correction
        -> ML-based DSR construction
        -> benchmark and consistency assessment
```

The corresponding scripts are:

```text
simulation_datasssa_2genP1003.m
        -> simulation_data_14_493_breaker_1003_2.mat

pfdatatestHankelparameter_1224_0.m
pfdatatestHankelparameter_1224_noise.m
        -> parameter_*.mat

evaluate_KNN_mislabeled_sample_correction_0624.m
build_ML_DSR_test_assessment_0625.m
```

However, the raw simulation stage currently depends on the following external files that are not included in this repository:

```text
s14.mat
modifyfile.m
```

The generated trajectory file is also not included:

```text
simulation_data_14_493_breaker_1003_2.mat
```

Therefore, the repository as provided supports direct reproduction from the included label datasets, but a from-scratch regeneration of all PSAT trajectories requires obtaining the external files above and installing PSAT. Place the external files in the repository root or update the paths in `simulation_datasssa_2genP1003.m` before running it.

The full simulation uses a 50-s time horizon and a 0.05-s fixed time step. Because it processes thousands of operating points, expect the raw simulation stage to require substantially more time and storage than the included-data workflow.

## Data conventions

The principal MAT files use the following variables:

- `parameters`: rows of operating points; the first two columns are the coordinates used to construct the DSR.
- `index`: KMD-derived binary labels.
- `index0`: TDS benchmark labels.
- `Saveopt`: saved steady-state operating quantities from PSAT.
- `time_set1`, `delta_set1`, `omega_set1`: simulated time, relative rotor-angle, and rotor-speed trajectories.

Before comparing two label files, the scripts verify that their `parameters` arrays are aligned sample by sample.

## Test-system and contingency summary

- System base: 100 MVA.
- Nominal frequency: 60 Hz.
- Parameter space: active-power outputs at Buses 2 and 6.
- Sampling ranges: `P_G2` in `[0, 1.4]` p.u. and `P_G6` in `[0, 1.0]` p.u.
- Sampled operating points: 10,000; the reported analysis uses 9,999 valid samples.
- Simulation horizon: 50 s.
- Sampling interval: 0.05 s.

See the detailed-description PDF for the complete network, generator, controller, fault, breaker, and data-processing settings. If a setting in this README and the PDF appears inconsistent, use the PDF and the executable model files as the authoritative sources.

## Troubleshooting

### `Undefined function 'knnsearch'`

Install or enable MATLAB's Statistics and Machine Learning Toolbox.

### `Unable to resolve the name 'py.lightgbm...'`

Check `pyenv`, install `numpy` and `lightgbm` into that same Python environment, and restart MATLAB after changing the interpreter. Alternatively, use `build_ML_DSR_test_assessment_0625.m`, which falls back to MATLAB bagged trees.

### Missing `simulation_data_14_493_breaker_1003_2.mat`

Use the included `parameter_*.mat` files for KNN and DSR experiments, or regenerate the trajectory data after supplying the external PSAT inputs described above.

### Output files appear outside the repository

Some publication scripts construct output paths relative to the original project directory, and the legacy `testforknnlightGBthreshold_DSRfilled.m` contains an absolute Windows path. Change `outputDir` or `exportPath` to a local path before running those scripts on another computer.

### MATLAB cannot start PSAT

Confirm that PSAT is installed and on the MATLAB path, then test `initpsat` in a clean MATLAB session before running the batch simulation.

## Citation

If this repository contributes to published work, please cite the associated paper and the repository. Until the paper's final bibliographic record is available, the repository may be cited as:

```text
J. Liu, "Detailed Description of the Modified IEEE 14-Bus Test System," GitHub repository. [Online]. Available: https://github.com/JuelinLiu/Detailed-Description-of-the-Modified-IEEE-14-Bus-Test-System
```

Please update the paper citation after publication.
