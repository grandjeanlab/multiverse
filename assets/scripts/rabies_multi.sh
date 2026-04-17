#!/bin/sh bash

# author: Joanes Grandjean
# intial date: 05.05.2022
# last modified: 11.04.2026 (Jo)

# changelog
# 11.04.2026 
# adapted to loop rabies with range of confound models
# 8.04.2026 
# add rabies_version to make rabies version selection more explicit
# 29.05.2024
# use the --inclusion_ids flag to run rabies one func at a time
# use the $TMPDIR environment variable to run rabies on /scratch and not on local project folder
# 03.08.2024
# modify it to run on the awake project. 



function make_conf () {
    conf_arg_final="--smoothing_filter ${conf_arg_smooth[conf_id_smooth]} --lowpass ${conf_arg_lowpass[conf_id_lowpass]} --nuisance_regressors ${conf_arg_nuisance_regressors[conf_id_nuisance_regressors]} --frame_censoring ${conf_arg_frame_censoring[conf_id_frame_censoring]}"
    conf_name_final="${conf_name_smooth[conf_id_smooth]}_${conf_name_lowpass[conf_id_lowpass]}_${conf_name_nuisance_regressors[conf_id_nuisance_regressors]}_${conf_name_frame_censoring[conf_id_frame_censoring]}"
}

function write_preprocessing_script () {
  #initialize the script with a bang and slurm header. you can edit the time and mem options if you think you need more or less resources. 
  echo '#!/bin/bash' > $script_file
  echo "#SBATCH --job-name="$func_noext >> $script_file
  echo "#SBATCH --nodes=1" >> $script_file
  echo "#SBATCH --time=12:00:00" >> $script_file
  echo "#SBATCH --mail-type=FAIL" >> $script_file
  echo "#SBATCH --partition=batch" >> $script_file
  echo "#SBATCH --mem=24GB" >> $script_file

  #create temporary folders in scratch folder so you don't clutter your project folder
  echo " " >> $script_file
  echo "module load afni" >> $script_file
  echo "module load fsl" >> $script_file
  echo " " >> $script_file
  echo "#### init varibles and make tmp directories ####" >> $script_file
  echo " " >> $script_file

  echo "preprocess=$""TMPDIR/preprocess" >> $script_file

  echo "mkdir -p $""preprocess" >> $script_file

  echo " " >> $script_file
  echo "#### run RABIES preprocess ####" >> $script_file
  echo " " >> $script_file

  #run the preprocessing step of rabies
  echo "apptainer run "${rabies}" --inclusion_ids "${func_file}" -p Linear preprocess "${bids}" $""{preprocess} "${bold_only}${prep_arg}${trcor} >> $script_file 

  #copy the QC report, motion, and tSNR maps
  echo "cp -r $""{preprocess}/preprocess_QC_report "$output_dir >> $script_file 
  echo "cp -r $""{preprocess}/motion_datasink "$output_dir >> $script_file 
}

function write_confound () {
  echo " " >> $script_file
  echo "#### run RABIES confound/analysis for "${conf_name_final}" ####" >> $script_file
  echo " " >> $script_file

  echo "confound=$""TMPDIR/confound_"${conf_name_final} >> $script_file
  echo "analysis=$""TMPDIR/analysis_"${conf_name_final}>> $script_file
  echo "mkdir -p $""confound" >> $script_file
  echo "mkdir -p $""analysis" >> $script_file 

  #run the confound correction step of rabies
  echo "apptainer run "${rabies}" --inclusion_ids "${func_file}" -p Linear confound_correction $""{preprocess} $""{confound} "${conf_arg_final} >> $script_file 
  #run the analysis step of rabies
  echo "apptainer run "${rabies}" --inclusion_ids "${func_file}" -p Linear analysis $""{confound} $""{analysis} "${analysis_arg} >> $script_file 
  #copy the analysis outputs and the data diagnosis to the output directory
  echo "mkdir -p $output_dir"/"$conf_name_final" >> $script_file
  #echo "cp -r $""confound/confound_correction_datasink/ "$output_dir"/"$conf_name_final >> $script_file 
  echo "cp -r $""analysis/commonspace_analysis_datasink "$output_dir"/"$conf_name_final >> $script_file 

}

function write_cleanup (){
  echo " " >> $script_file
  echo "#### clean up####" >> $script_file
  echo " " >> $script_file

  #clean up scratch
  echo "rm -rf $""TMPDIR/*" >> $script_file 
}


#define what root dir you want to use, where the bids folder is, where the tmp scripts will go, and where the output will go
root_dir="/project/4180000.41/"
bids=$root_dir"/bids_test"
script_dir=$root_dir"/tmp_multiverse_scripts"
output_dir=$root_dir"/output_multiverse"
template_dir="/home/traaffneu/joagra/code/awake/assets/template/rat"
templaters_dir="/home/traaffneu/joagra/code/awake/assets/template/rat"

#define what version of rabies you want to use. run `ls /opt/rabies/` to see what versions are on
rabies_version=0.6.0
rabies="/opt/rabies/${rabies_version}/rabies.sif"


#arguments for RABIES preprocessing, confound regression, analysis. see https://rabies.readthedocs.io/ for more info
prep_arg='--commonspace_resampling 0.3x0.3x0.3 --anatomical_resampling 0.3x0.3x0.3 --detect_dummy --oblique2card 3dWarp --commonspace_reg masking=false,brain_extraction=false,template_registration=SyN,fast_commonspace=true --anat_template '${template_dir}'/template.nii.gz --brain_mask '${template_dir}'/mask.nii.gz --WM_mask '${template_dir}'/wm.nii.gz --CSF_mask '${template_dir}'/csf.nii.gz --vascular_mask '${template_dir}'/csf.nii.gz --TR ' 

#variable arguments for confound correction. these will be looped over to create a separate script for each combination of confound correction steps.
conf_arg_gen=' --highpass 0.01 --read_datasink'

conf_arg_smooth=("0.1" "0.2" "0.3" "0.4" "0.5")
conf_name_smooth=("smooth01" "smooth02" "smooth03" "smooth04" "smooth05")

conf_arg_lowpass=("0.1" "0.15" "0.2" "0.25")
conf_name_lowpass=("lowpass01" "lowpass015" "lowpass02" "lowpass025")

conf_arg_nuisance_regressors=("mot_6 WM_signal CSF_signal" "mot_6 global_signal" "mot_6 aCompCor_percent")
conf_name_nuisance_regressors=("wmcsf" "gsr" "aCompCor")

conf_arg_frame_censoring=("FD_censoring=true,FD_threshold=0.1,DVARS_censoring=true,minimum_timepoint=3" "FD_censoring=true,FD_threshold=0.1,DVARS_censoring=false,minimum_timepoint=3" "FD_censoring=true,FD_threshold=0.5,DVARS_censoring=true,minimum_timepoint=3" "FD_censoring=true,FD_threshold=0.5,DVARS_censoring=false,minimum_timepoint=3")
conf_name_frame_censoring=("FD01_DVARS" "FD01_noDVARS" "FD05_DVARS" "FD05_noDVARS")


#arguments for analysis. these will be the same for all scripts so they don't need to be looped over.
analysis_arg='--seed_list '${template_dir}'/s1_r.nii.gz '${template_dir}'/s1_l.nii.gz '${template_dir}'/aca_r.nii.gz --ROI_labels_file /home/traaffneu/joagra/code/awake/assets/template/mouse/labels.nii.gz --FC_matrix --prior_maps /home/traaffneu/joagra/code/awake/assets/template/rat/ica.nii.gz --DR_ICA --prior_bold_idx 1 2 --prior_confound_idx 3 4 --ROI_labels_file '${template_dir}'/labels.nii.gz --FC_matrix --prior_maps '${template_dir}'/ica.nii.gz --DR_ICA --prior_bold_idx 1 2 --prior_confound_idx 3 4 --data_diagnosis'


mkdir -p $script_dir
cd $script_dir

#this is the main loop. by default, it will loop over every func scan that you have in your bids directory and make a separate script for it. 
find $bids -name *_bold.nii.gz | while read line
do

#need to find the corresponding json to find tr, extract it from json, and div by 1000 to get val in sec.
#json=$(echo $line | sed "s/.nii.gz/.json/g")
#tr=$(grep "RepetitionTime" $json | sed -r 's/"RepetitionTime"://g' | sed "s/[^[:digit:]]//g")
trcor=1
#trcor=`echo $tr / 1000 | bc -l`

#check for anatomical scans
anat_folder=$(dirname $line)
anat_scan=$(dirname $anat_folder)'/anat/*T2w.nii.gz'
bold_only=''
if [ ! -f $anat_scan ]; then
    bold_only=' --bold_only'
fi

#edit the func file name and path for rabies
##replace the full path to the bids directory with a relative path for rabies
func_file=$line

##set the name of the script file that will be created. 
func_base=$(basename $func_file)
func_noext="$(remove_ext $func_base)"

script_file=$script_dir/$func_noext'.sh'

echo "now doing subject "$func_noext
write_preprocessing_script

conf_len_smooth=$((${#conf_arg_smooth[@]}-1))
conf_len_lowpass=$((${#conf_arg_lowpass[@]}-1))
conf_len_nuisance_regressors=$((${#conf_arg_nuisance_regressors[@]}-1))
conf_len_frame_censoring=$((${#conf_arg_frame_censoring[@]}-1))

for conf_id_smooth in $(seq 0 $conf_len_smooth) 
do
  for conf_id_lowpass in $(seq 0 $conf_len_lowpass) 
  do
    for conf_id_nuisance_regressors in $(seq 0 $conf_len_nuisance_regressors) 
    do
      for conf_id_frame_censoring in $(seq 0 $conf_len_frame_censoring) 
      do
        make_conf
        write_confound
      done
    done
  done
done


#end of the loop
done
