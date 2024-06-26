# Pipeline description
Joanes Grandjean
2024-06-18

# SPM pipeline

## Owner and description.

Tong Chuanjun & Liang Zhifeng

Pre-processing was performed utilizing custom scripts in MATLAB 2020a
(MathWorks, Natick, MA) and [SPM12](http://www.fil.ion.ucl.ac.uk/spm/).
Firstly, the voxel size of anatomical and functional images of each scan
was magnified ×10 folds, resulting comparable brain size to human brain
and thus suitable to use SPM12 default parameters for preprocessing.
Secondly, functional images of each scan were realigned to the first
volume for motion correction (SPM 12, realignment) and registered to the
scan-specific anatomical image utilizing rigid body transformation (SPM
12, coregistration). Then, for each anatomical image, the rat brain was
extracted manually using [ITK-SNAP version
3.8.0](http://www.itksnap.org/). After that, for each session, the
masked anatomical image was then nonlinearly transformed to the (×10
magnified) SIGMA rat brain templates (SPM 12, oldnormalize) with a
common space resampling to 3 × 3 × 3 mm3 (i.e., 0.3 × 0.3 × 0.3 mm3 for
raw data), and the transformation matrix was applied to the
corresponding functional images. Next, a light spatial smoothing (SPM
12, smooth) was achieved using a 5 mm isotropic Gaussian kernel (i.e.,
0.5 mm Gaussian kernel for raw data). Furthermore, BOLD signals were
regressed by “6 rp + 6 Δrp + 10 PCs” nuisance signals (MATLAB function
regress) to minimize the effects of scanner drift, motion and other
non-neural physiological noises (ref 1 2 3). “6 rp + 6 Δrp” nuisance
signals represented 6 head motion parameters and their 1st order first
derivatives, and “10 PCs” were the first 10 principal components from
the BOLD signals of non-brain tissue, e.g., the muscles. Finally, the
denoised BOLD signals were band-pass filtered to eliminate both
low-frequency drift effects and high frequency noise, thus retaining
frequencies between 0.001 and 0.1 Hz. The first three head motion
parameters and voxel size of pre-processed images was reduced by 10
folds for transforming the magnified rat brain into the SIGMA space.

Ref 1. Chen, X. and Tong, C. et al. Sensory evoked fMRI paradigms in
awake mice. Neuroimage 204, 116242 (2020). Ref 2. Tong, C. et
al. Multimodal analysis demonstrating the shaping of functional
gradients in the marmoset brain. Nat. Commun. 13, 6584 (2022). Ref 3.
Yu, Y. and Qiu, Y. et al. Sleep fMRI with simultaneous electrophysiology
at 9.4 T in male mice. Nat Commun 14, 1651 (2023)

## Package summary

| Software | Type          | Version | License    |
|----------|---------------|---------|------------|
| Matlab   | scripting     | 2020a   | Mathwork   |
| SPM      | preprocessing | 12      | GNU GPL v2 |
| ITK-SNAP | visualisation | 3.8.0   | GNU GPL v3 |

## Graphical summary of the DI1 pipeline.

``` mermaid
flowchart TD
  A(BIDS Anat) --> B(10x voxel size, Matlab)
  B --> C(Brain mask, ITK-snap)
  C --> D(Anat to SIGMA, SPM)
  
  E(BIDS Func) --> F(10x voxel size, Matlab)
  F --> G(MotionCorr, SPM)
  G --> J(Func to Anat, SPM)
  J --> D  
  D --> K(Smoothing, SPM)
  K --> L(Nuisance regression, Matlab)
  L --> M(Bandpass, Matlab)
  M --> N(Return to original voxel size, Matlab)
  N --> O(Cleaned func in SIGMA)
```

# RABIES pipeline

## Owner and use.

Gabriel Desrosiers-Grégoire & CoBrALab

[RABIES](https://github.com/CoBrALab/RABIES) stands for “Rodent
Automated Bold Improvement of EPI Sequences”. RABIES has been featured
notably in the MultiRAT project and tested to run on rodents datasets
from multiple sources. RABIES includes a preprocessing module, a
confound correction module, and an analysis module that carries some of
the most common functional connectivitiy analysis methods. RABIES is
designed to work with the [BIDS](https://bids.neuroimaging.io/) standard
and to be run reproducbily using Docker/apptainer.

## Reproducible installation

You can get the latest version of RABIES
[here](https://github.com/CoBrALab/RABIES/releases).

RABIES can be run using: `apptainer run rabies-${VERSION}.sif`

## Package summary

| Software     | Type                   | Version      | License                                                                        |
|--------------|------------------------|--------------|--------------------------------------------------------------------------------|
| Ubuntu       | OS                     | 22.04        | Canonical                                                                      |
| RABIES       | Workflow manager       | 0.5.1        | CoBrALab                                                                       |
| AFNI         | preprocessing          | AFNI_23.3.06 | GNU GPL v2                                                                     |
| ANTs         | preprocessing          | 2.5.0        | Apache-2                                                                       |
| fslconda     | preprocessing          | 2309.1       | [Oxford University Innovation](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Licence) |
| minc-toolkit | preprocessing          | 1.9.18       | GNU GPL v3                                                                     |
| micromamba   | python package manager | 1.5.1        | BSD-3                                                                          |

### Additional software

| Software         | Type               | Version  | License         |
|------------------|--------------------|----------|-----------------|
| Apptainer        | Container platform | 1.1.5    | BSD-3           |
| Slurm (optional) | Workflow manager   | 22.05.10 | unknown license |

# DI1 pipeline

## Owner and use.

Joanes Grandjean.

The pipeline is available
[here](https://github.com/grandjeanlab/MouseMRIPrep). It is an evolution
of Zerbi 2015, Grandjean 2019, and Grandjean 2020. The latest version
dropped FIX, which is too hard to implement, and implemented BEN for
brain masking to replace MM_RAT and/or custom brain masking adaptations
of ANTs’ [routines](https://github.com/grandjeanlab/MouseANTs.git). The
latest version also uses the SLURM scheduler for mass parallel
processing (but this can be turn off in the script)

## Reproducible installation

The software is run within a container using the
[neurodocker](https://www.repronim.org/neurodocker/) to generate a
reproducible definition file. I use the apptainer/singularity container
format which is available for GNU/Linux systems.

`apptainer run docker://repronim/neurodocker:latest generate singularity --pkg-manager yum --base-image fedora:36 --yes --afni method=binaries version=latest --ants version=2.4.3 --fsl version=6.0.6 --run-bash "yum install -y -q git; mkdir -p /opt/MouseANTs; git clone https://github.com/grandjeanlab/MouseANTs.git /opt/MouseANTs;  cd /opt/MouseANTs; chmod +x *.sh; export PATH=/opt/MouseANTs:$PATH" > di1`

The container is then built with `apptainer build di1.sif di1`

The container and bash script is then run with the following.
`apptainer shell di1.sif`

## Package summary

| Software                              | Type          | Version      | License                                                                        |
|---------------------------------------|---------------|--------------|--------------------------------------------------------------------------------|
| Fedora                                | OS            | 36           | MIT                                                                            |
| AFNI                                  | preprocessing | AFNI_24.1.17 | GNU GPL v2                                                                     |
| ANTs                                  | preprocessing | 2.4.3        | Apache-2                                                                       |
| FSL                                   | preprocessing | 6.0.6        | [Oxford University Innovation](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Licence) |
| bash                                  | scripting     | 5.2.15       | GNU GPL v3                                                                     |
| [BEN](https://github.com/yu02019/BEN) | brain masking | 0.2          | non commercial                                                                 |

### Additional software

| Software         | Type                                 | Version  | License         |
|------------------|--------------------------------------|----------|-----------------|
| Neurodocker      | Container definition file generation | 1.0      | Appache-2       |
| Apptainer        | Container platform                   | 1.1.5    | BSD-3           |
| Slurm (optional) | Workflow manager                     | 22.05.10 | unknown license |

## Graphical summary of the DI1 pipeline.

``` mermaid
flowchart TD
  A(BIDS Anat) --> B(Deoblique/Reorient, AFNI)
  B --> C(N4/Denoise, ANTs)
  C --> D(Anat to SIGMA, ANTs)
  C --> J
  D --> L
  A --> R(Brain mask, BEN)
  R --> D


  E(BIDS Func) --> F(Deoblique/Reorient, AFNI)
  F --> G(Despike/MotionCorr, AFNI)
  G --> H(Temporal mean, ANTs)
  H --> I(N4, ANTs)
  I --> J(Func to Anat, ANTs)
  J --> L  
  G --> K(Denoise/bandpass/nuisance regression, AFNI)
  K --> L(Cleaned func in SIGMA)

  J --> M(WM/CSF masks in SIGMA)
  D --> M
  M --> N(Confound extraction, FSL)
  N --> K
  G --> O(Volume censoring, ANFI)
  O --> K
  E --> S(Brain mask, BEN)
  S --> J

```

# DI2 pipeline.

## Owner and use.

Joanes Grandjean.

Derivative of the DI1 pipeline. Designed to only use fully permissive
software for commercial use (e.g. no FSL). Released under the Apache-2
license with this repository.

## Reproducible installation

The software is run within a container using the
[neurodocker](https://www.repronim.org/neurodocker/) to generate a
reproducible definition file. I use the apptainer/singularity container
format which is available for GNU/Linux systems.

`apptainer run docker://repronim/neurodocker:latest generate singularity --pkg-manager yum --base-image fedora:36 --yes --afni method=binaries version=latest --ants version=2.4.3 --miniconda version=latest env_name=nipype pip_install="nipype pybids nilearn" > di2`

The container is then built with `apptainer build di2.sif di2`

The container and python script is then run with the following.
`apptainer shell di2.sif` `python di2_script.py`

## Package summary

| Software | Type                    | Version      | License    |
|----------|-------------------------|--------------|------------|
| Fedora   | OS                      | 36           | MIT        |
| AFNI     | preprocessing           | AFNI_24.1.17 | GNU GPL v2 |
| ANTs     | preprocessing           | 2.4.3        | Apache-2   |
| python3  | scripting               | 3.12.3       | PSFL       |
| conda    | python package manager  | 24.5.0       | BSD-3      |
| Nipype   | python workflow manager | 1.8.6        | Apache-2   |

### Additional software

| Software    | Type                                 | Version | License   |
|-------------|--------------------------------------|---------|-----------|
| Neurodocker | Container definition file generation | 1.0     | Appache-2 |
| Apptainer   | Container platform                   | 1.1.5   | BSD-3     |

## Graphical summary of the DI2 pipeline.

``` mermaid
flowchart TD
  A(BIDS Anat) --> B(Deoblique/Reorient, AFNI)
  B --> C(N4/Denoise, ANTs)
  C --> D(Anat to SIGMA, ANTs)
  C --> J
  D --> L
  

  E(BIDS Func) --> F(Deoblique/Reorient, AFNI)
  F --> G(Despike/MotionCorr, AFNI)
  G --> H(Temporal mean, ANTs)
  H --> I(N4, ANTs)
  I --> J(Func to Anat, ANTs)
  J --> L  
  G --> K(Denoise/bandpass/nuisance regression, AFNI)
  K --> L(Cleaned func in SIGMA)

  J --> M(WM/CSF masks in SIGMA)
  D --> M
  M --> N(Confound extraction, Nipype)
  N --> K
  G --> O(Volume censoring, ANFI)
  O --> K

```
