# Pipeline description
Joanes Grandjean
2024-06-18

# Summary of the pipelines

|          | SPM    | RABIES                        | DI1             | DI2        |
|----------|--------|-------------------------------|-----------------|------------|
| Workflow | Matlab | Nypipe                        | Bash            | Nypipe     |
| Toolkits | SPM    | ANTS, AFNI, FSL, minc-toolkit | ANTS, AFNI, FSL | ANTS, AFNI |

# Summary of the confound models

|             | SPM                           | RABIES           | DI1        | DI2        |
|-------------|-------------------------------|------------------|------------|------------|
| Bandpass    | 0.001 - 0.1                   | 0.01 - 0.2       | 0.01 - 0.1 | 0.01 - 0.1 |
| Noise model | motion + derivatives + muscle | motion + compcor | ven + vasc | ven + vasc |
| Smoothing   | 0.5                           | 0.5              | 0.4        | 0.4        |

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

Here, the RABIES container was created from the master branch on
20231215

RABIES can be run using: `apptainer run rabies-${VERSION}.sif`

the RABIES script for confound correction stage; for each dataset the
strategy was: FD censoring with threshold of 0.075mm, regression of 6
motion parameters and 5 aCompCor components, bandpass at 0.01-0.2Hz and
smoothing with 0.5mm.

`apptainer run -B /scratch/m/mchakrav/desgab/data/StandardRat:/nii_inputs:ro \ -B /scratch/m/mchakrav/desgab/data_preprocess/preprocess_StandardRat:/preprocess_StandardRat \ -B /home/m/mchakrav/desgab/atlases:/atlases:ro \ -B /scratch/m/mchakrav/desgab/data_preprocess/StandardRat_files:/StandardRat_files \ /home/m/mchakrav/desgab/singularity_images/rabies-master20231215.sif \ -p MultiProc --force  preprocess /nii_inputs /preprocess_StandardRat/rabies_StandardRat3001_20231106 \ --bids_filter /preprocess_StandardRat/preprocess_call/specs_3001.json \ --anatomical_resampling 0.25x0.25x0.25 \ --commonspace_resampling 0.3x0.3x0.3 \ --oblique2card affine \ --anat_template /atlases/jo_template/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_InVivo_Template/SIGMA_InVivo_Brain_Template.nii \ --brain_mask /atlases/jo_template/SIGMA_Wistar_Rat_Brain_TemplatesAndAtlases_Version1.1/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_InVivo_Template/SIGMA_InVivo_Brain_Mask.nii \ --WM_mask /StandardRat_files/WM_mask_eroded.nii.gz \ --CSF_mask /StandardRat_files/CSF_mask_eroded.nii.gz \ --vascular_mask /StandardRat_files/CSF_mask_eroded.nii.gz \ --labels /StandardRat_files/labels_resampled.nii.gz \ --bold_robust_inho_cor apply=true,masking=false,brain_extraction=false,keep_mask_after_extract=false,template_registration=SyN \ --bold_inho_cor method=SyN,otsu_thresh=2,multiotsu=false`

`apptainer run -B /scratch/m/mchakrav/desgab/data/StandardRat:/nii_inputs:ro -B /scratch/m/mchakrav/desgab/data_preprocess/preprocess_StandardRat:/preprocess_StandardRat -B /home/m/mchakrav/desgab/atlases:/atlases:ro -B /scratch/m/mchakrav/desgab/data_preprocess/StandardRat_files:/StandardRat_files /home/m/mchakrav/desgab/singularity_images/rabies-master20231215.sif  --local_threads 5 -p MultiProc --force  confound_correction /preprocess_StandardRat/rabies_StandardRat3001_20231106 /preprocess_StandardRat/rabies_StandardRat3001_20231106/mot6_aCompCor_FD_lowpass0.2 --smoothing_filter 0.5 --image_scaling grand_mean_scaling --conf_list mot_6 aCompCor_5 --frame_censoring FD_censoring=true,FD_threshold=0.075,DVARS_censoring=false,minimum_timepoint=666 --highpass 0.01 --edge_cutoff 30 --lowpass 0.2`

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

## Graphical summary of the RABIES pipeline.

``` mermaid
flowchart TD
  A(BIDS Anat) --> B(Inho correction/Brain mask, minc-toolkit)
  B --> C(Study template, ANTs)
  C --> D(Anat to study template, ANTs)
  B --> D
  D --> E(study template to SIGMA, ANTs)

  
  F(BIDS Func) --> G(Inho correction/Brain mask, minc-toolkit)
  G --> H(Func to Anat, ANTs)
  F --> I(MotionCorr, ANTs)
  I --> J(Func to Anat, ANTs)
  J --> D  
  D --> K(Denoise/bandpass/nuisance regression, RABIES)
  K --> L(Cleaned func in SIGMA)

```

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

\#EDNiX pipeline.

## Owner and use.

Clément garin, Suliann Ben Hamed, Simon Clavagnier.

Pending publication details

## Package summary

| Software | Type                    | Version | License                                                                        |
|----------|-------------------------|---------|--------------------------------------------------------------------------------|
| AFNI     | preprocessing           | \-      | GNU GPL v2                                                                     |
| ANTs     | preprocessing           | \-      | Apache-2                                                                       |
| FSL      | preprocessing           | \-      | [Oxford University Innovation](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Licence) |
| Nipype   | python workflow manager | \-      | Apache-2                                                                       |

## Graphical summary of the EDNiX pipeline.

``` mermaid
A(BIDS Anat) --> B(Anat to SIGMA, ANTS)

C(BIDS Func) --> D(Volume remove, AFNI)
D --> E(Despike, AFNI)
E --> F(Slice timing correction, AFNI)
F --> G(MotionCorr, AFNI)
G --> H(Frame censoring, AFNI)
H --> I(N4, ANTS)
I --> J(distortion correction, FSL)
J --> K(Func to Anat, ANTS)
J --> L(ICA, FSL)
L --> M(denoise, AFNI)
M --> N(apply transforms, ANTS)
J --> N
B --> N
```

# Liming pipeline.

## Owner and use.

Li-Ming Hsu & Yen-Yu Ian Shih

See the bash script for the pipeline [here](assets/pipeline/liming.sh)

Masking done with [2D U-Net](https://doi.org/10.3389/fnins.2020.568614),
[Github](https://github.com/CAMRIatUNC/RodentMRISkullStripping)

## Package summary

| Software | Type          | Version | License    |
|----------|---------------|---------|------------|
| AFNI     | preprocessing | AFNI_x  | GNU GPL v2 |
| ANTs     | preprocessing | x       | Apache-2   |
| FSL      | preprocessing | x       | PSFL       |

## Graphical summary of the Liming pipeline.

``` mermaid
flowchart TD
  A(BIDS Anat) --> B(Mask, 2D U-Net)
  A --> C(Anat to SIGMA, ANTs)
  B --> C
  D --> C

  D(BIDS Func) --> F(Volume remove/MotionCorr, AFNI)
  F --> G(Spatial Smoothing, AFNI)
  G --> H(Despike, AFNI)
  H --> I(Motion regression, AFNI)
  I --> J(Bandpass filter, AFNI)
  J --> K(Orientat, AFNI)
  K --> L(ICA/Denoise, FSL)

  J --> M(WM/CSF masks in SIGMA)
  D --> M
  M --> N(Confound extraction, Nipype)
  N --> K
  G --> O(Volume censoring, ANFI)
  O --> K

```

# Russo pipeline.

## Owner and use.

Russo et al. 

## Pipeline description

Despiking (3dDespike -NEW25) Motion Correction (3dvolreg) Functional
Brain Extraction using fslmaths with existing functional masks (using
BEN) Anatomical Brain Extraction using fslmaths with existing anatomical
masks (using BEN) Spatial Smoothing (3dBlurInMask, dynamically
calculating for each dataset 1.5x the voxel size) Band-Pass Filtering
(0.01-0.1 Hz, 3dTproject polort 2) Registration and Transformation To
Standard SIGMA space (flirt)

Affiliation: Gabriele Russo, Department of Translational Biomedicine and
Neuroscience, University of Bari Aldo Moro, Bari, Italy.
gabriele.russo@uniba.it

## Package summary

| Software | Type          | Version | License                                                                        |
|----------|---------------|---------|--------------------------------------------------------------------------------|
| AFNI     | preprocessing | \-      | GNU GPL v2                                                                     |
| FSL      | preprocessing | \-      | [Oxford University Innovation](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/Licence) |
| BEN      | masking       | \-      | academic                                                                       |

## Graphical summary of the DI2 pipeline.

``` mermaid
flowchart TD
  A(BIDS Anat) --> B(Masking, BEN)
  B --> C(Anat to SIGMA, FSL)
  A --> C(Anat to SIGMA, FSL)
  

  E(BIDS Func) --> F(Despike, AFNI)
  F --> G(MotionCorr, AFNI)
  G --> H(Masking, BEN/FSL)
  H --> I(Smoothing, AFNI)
  I --> J(Bandpass, AFNI)
  J --> K(Func to SIGMA, FSL)  
  C --> L
  K --> L(Cleaned func in SIGMA)

```
