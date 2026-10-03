# Preprocessing: from the HCP data to `data/`

These scripts compute the connectivity matrices behind [`data/`](../data/README.md) from the
HCP 1200 Subjects Release. `run_all` starts from `data/`, so they are needed only to rebuild
`data/` from the HCP data, which are not part of this repository.

```text
HCP 1200 Subjects Release
│
├─ fMRI   fmri/
│    step 0   mount the HCP Amazon S3 bucket                        step0_mount_hcp_s3.sh
│    step 1   normalise each of the 4 runs, concatenate them        step1_normalize_concatenate.sh
│    step 2   360 parcel time series → 360 × 360 matrices           step2_parcellate_netmats.m
│             → Outputs_<N>subjs_partialcorr_rfMRI_MEAN.mat
│
├─ MEG    pipeline of Soyuhos & Baldauf (2023), in its own repository (meg/README.md)
│             → Outputs_2s_55subjs_{opec,icoh,pdc}.mat
│
└─ make_data.m   seed rows, network matrices, behaviour → data/
```

## fMRI

The steps follow Smith et al. (2013), as described in Section 4.4 of the paper.

| step | script | runs in | what it does |
|---|---|---|---|
| 0 | `fmri/step0_mount_hcp_s3.sh` | Ubuntu (WSL on Windows) | mounts the HCP Open Access S3 bucket with s3fs, using your own HCP AWS keys |
| 1 | `fmri/step1_normalize_concatenate.sh` | Ubuntu (WSL on Windows) | reads the four resting-state runs (`rfMRI_REST{1,2}_{LR,RL}_Atlas_MSMAll_hp2000_clean.dtseries.nii`: ICA-FIX denoised, MSMAll-registered, 1200 frames each), normalises each grayordinate's time series, (x − mean)/stdev, and concatenates the runs into one file of 4800 frames |
| 2 | `fmri/step2_parcellate_netmats.m` | MATLAB | averages the time series within each of the 360 HCP-MMP1 parcels (`wb_command -cifti-parcellate`, MEAN), computes the ridge-regularised partial correlation (`nets_netmats(ts, 0, 'ridgep', 0.01)`), takes `tanh`, orders the parcels as in `data/atlas/hcp_mmp1_labels.csv` and saves the group file |

Step 2 writes `Outputs_<N>subjs_partialcorr_rfMRI_MEAN.mat`, with a struct `group_results`:
`data_perSubject` (360 × 360 × N), `data` (the mean over subjects), `label` and `band`. It is run
for the 55- and the 371-subject cohorts.

**Requirements**
- [Connectome Workbench](https://www.humanconnectome.org/software/connectome-workbench)
  (`wb_command`): the Linux version for Step 1 (it needs `sudo apt install libgomp1`) and the
  Windows version for Step 2.
- [cifti-matlab](https://github.com/Washington-University/cifti-matlab) (`cifti_read`).
- [FSLNets](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FSLNets) v0.6.2 (`nets_netmats`).
- s3fs, and an HCP account with Amazon S3 access (Step 0).

Edit the paths at the top of each script before running it.

**Subjects.** The lists of subject IDs are not part of this repository. Section 4.1 of the paper
describes the two cohorts:
- 55 of the 95 subjects with MEG data, one per twin pair;
- 371 subjects with resting-state fMRI and the task data, each from a different family.

Put the IDs of a cohort in `subject_list_file.txt` in the subjects folder, separated by spaces,
tabs or new lines. Their order is the order of the subjects in the output files. For the
371-subject cohort, it is also the order of the rows of `data/behaviour_371subjs.csv`.

**Parcellation.** The file
`fmri/parcellation/Q1-Q6_RelatedValidation210.CorticalAreas_dil_Final_Final_Areas_Group_Colors.32k_fs_LR.dlabel.nii`
is the HCP-MMP1.0 atlas (Glasser et al., 2016), from
[BALSA](https://balsa.wustl.edu/file/show/3VLx). It is distributed under the HCP data use terms.
- Its label keys 1–180 are the right hemisphere and 181–360 the left.
- `wb_command` sorts the parcels by key, and Step 2 lists them in that order before reordering
  them.

## MEG

See [`meg/README.md`](meg/README.md).

## Building `data/`

`make_data.m` reads:
- the fMRI and MEG group files;
- the behavioural scores and head motion of the 371-subject cohort;
- the fsaverage surface with the HCP-MMP1 parcels.

It writes everything in `data/`. Run it from the repository root:

```matlab
addpath('preprocessing')
make_data(source_dir)
```

`source_dir` holds the group files in `connMatrices/rfMRI/` and `connMatrices/rMEG/`; the header
of `make_data.m` lists every input file. The behavioural scores (`behaviScores/`) and the
head-motion values (`headMotion/`) are prepared from the HCP data; no script for them is
included.

## References

- Glasser, M. F., et al. (2016). A multi-modal parcellation of human cerebral cortex. *Nature,
  536*, 171–178. https://doi.org/10.1038/nature18933
- Smith, S. M., et al. (2013). Resting-state fMRI in the Human Connectome Project. *NeuroImage,
  80*, 144–168. https://doi.org/10.1016/j.neuroimage.2013.05.039
- Soyuhos, O., & Baldauf, D. (2023). Functional connectivity fingerprints of the frontal eye
  field and inferior frontal junction suggest spatial versus nonspatial processing in the
  prefrontal cortex. *European Journal of Neuroscience, 57*(7), 1114–1140.
  https://doi.org/10.1111/ejn.15936
