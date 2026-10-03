%% F05  Figure S3: directed MEG connectivity (PDC) in delta, theta and alpha
%
% As Figure 3C for the lower bands: A = FFA, B = PPA; magenta = seed ->
% region, green = region -> seed; both hemispheres combined.
%
% Input   results/analysis/meg_roi.mat (a04_meg_roi)
% Output  results/figures/figureS3.png (all panels)
%         results/figures/panels/figureS3_PDC_*.png, figureS3_legend.png
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

cfg = config();
G = roi_groups(cfg);
Q = load(fullfile(cfg.results_dir, 'analysis', 'meg_roi.mat'));
pan = cfg.panels_dir;
if ~exist(pan, 'dir'), mkdir(pan); end
bands = {'delta', 'theta', 'alpha'};
bandTitle = struct('delta', '\delta (1-4 Hz)', 'theta', '\theta (4-8 Hz)', 'alpha', '\alpha (8-13 Hz)');
seeds = {'FFC', 'FFA'; 'PHA3', 'PPA'};

p = struct('file', {}, 'pos', {}, 'letter', {});
for s = 1:2
    for b = 1:3
        fig = circle_graph(G, Q.roi.(['PDC_' seeds{s, 1}]).(bands{b}).combined.value, 'directed', ...
            struct('seed_labels', {seeds(s, 2)}, 'title', bandTitle.(bands{b})));
        file = fullfile(pan, sprintf('figureS3_PDC_%s_%s.png', seeds{s, 2}, bands{b}));
        exportgraphics(fig, file, 'Resolution', 200);
        close(fig);
        letter = ''; if b == 1, letter = char('A' + s - 1); end
        y = 0.535 * (s == 1);
        p(end+1) = struct('file', file, 'pos', [(b - 1) / 3, y, 1 / 3, 0.465], 'letter', letter); %#ok<SAGROW>
    end
end
legend_image(fullfile(pan, 'figureS3_legend.png'), 'directed');
p(end+1) = struct('file', fullfile(pan, 'figureS3_legend.png'), 'pos', [0.42 0.47 0.16 0.06], 'letter', '');
panel_figure(fullfile(cfg.figures_dir, 'figureS3.png'), p, 1800, 1250);
fprintf('Figure S3 written to %s\n', cfg.figures_dir);
