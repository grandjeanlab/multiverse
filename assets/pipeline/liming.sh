# Define file path and subject numbers
FILE_PATH="Data/"
NUMS="300100 300101 300102 300103 300104 300105 300106 300107 300108 300109"

# Loop through each subject
for ratNum in $NUMS; do
	
	
	
  #### masking options: 1. manually 2. 3dSkullStrip from AFNI, and 3. 2D U-Net from our previous publication 'Automatic Skull Stripping of Rat and Mouse Brain MRI Data Using U-Net' https://doi.org/10.3389/fnins.2020.568614 (install from https://github.com/CAMRIatUNC/RodentMRISkullStripping)
  

  #### Step 1: ANTs Registration ####
  # Purpose: Normalized T2 image to Template and apply transformations to align functional data with a template.
  antsRegistrationSyN.sh -d 3 -f sigma_wistar_rat_brain_templatesandatlases_version_2.0/SIGMA_Rat_Anatomical_Imaging/SIGMA_Rat_Anatomical_InVivo_Template/anatomy/SIGMA_InVivo_Anatomical_Brain_template_masked.nii.gz \
  	-m ${FILE_PATH}sub-${ratNum}_T2w_masked.nii.gz \
  	-o ${FILE_PATH}sub-${ratNum}_T2w_masked_ANTs -t s -n 4
  
  antsApplyTransforms -d 3 -e 3d

  #### Step 2: Remove Initial Volumes ####
  # Purpose: Exclude first 5 volumes to remove scanner warm-up artifacts.
  rm ${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5.nii.gz
  3dcalc -a "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped.nii.gz[5..999]" \
         -expr 'a' \
         -prefix ${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5.nii.gz


  #### Step 3: Motion Correction ####
  # Purpose: Correct for head motion between volumes.
  rm "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_parameters"
  rm "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg.nii.gz" 
  3dvolreg -tshift 0 -zpad 4 \
           -prefix "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg.nii.gz" \
           -1Dfile "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_parameters" \
           ${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5.nii.gz


  #### Step 4: Spatial Smoothing ####
  # Purpose: Apply spatial smoothing to reduce noise.
  rm "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur.nii.gz"
  3dmerge -doall -1blur_fwhm 0.6 \
          -prefix "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur.nii.gz" \
          "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg.nii.gz"


  #### Step 5: Remove Spikes ####
  # Purpose: Remove extreme values to reduce outlier effects.
  rm "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike.nii.gz"
  3dDespike -NEW25 -prefix "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike.nii.gz" \
            -nomask "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur.nii.gz"

  #### Step 6: Remove Motion Effects ####
  # Purpose: Regress out motion parameters to mitigate motion-induced artifacts.
  rm "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion.nii.gz"
  3dDeconvolve -input "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike.nii.gz" \
               -local_times -polort 7 -jobs 11 -num_stimts 6 \
               -fitts "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion_fitts_IM" \
               -errts "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion.nii.gz" \
			   -stim_file 1 "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_parameters"'[0]' 								\
			   -stim_label 1 "roll" 													\
			   -stim_base 1														\
			   -stim_file 2 "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_parameters"'[1]' 								\
			   -stim_label 2 "pitch" 													\
			   -stim_base 2														\
			   -stim_file 3 "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_parameters"'[2]' 								\
			   -stim_label 3 "yaw" 													\
			   -stim_base 3														\
			   -stim_file 4 "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_parameters"'[3]' 								\
			   -stim_label 4 "DS" 													\
			   -stim_base 4														\
			   -stim_file 5 "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_parameters"'[4]' 								\
			   -stim_label 5 "DL" 													\
			   -stim_base 5														\
			   -stim_file 6 "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_parameters"'[5]' 								\
			   -stim_label 6 "DP" 													\
			   -stim_base 6														\
			   -nobucket



  #### Step 7: Bandpass Filtering ####
  # Purpose: Retain frequencies within the range of interest (0.01–0.15 Hz).
  rm "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion_bandpass015.nii.gz"
  3dBandpass -prefix "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion_bandpass015.nii.gz" \
             -band 0.01 0.15 \
             "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion.nii.gz"

  #### Step 8: Add Mean Signal Back ####
  # Purpose: Add mean signal back to preserve original signal intensity.
  rm "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_mean.nii.gz"
  3dTstat -mean -prefix "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_mean.nii.gz" \
          "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur.nii.gz"
  rm "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion_bandpass015_admean.nii.gz"
  3dcalc -a "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion_bandpass015.nii.gz" \
         -b "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_mean.nii.gz" \
         -expr 'a+b' \
         -prefix "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion_bandpass015_admean.nii.gz"



  #### Step 9: Mask Data ####
  # Purpose: Apply a brain mask to isolate brain voxels.
  rm "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion_bandpass015_admean_masked.nii.gz"
  3dcalc -a "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion_bandpass015_admean.nii.gz" \
         -b sigma_wistar_rat_brain_templatesandatlases_version_2.0/SIGMA_Rat_Functional_Imaging/SIGMA_InVivo_Functional_Brain_mask.nii.gz \
         -expr 'a*b' \
         -prefix "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion_bandpass015_admean_masked.nii.gz"

  #### Step 10: Orientation Adjustment ####
  # Purpose: Adjust image orientation to standard LIA format for ICA display.
  3dresample -orient LIA \
             -inset "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion_bandpass015_admean_masked.nii.gz" \
             -prefix "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion_bandpass015_admean_masked_LIA.nii.gz"

  #### Step 11: Independent Component Analysis (ICA) ####
  # Purpose: Perform ICA to identify and separate noise components from the signal.
  rm -r "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion_bandpass015_admean_masked_LIA"
  melodic -i "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion_bandpass015_admean_masked_LIA.nii.gz" \
          -o "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion_bandpass015_admean_masked_LIA" \
          --nobet -d 35 -a concat --report --Oall


  #### Step 12: Denoising (Optional) ####
  # Purpose: Use ICA components to remove noise and generate a cleaned dataset.
  rm "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion_highpass_admean_masked_denoise.nii.gz"
  fsl_regfilt -i "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion_bandpass015_admean_masked_LIA.nii.gz" \
              -d "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion_bandpass015_admean_masked_LIA/melodic_mix" \
              -o "${FILE_PATH}sub-${ratNum}_task-rest_bold_ANTsWarped_rm5_volreg_blur_despike_rmmotion_highpass_admean_masked_denoise.nii.gz" \
              -f "7, 18, 27"  # Adjust component indices as necessary for your data.

done
