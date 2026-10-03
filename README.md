# Face and scene connectivity

Analysis code for:

> Soyuhos, O., Scarpa, A., & Baldauf, D. (2026). Distinct resting-state connectomes for face
> and scene perception predict individual task performance. *Human Brain Mapping*, 47(5),
> e70498. https://doi.org/10.1002/hbm.70498

`run_all` runs all analyses and makes the figures and tables of the paper from the data
in [`data/`](data/README.md):

```matlab
run_all                      % everything, as in the paper
run_all('Permutations', 0)   % skip the CPM permutation tests (about 2 minutes in total)
```

Without the permutation tests, the CPM p-values are not computed, and Figures 5, 6 and S5 are
drawn without the null-distribution insets.

## Figures and tables

| paper | analysis | figure / table | output in `results/` |
|---|---|---|---|
| Figure 1C/D, Tables S2/S3 | `a01_fmri_seed_maps` | `f01_figure1`, `tables.R` | `figures/figure1.png` (panels C and D), `tables/table_S2*`, `table_S3*` |
| Figure 2, Table 1 | `a02_fmri_contrast` | `f02_figure2`, `tables.R` | `figures/figure2.png`, `tables/table1*` |
| Figure 3 | `a04_meg_roi` | `f03_figure3` | `figures/figure3.png` |
| Figures S1, S2 | `a03_meg_wholebrain` | `f04_figures_S1_S2` | `figures/figureS1.png`, `figureS2.png` |
| Figure S3 | `a04_meg_roi` | `f05_figure_S3` | `figures/figureS3.png` |
| Figures 5, 6, S5; CPM results of Sections 2.4 and 2.5 | `a05_cpm` | `cpm_figures.R` | `figures/figure5.png`, `figure6.png`, `figureS5.png`, `tables/cpm_summary.csv`, `cpm_bootstrap_ci.csv` |
| Figure S4, behaviour (Section 2.4), head motion (Section 4.6) | `a06_behaviour` | `figure_S4.R` | `figures/figureS4.png`, `tables/behaviour_*.csv` |

Analyses are in `code/analysis/`, MATLAB figures in `code/figures/`, R scripts in `code/R/`.
Each panel of the MATLAB figures is also saved as its own PNG in `results/figures/panels/`.

Not made by this code: the identification of the seed regions (Figure 1A/B and Table S1, made
with Neurosynth, AFNI and MRIcroGL) and the task illustrations of Figure 4.

## Requirements

- **MATLAB** (tested with R2023a) with the Statistics and Machine Learning Toolbox.
  - The Parallel Computing Toolbox is optional. It runs the permutation tests in parallel; the results are the same.
- **R** (tested with 4.4.1) with `ggplot2` (≥ 3.5), `patchwork`, `boot` and `gt`.
  - Optional: `webshot2` with Chrome, for PNG versions of the tables.
  - Optional: `systemfonts`, to use Arial.
  - `run_all` finds `Rscript` on the PATH or in the default install folder. Otherwise set `cfg.rscript` in `config.m`.

No other toolbox is needed to run the analyses. The FDR function `fdr_bh` is included in
`code/external/`. The preprocessing scripts in `preprocessing/` have their own requirements.

## Run time

Measured on a 20-core Windows PC:
- **Without permutations:** 1.5–2.5 minutes for the whole pipeline (`results/RUN_LOG.md` lists
  each step).
- **Permutation tests (12 models × 1000 iterations):** 50 iterations of all 12 models took
  2.5 minutes with the parallel pool, which puts the full 1000 at about 45 minutes. Without the
  pool, a single MATLAB session is several times slower.

`config.m` sets the number of iterations (`cfg.cpm.n_permutations`, default 1000 as in the
paper) and whether to use the parallel pool.

## Analysis details

**Connectivity statistics (Figures 1–3, S1–S3, Tables 1, S2, S3)**
- Each target parcel gets a paired Wilcoxon signed-rank test across the 55 subjects (`signrank`).
- FDR: Benjamini–Hochberg over all tested parcels (`fdr_bh`, `'pdep'`, q = 0.05). For the whole-hemisphere analyses (fMRI and MEG) these are the 180 parcels of one hemisphere; for the MEG analyses of the target regions (Figures 3 and S3), the 33 regions of Table 1.
- z-scores are computed from the adjusted p-values: |Φ⁻¹(p/2)| for two-sided tests, |Φ⁻¹(p)| for one-sided tests. The brain maps and the circles of Figure 2B show the signed z-score (column `stat` of the `*_all_parcels.csv` tables), which is 0 for non-significant parcels; column `z` gives |z| for every parcel. Tables 1, S2 and S3 list |z| for the significant parcels.
- **Seed maps:** the seed's connectivity with each parcel against the subject's mean connectivity over the whole 360 × 360 matrix. One-sided test.
- **FFA vs PPA:** paired comparison of the two seeds' connectivity with each parcel. Two-sided test.
- **Directionality (PDC):** seed → region against region → seed, for each region. Two-sided test.
- Each seed's connectivity with itself is set to 1, and the seed is one of the 180 tested parcels of its hemisphere.
- **Both hemispheres (Figures 3, S3):** z = (z_L + z_R)/√2, with a non-significant hemisphere counted as 0. A line is drawn when the region is significant in at least one hemisphere. The line width is proportional to |z|.

**Connectome-based predictive modelling (Figures 5, 6, S5)**
- **Exclusions:** subjects with mean framewise displacement above 0.15 mm or a missing score.
- **Edge selection:** leave-one-out cross-validation. In each fold, every edge is correlated with the RT across the training subjects (Spearman correlation). Negative edges with p < .05 are selected.
- **Prediction:** the summed connectivity of the selected edges goes into a linear fit. Performance is the Spearman correlation between predicted and observed RTs.
- **Permutation test:** 1000 iterations. Iteration *i* shuffles the RTs with `rng(i + 123)`; iteration 1 is the observed model. p is the fraction of iterations with r ≥ the observed r.
- **Confidence intervals:** bootstrap BCa intervals (R `boot`, 5000 resamples, seed 123).
- **Head motion vs RT:** Spearman correlation between the mean framewise displacement and the median RT, over all subjects with a score for the task.

## Layout

```text
run_all.m            runs everything
config.m             paths and options
code/analysis/       a01-a06: statistics
code/figures/        f01-f05: brain maps and circular graphs (MATLAB)
code/R/              Figures 5, 6, S4, S5, bootstrap CIs, formatted tables
code/lib/stats/      Wilcoxon/FDR tests, combining hemispheres, networks
code/lib/cpm/        connectome-based predictive modelling
code/lib/parcels/    parcel labels and the 33 target regions
code/lib/io/         reading data, writing results, running the steps
code/viz/            surface rendering, circular graphs, colour maps
code/external/       fdr_bh (third party)
data/                derived data (see data/README.md)
preprocessing/       how the matrices behind data/ were made from the HCP data
  fmri/              steps 0-2: download, normalise and concatenate, parcellate, FSLNets
  meg/               pointer to the MEG pipeline (separate repository)
  make_data.m        builds data/ from the matrices
results/             output (made by run_all; not tracked by git)
  figures/           the figures (figure1.png ... figureS5.png)
  figures/panels/    every panel of the MATLAB figures as its own PNG
  tables/, cpm/, analysis/, RUN_LOG.md
```

## Data

The data are derived from the Human Connectome Project (WU-Minn HCP 1200 Subjects Release).
They are shared under the HCP Open Access Data Use Terms; see [`data/README.md`](data/README.md).

## How the data were made

[`preprocessing/`](preprocessing/README.md) contains the code that computed the connectivity
matrices behind `data/` from the HCP data. `run_all` does not use it.
- **fMRI** (`preprocessing/fmri/`): the four resting-state runs are normalised and concatenated
  (Connectome Workbench) and averaged within the HCP-MMP1 parcels. The connectivity matrices are
  then computed with FSLNets.
- **MEG**: computed with the pipeline of our earlier study, Soyuhos & Baldauf (2023),
  *European Journal of Neuroscience*, https://doi.org/10.1111/ejn.15936.
  - Code: https://github.com/orhansoyuhos/Functional-connectivity-fingerprints-of-the-FEF-and-IFJ
  - The settings used here are in [`preprocessing/meg/README.md`](preprocessing/meg/README.md).
- `preprocessing/make_data.m` builds the files in `data/` from these matrices.

## License

Copyright (C) 2026 Orhan Soyuhos

The code is free software under the GNU General Public License v3.0 (`LICENSE`): you can
redistribute and modify it under those terms. It comes without any warranty.

Third-party code and data keep their own terms:
- `code/external/fdr_bh.m`: the BSD license of the MATLAB File Exchange (see
  `code/external/README.md`);
- the data in `data/` and the atlas in `preprocessing/fmri/parcellation/`: the HCP Open Access
  Data Use Terms.
