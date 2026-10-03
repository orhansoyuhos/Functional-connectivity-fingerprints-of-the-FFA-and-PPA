%% F03  Figure 3: MEG connectivity of the FFA and PPA with the 33 target regions
%
% A  the 33 regions of Table 1 on the left hemisphere, coloured by group
% B  amplitude coupling (oPEC), FFA vs PPA, beta and gamma, both hemispheres
%    combined: red = FFA, blue = PPA
% C  directed coupling (PDC), beta and gamma, for the FFA (top) and the PPA
%    (bottom): magenta = seed -> region, green = region -> seed
% Line width = |z| (combined across hemispheres, combine_hemispheres).
%
% Input   results/analysis/meg_roi.mat (a04_meg_roi)
% Output  results/figures/figure3.png (all panels)
%         results/figures/panels/figure3A_*.png, figure3B_*.png, figure3C_*.png
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

cfg = config();
S = load_surface(cfg);
G = roi_groups(cfg);
Q = load(fullfile(cfg.results_dir, 'analysis', 'meg_roi.mat'));
pan = cfg.panels_dir;
if ~exist(pan, 'dir'), mkdir(pan); end
bandTitle = struct('delta', '\delta (1-4 Hz)', 'theta', '\theta (4-8 Hz)', 'alpha', '\alpha (8-13 Hz)', ...
                   'beta', '\beta (13-30 Hz)', 'gamma', '\gamma (30-100 Hz)');

roi_location_figure(S, G, {hcp_label(cfg.seed_ffa, 'L'), hcp_label(cfg.seed_ppa, 'L')}, ...
    fullfile(pan, 'figure3A_roi_locations.png'));
legend_image(fullfile(pan, 'figure3A_legend.png'), 'groups_colored', G);
legend_image(fullfile(pan, 'figure3A_seeds.png'), 'seeds');
legend_image(fullfile(pan, 'figure3B_legend.png'), 'contrast');
legend_image(fullfile(pan, 'figure3C_legend.png'), 'directed');

for b = {'beta', 'gamma'}
    fig = circle_graph(G, Q.roi.oPEC.(b{1}).combined.value, 'contrast', ...
        struct('ring_colors', true, 'title', bandTitle.(b{1})));
    exportgraphics(fig, fullfile(pan, sprintf('figure3B_oPEC_%s.png', b{1})), 'Resolution', 200);
    close(fig);
    for s = {'FFC', 'PHA3'}
        lab = 'FFA'; if strcmp(s{1}, 'PHA3'), lab = 'PPA'; end
        fig = circle_graph(G, Q.roi.(['PDC_' s{1}]).(b{1}).combined.value, 'directed', ...
            struct('seed_labels', {{lab}}, 'title', bandTitle.(b{1})));
        exportgraphics(fig, fullfile(pan, sprintf('figure3C_PDC_%s_%s.png', lab, b{1})), 'Resolution', 200);
        close(fig);
    end
end

f = @(n) fullfile(pan, n);
p = struct('file', {}, 'pos', {}, 'letter', {});
p(end+1) = struct('file', f('figure3A_roi_locations.png'), 'pos', [0.00 0.36 0.30 0.62], 'letter', 'A');
p(end+1) = struct('file', f('figure3A_seeds.png'),         'pos', [0.01 0.28 0.26 0.06], 'letter', '');
p(end+1) = struct('file', f('figure3A_legend.png'),        'pos', [0.03 0.02 0.24 0.25], 'letter', '');
p(end+1) = struct('file', f('figure3B_oPEC_beta.png'),     'pos', [0.31 0.66 0.33 0.33], 'letter', 'B');
p(end+1) = struct('file', f('figure3B_oPEC_gamma.png'),    'pos', [0.66 0.66 0.33 0.33], 'letter', '');
p(end+1) = struct('file', f('figure3B_legend.png'),        'pos', [0.58 0.95 0.10 0.03], 'letter', '');
p(end+1) = struct('file', f('figure3C_PDC_FFA_beta.png'),  'pos', [0.31 0.33 0.33 0.32], 'letter', 'C');
p(end+1) = struct('file', f('figure3C_PDC_FFA_gamma.png'), 'pos', [0.66 0.33 0.33 0.32], 'letter', '');
p(end+1) = struct('file', f('figure3C_PDC_PPA_beta.png'),  'pos', [0.31 0.00 0.33 0.32], 'letter', '');
p(end+1) = struct('file', f('figure3C_PDC_PPA_gamma.png'), 'pos', [0.66 0.00 0.33 0.32], 'letter', '');
p(end+1) = struct('file', f('figure3C_legend.png'),        'pos', [0.58 0.31 0.10 0.04], 'letter', '');
panel_figure(fullfile(cfg.figures_dir, 'figure3.png'), p, 1800, 1900);
fprintf('Figure 3 written to %s\n', cfg.figures_dir);
