# Results

Everything in this folder is written by `run_all`:

| folder / file | content |
|---|---|
| `figures/` | the figures: `figure1.png` (panels C and D), `figure2.png`, `figure3.png`, `figure5.png`, `figure6.png`, `figureS1.png` to `figureS5.png` |
| `figures/panels/` | each panel of the MATLAB figures (1–3, S1–S3) as its own PNG |
| `tables/` | CSV tables of all analyses; `table1.html`, `table_S2.html`, `table_S3.html` as formatted tables (also as PNG when `webshot2` and Chrome are available) |
| `cpm/` | one MAT file per CPM model, with its predictions and edge-selection consistency as CSV, and its permutation null distribution (CSV) when the permutation tests are run |
| `analysis/` | MAT files with the per-parcel statistics, used by the figure scripts |
| `RUN_LOG.md` | run time of each step |
