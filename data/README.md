# Data

All files were made from the complete per-subject 360 × 360 connectivity matrices
with [`preprocessing/make_data.m`](../preprocessing/make_data.m).
[`preprocessing/`](../preprocessing/README.md) shows how those matrices were computed from the
HCP data.

The underlying data come from the Human Connectome Project, WU-Minn Consortium (HCP 1200
Subjects Release, https://www.humanconnectome.org). These derived data are shared under the
[HCP Open Access Data Use Terms](https://www.humanconnectome.org/study/hcp-young-adult/document/wu-minn-hcp-consortium-open-access-data-use-terms),
and anyone using them agrees to those terms. No subject identifiers are included. Subjects
appear in the same order in all files of a cohort.

## Connectivity, 55 subjects (MEG and fMRI cohort)

The files are MAT files (MATLAB v7). Each holds one struct, `conn`, with these fields.

| field | content |
|---|---|
| `labels` | 360 × 1 HCP-MMP1 parcel labels such as `L_V1_ROI L`: 1–180 left and 181–360 right hemisphere, each in character order (as in `atlas/hcp_mmp1_labels.csv`) |
| `seeds` | seed parcel labels, the first dimension of `rows` and `cols` |
| `rows` | seeds × 360 × 55 (× 5 bands): connectivity of each seed with the parcels of its own hemisphere (seed → parcel for PDC); NaN for the other hemisphere |
| `cols` | PDC only, the same size: parcel → seed |
| `wb_mean` | not for PDC. 55 × 1 (× 5 bands): each subject's mean over the whole 360 × 360 matrix, `squeeze(mean(mean(X, 'omitnan')))`; the baseline of the seed maps. For fMRI the diagonal (0) is part of this mean; for MEG the diagonal is NaN and is left out |
| `bands`, `band_edges` | MEG: delta, theta, alpha, beta, gamma (1–4, 4–8, 8–13, 13–30, 30–100 Hz) |

| file | measure | seeds |
|---|---|---|
| `fmri_55subjs_seed_connectivity.mat` | resting-state fMRI, ridge-regularised partial correlation (FSLNets `nets_netmats`, ridgep 0.01) | FFC, PHA3, PHA2 (L, R) |
| `meg_55subjs_seed_connectivity_opec.mat` | MEG orthogonalised power-envelope correlation | FFC, PHA3 (L, R) |
| `meg_55subjs_seed_connectivity_icoh.mat` | MEG imaginary part of coherency | FFC, PHA3 (L, R) |
| `meg_55subjs_seed_connectivity_pdc.mat` | MEG partial directed coherence (`rows` and `cols`), only for the 33 target regions of Table 1 (NaN for the other parcels) | FFC, PHA3 (L, R) |

PHA2 is the anterior-PPA seed of the control analysis (Section 2.5).

## CPM cohort, 371 subjects (one per family)

- **`fmri_371subjs_network_connectivity.mat`**: struct `cpm`.
  - `labels`: the 78 parcels that belong to any CPM network.
  - `data`: 78 × 78 × 371 fMRI partial correlations. Both triangles are kept, because the CPM
    sums over the full matrices.
- **`behaviour_371subjs.csv`**: one row per subject, in the same order. Numbers are written
  with 17 significant digits, so they are read back exactly.

  | column | content |
  |---|---|
  | `row` | row number (1–371); no HCP subject identifiers are included |
  | `Emotion_Task_Face_Median_RT`, `Emotion_Task_Face_Acc` | face-matching task: median RT of correct trials (ms) and accuracy (%) |
  | `WM_Task_0bk_Place_Median_RT`, `WM_Task_0bk_Place_Acc` | 0-back scene task |
  | `WM_Task_2bk_Place_Median_RT`, `WM_Task_2bk_Place_Acc` | 2-back scene task |
  | `mean_FD` | mean framewise displacement of the resting-state fMRI (mm). Subjects above 0.15 mm are excluded |

## Atlas and surface

| file | content |
|---|---|
| `atlas/hcp_mmp1_labels.csv` | the 360 parcel labels in data order |
| `atlas/roi_groups.csv` | the 33 target regions in the order of the circular graphs, with their group (V, MT+, …) and colour (Figure 3A) |
| `atlas/region_names.csv` | the region descriptions used in Tables 1, S2 and S3 |
| `surface/fsaverage_15k_inflated70_hcpmmp1.mat` | fsaverage cortical surface (15002 vertices, inflated 70 %, from Brainstorm) with the HCP-MMP1 parcel of each vertex; used for all brain maps |

The HCP-MMP1 parcellation (Glasser et al., 2016) is distributed under the HCP data use terms.
