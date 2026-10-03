%% F02  Figure 2: FFA vs PPA fMRI connectivity (A: brain maps, B: circular graphs)
%
% Input   results/analysis/fmri_contrast.mat (a02_fmri_contrast)
% Output  results/figures/figure2.png (both panels)
%         results/figures/panels/figure2A_contrast_map.png,
%         figure2B_circle_LH.png, figure2B_circle_RH.png, figure2B_legend.png
%
% The circles show the 33 Table 1 regions of each hemisphere with the
% z-scores of the 180-parcel test of that hemisphere: red = stronger
% connectivity with the FFA, blue = with the PPA; width = |z|.
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

cfg = config();
S = load_surface(cfg);
G = roi_groups(cfg);
A = load(fullfile(cfg.results_dir, 'analysis', 'fmri_contrast.mat'));
R = A.res.(cfg.seed_ppa);
pan = cfg.panels_dir;
if ~exist(pan, 'dir'), mkdir(pan); end

v = [R.L.stat; R.R.stat];
brain_figure(S, v, 'contrast', 8, [], fullfile(pan, 'figure2A_contrast_map.png'), ...
    struct('label', '\Delta (FFA - PPA)'));

hemis = {'L', 'R'};
for h = 1:2
    Rh = R.(hemis{h});
    k = parcel_index(Rh.labels, hcp_label(G.names, hemis{h}));
    fig = circle_graph(G, Rh.stat(k), 'contrast', struct('title', [hemis{h} 'H']));
    exportgraphics(fig, fullfile(pan, sprintf('figure2B_circle_%sH.png', hemis{h})), 'Resolution', 200);
    close(fig);
end
legend_image(fullfile(pan, 'figure2B_legend.png'), 'groups', G);

p = struct('file', {}, 'pos', {}, 'letter', {});
p(1) = struct('file', fullfile(pan, 'figure2A_contrast_map.png'), 'pos', [0.01 0.56 0.98 0.43], 'letter', 'A');
p(2) = struct('file', fullfile(pan, 'figure2B_circle_LH.png'), 'pos', [0.01 0.01 0.40 0.53], 'letter', 'B');
p(3) = struct('file', fullfile(pan, 'figure2B_legend.png'), 'pos', [0.42 0.25 0.16 0.25], 'letter', '');
p(4) = struct('file', fullfile(pan, 'figure2B_circle_RH.png'), 'pos', [0.59 0.01 0.40 0.53], 'letter', '');
panel_figure(fullfile(cfg.figures_dir, 'figure2.png'), p, 2000, 1500);
fprintf('Figure 2 written to %s\n', cfg.figures_dir);
