#!/bin/bash
# Step 1 (fMRI): normalise each resting-state run and concatenate the four runs.
#
# For each subject and each of the four runs (REST1_LR, REST1_RL, REST2_LR,
# REST2_RL), the ICA-FIX denoised, MSMAll-registered dense time series
#   rfMRI_REST<1|2>_<LR|RL>_Atlas_MSMAll_hp2000_clean.dtseries.nii
# is read from the S3 mount of Step 0, and the time series of every
# grayordinate is normalised: (x - mean) / stdev (Connectome Workbench,
# -cifti-reduce and -cifti-math). The four normalised runs are then
# concatenated in the order above (-cifti-merge) into
#   <main_dir>/<subject>/MNINonLinear/Results/rfMRI_concenatedFourRuns_<subject>.dtseries.nii
# which Step 2 reads. The per-run intermediate folders are deleted afterwards.
#
# Runs in Ubuntu (WSL on Windows). Edit the paths below, then:
#   sudo apt install libgomp1                 # needed by the Linux wb_command
#   sudo bash step1_normalize_concatenate.sh
#
# The subject list is a text file with HCP subject IDs separated by spaces,
# tabs or new lines. It is not part of this repository.
#
# Author: Orhan Soyuhos, 2026
# License: GPL-3.0 (see LICENSE)

# ---- Paths (edit) ------------------------------------------------------------
main_dir=/mnt/c/path/to/HCP_subjects                          # output folder, read by Step 2
wb_command_path=/path/to/workbench/bin_linux64/wb_command      # Connectome Workbench (Linux)
mount_point=/home/your_user/hcp-openaccess/HCP_1200            # HCP 1200 data (Step 0)
subject_list=$main_dir/subject_list_file.txt                   # HCP subject IDs
# ------------------------------------------------------------------------------

# The per-run folders under main_dir are deleted after merging, so main_dir
# must not be the folder that holds the HCP data.
if [ "$main_dir" -ef "$mount_point" ]; then
    echo "main_dir must be a different folder from mount_point." >&2
    exit 1
fi

subjectIDs=( $(tr -d '\r' < "$subject_list") )
for subject in "${subjectIDs[@]}"
do
    echo "Subject $subject"
    for idx in 1 2
    do
        for phaseCode in LR RL
        do
            filename=rfMRI_REST${idx}_${phaseCode}_Atlas_MSMAll_hp2000_clean.dtseries.nii
            file_relative_path=$subject/MNINonLinear/Results/rfMRI_REST${idx}_${phaseCode}
            full_mount_point=$mount_point/$file_relative_path/$filename
            mkdir -p "$main_dir/$file_relative_path"
            cd "$main_dir/$file_relative_path" || exit 1
            if [ ! -f "$full_mount_point" ]; then
                echo "  File does not exist: $full_mount_point"
            fi
            "$wb_command_path" -cifti-reduce "$full_mount_point" MEAN mean.dscalar.nii
            "$wb_command_path" -cifti-reduce "$full_mount_point" STDEV stdev.dscalar.nii
            "$wb_command_path" -cifti-math '(x - mean) / stdev' demeanNormed_$idx$phaseCode.dtseries.nii -fixnan 0 \
                -var x "$full_mount_point" \
                -var mean mean.dscalar.nii -select 1 1 -repeat \
                -var stdev stdev.dscalar.nii -select 1 1 -repeat
        done
    done
    cd "$main_dir/$subject/MNINonLinear/Results" || exit 1
    output_name=rfMRI_concenatedFourRuns_$subject.dtseries.nii
    "$wb_command_path" -cifti-merge "$output_name" \
        -cifti rfMRI_REST1_LR/demeanNormed_1LR.dtseries.nii \
        -cifti rfMRI_REST1_RL/demeanNormed_1RL.dtseries.nii \
        -cifti rfMRI_REST2_LR/demeanNormed_2LR.dtseries.nii \
        -cifti rfMRI_REST2_RL/demeanNormed_2RL.dtseries.nii
    rm -r "$main_dir/$subject/MNINonLinear/Results/rfMRI_REST1_LR" \
          "$main_dir/$subject/MNINonLinear/Results/rfMRI_REST1_RL" \
          "$main_dir/$subject/MNINonLinear/Results/rfMRI_REST2_LR" \
          "$main_dir/$subject/MNINonLinear/Results/rfMRI_REST2_RL"
done
