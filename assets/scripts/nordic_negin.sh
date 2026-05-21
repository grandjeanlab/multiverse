#!/bin/bash
# ----------------------------------------------------------------------
# Script: nordic_denoise.sh
# Purpose: Run NORDIC denoising on preprocessed dataset directories
# Usage: ./nordic_denoise.sh <prepro_dataset_dir> [nordic_path]
#
# Arguments:
#   prepro_dataset_dir : Directory containing preprocessed datasets
#   nordic_path        : Path to NORDIC_Raw-main (default: ./NORDIC_Raw-main)
# ----------------------------------------------------------------------

if [ $# -lt 1 ]; then
    echo "Usage: $0 <prepro_dataset_dir> [nordic_path]"
    exit 1
fi

prepro_dataset_dir=$1
nordic_path=${2:-"./NORDIC_Raw-main"}

for dset_folder in "$prepro_dataset_dir"/*/; do
    for subj_folder in "$dset_folder"bold_datasink/commonspace_bold/*/*/; do
        input_file=$(find "$subj_folder" -name "sub*.nii.gz" | head -n 1)
        if [ -z "$input_file" ]; then
            input_file=$(find "$subj_folder" -name "sub*.nii" | head -n 1)
            if [ -z "$input_file" ]; then
                echo "No input file found in $subj_folder"
                continue
            fi
	fi

	output_dir=$(dirname "$input_file")
        base_filename=$(basename "$input_file")
        output_prefix="NORDIC_${base_filename%.nii.gz}"

        echo "Denoising $input_file -> $output_dir/$output_prefix"

	matlab -singleCompThread -nojvm -nodisplay -nosplash -r "addpath('$nordic_path'); \
    		fn_magn_in='$input_file'; \
    		fn_phase_in='$input_file'; \
    		fn_out='$output_prefix'; \
    		ARG.DIROUT='$output_dir/'; \
    		ARG.temporal_phase=1; \
		ARG.phase_filter_width=10; \
    		ARG.magnitude_only=1; \
    		NIFTI_NORDIC(fn_magn_in, fn_phase_in, fn_out, ARG); \
    		exit;"

    done
done

