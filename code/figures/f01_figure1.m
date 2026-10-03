%% F01  Figure 1C/D: whole-brain fMRI connectivity maps of the FFA and PPA seeds
%
% Input   results/analysis/fmri_seed_maps.mat (a01_fmri_seed_maps)
% Output  results/figures/figure1.png (panels C and D)
%         results/figures/panels/figure1C_FFA_seed_map.png, figure1D_PPA_seed_map.png
%
% Figure 1A/B (Neurosynth maps and seed parcels) are not made by this code.
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

cfg = config();
S = load_surface(cfg);
A = load(fullfile(cfg.results_dir, 'analysis', 'fmri_seed_maps.mat'));
pan = cfg.panels_dir;
if ~exist(pan, 'dir'), mkdir(pan); end

seeds = {cfg.seed_ffa, 'figure1C_FFA_seed_map', 'Partial correlation (FFA)', 'C'; ...
         cfg.seed_ppa, 'figure1D_PPA_seed_map', 'Partial correlation (PPA)', 'D'};
p = struct('file', {}, 'pos', {}, 'letter', {});
for s = 1:size(seeds, 1)
    v = [A.maps.(seeds{s, 1}).L.stat; A.maps.(seeds{s, 1}).R.stat];
    dots = parcel_index(S.labels, {hcp_label(seeds{s, 1}, 'L'), hcp_label(seeds{s, 1}, 'R')});
    file = fullfile(pan, [seeds{s, 2} '.png']);
    brain_figure(S, v, 'seedmap', 8, dots, file, struct('label', seeds{s, 3}));
    p(end+1) = struct('file', file, 'pos', [0.02, 1 - s * 0.5 + 0.01, 0.97, 0.48], 'letter', seeds{s, 4}); %#ok<SAGROW>
end
panel_figure(fullfile(cfg.figures_dir, 'figure1.png'), p, 2000, 900);
fprintf('Figure 1C/D written to %s\n', cfg.figures_dir);
