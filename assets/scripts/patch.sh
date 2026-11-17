#!/bin/bash
#SBATCH --job-name=patch
#SBATCH --nodes=1
#SBATCH --time=70:00:00
#SBATCH --mail-type=FAIL
#SBATCH --partition=batch
#SBATCH --mem=32GB


root_dir="/project/4180000.41"
patch_singularity="/project/4180000.41/patch-denoise.sif"

rm -rf $root_dir/bids_patch
rm -rf $root_dir/bids_nordic
#copy bids to bids_patch
cp -r $root_dir/bids $root_dir/bids_patch
cp -r $root_dir/bids $root_dir/bids_nordic

fd bold.nii.gz $root_dir/bids_patch | while read line
do

echo "now doing "$line

mask=$(sed "s/bold.nii.gz/bold_mask.nii.gz/" <<< "$line")
denoise=$(sed "s/func\/sub-/func\/Dsub-/" <<< "$line")
noise=$(sed "s/bold.nii.gz/bold_noise_std.nii.gz/" <<< "$denoise")

apptainer run ${patch_singularity} --cpu --method optimal-fro --mask ${mask} --outmap.noise-std ${line}

denoise=$(sed "s/func\/sub-/func\/Dsub-/" <<< "$line")

rm $line
mv $denoise $line

noise_nordic=$(sed "s/bids_patch/bids_nordic/" <<< "$noise")
cp $noise $noise_nordic

tmp_dir=$(dirname $line)
touch $tmp_dir/done

done



fd bold.nii.gz $root_dir/bids_nordic | while read line
do

echo "now doing "$line

mask=$(sed "s/bold.nii.gz/bold_mask.nii.gz/" <<< "$line")
denoise=$(sed "s/func\/sub-/func\/Dsub-/" <<< "$line")
noise=$(sed "s/bold.nii.gz/bold_noise_std.nii.gz/" <<< "$denoise")

apptainer run ${patch_singularity} --cpu --method nordic --mask ${mask} --noise-std-map ${noise} ${line}

rm $line
mv $denoise $line

tmp_dir=$(dirname $line)
touch $tmp_dir/done


done

