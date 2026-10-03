# MEG connectivity

The MEG connectivity matrices were computed with the pipeline of our earlier study. That pipeline
has its own repository:

> Soyuhos, O., & Baldauf, D. (2023). Functional connectivity fingerprints of the frontal eye field
> and inferior frontal junction suggest spatial versus nonspatial processing in the prefrontal
> cortex. *European Journal of Neuroscience, 57*(7), 1114–1140. https://doi.org/10.1111/ejn.15936

Code: <https://github.com/orhansoyuhos/Functional-connectivity-fingerprints-of-the-FEF-and-IFJ>

The pipeline has two parts:
1. `Analysis_Pipeline/AnalysisPipeline_Part1.m` cleans the HCP resting-state MEG and cuts it into
   epochs, with megconnectome 3.0 and FieldTrip.
2. `Analysis_Pipeline/AnalysisPipeline_Part2.m` reconstructs the sources in Brainstorm and
   extracts the time series of the 360 HCP-MMP1 parcels. It then computes the connectivity in
   each frequency band with FieldTrip.

Settings for this paper:

| setting | value |
|---|---|
| subjects | the 55 subjects of the fMRI and MEG cohort (paper, Section 4.1) |
| epoch length (`trialDuration`) | 2 s |
| measures (`connMetric`) | `'oPEC'`, `'iCOH'` and `'PDC'` |
| frequency bands | delta 1–4, theta 4–8, alpha 8–13, beta 13–30, gamma 30–100 Hz |

The group files used here have the format of the pipeline's group results:
- the files are `Outputs_2s_55subjs_opec.mat`, `Outputs_2s_55subjs_icoh.mat` and
  `Outputs_2s_55subjs_pdc.mat`;
- each holds a struct array `group_results` with one element per band, with the fields `band`,
  `freq_bands`, `label`, `data_perSubject` (360 × 360 × 55) and `data`.

In these files:
- all three measures are computed for all pairs of the 360 parcels (full 360 × 360 matrices);
- the diagonal (a parcel with itself) is NaN;
- the parcels are in the order of `data/atlas/hcp_mmp1_labels.csv`.

[`../make_data.m`](../make_data.m) takes the following from these files:
- the seed rows (FFC and PHA3, both hemispheres);
- each subject's mean over the whole matrix;
- for PDC, also the seed columns.
