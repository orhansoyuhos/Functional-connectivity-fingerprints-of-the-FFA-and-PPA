function cfg = config()
% CONFIG  Paths and options shared by all scripts.
%
%   cfg = config();
%
% Every analysis and figure script calls config() first. It also puts the
% repository's code on the MATLAB path. Edit the OPTIONS block to change how
% run_all behaves (for example, to skip the CPM permutation tests).
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

root = fileparts(mfilename('fullpath'));

% ---- Paths --------------------------------------------------------------
cfg.root        = root;
cfg.data_dir    = fullfile(root, 'data');
cfg.results_dir = fullfile(root, 'results');
cfg.tables_dir  = fullfile(cfg.results_dir, 'tables');
cfg.figures_dir = fullfile(cfg.results_dir, 'figures');        % the figures
cfg.panels_dir  = fullfile(cfg.figures_dir, 'panels');         % each panel on its own
cfg.cpm_dir     = fullfile(cfg.results_dir, 'cpm');

% ---- Statistics ---------------------------------------------------------
cfg.alpha = 0.05;   % nominal alpha of each Wilcoxon signed-rank test
cfg.q_fdr = 0.05;   % false discovery rate (Benjamini-Hochberg)

% ---- Seeds and frequency bands ------------------------------------------
cfg.seed_ffa  = 'FFC';    % FFA seed parcel (HCP-MMP1)
cfg.seed_ppa  = 'PHA3';   % PPA seed parcel
cfg.seed_appa = 'PHA2';   % anterior-PPA control seed (Section 2.5)
cfg.bands      = {'delta', 'theta', 'alpha', 'beta', 'gamma'};
cfg.band_edges = [1 4; 4 8; 8 13; 13 30; 30 100];   % Hz

% ---- OPTIONS -------------------------------------------------------------
% CPM permutation test: 1000 iterations as in the paper (iteration 1 is the
% observed model). Set to 0 to skip; the p-values are then not computed.
cfg.cpm.n_permutations = 1000;
% Run the permutations with parfor when the Parallel Computing Toolbox is
% installed (much faster; the results are identical).
cfg.cpm.parallel = true;
cfg.cpm.threshold  = 0.05;   % edge-selection threshold (p < .05)
cfg.cpm.motion_max = 0.15;   % exclude subjects with mean FD > 0.15 mm

% run_all.m calls the R scripts (Figures 5, 6, S4, S5, bootstrap CIs and
% table images) at the end when this is true and Rscript is found.
cfg.run_R   = true;
cfg.rscript = '';   % full path to Rscript; empty = search the PATH and the default install folders

% ---- Options given to run_all (they override the values above) -----------
ov = getappdata(0, 'face_scene_options');
if isstruct(ov)
    if isfield(ov, 'Permutations'), cfg.cpm.n_permutations = ov.Permutations; end
    if isfield(ov, 'Parallel'),     cfg.cpm.parallel = ov.Parallel; end
    if isfield(ov, 'RunR'),         cfg.run_R = ov.RunR; end
    if isfield(ov, 'Rscript'),      cfg.rscript = ov.Rscript; end
end

% ---- MATLAB path ---------------------------------------------------------
addpath(root);
addpath(genpath(fullfile(root, 'code')));
end
