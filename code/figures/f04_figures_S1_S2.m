%% F04  Figures S1 and S2: whole-brain MEG maps of the FFA and PPA
%
% S1  amplitude coupling (oPEC), all five bands
% S2  phase coupling (iCOH), delta, theta and alpha
% Rows: A = FFA seed map, B = PPA seed map, C = FFA vs PPA contrast.
%
% Input   results/analysis/meg_wholebrain.mat (a03_meg_wholebrain)
% Output  results/figures/figureS1.png, figureS2.png (all panels)
%         results/figures/panels/figureS1_*.png, figureS2_*.png (one panel per map)
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

cfg = config();
S = load_surface(cfg);
W = load(fullfile(cfg.results_dir, 'analysis', 'meg_wholebrain.mat'));
pan = cfg.panels_dir;
if ~exist(pan, 'dir'), mkdir(pan); end
bandTitle = struct('delta', '\delta (1-4 Hz)', 'theta', '\theta (4-8 Hz)', 'alpha', '\alpha (8-13 Hz)', ...
                   'beta', '\beta (13-30 Hz)', 'gamma', '\gamma (30-100 Hz)');
figs = {'S1', 'opec', {'delta', 'theta', 'alpha', 'beta', 'gamma'}, 'Power correlation'; ...
        'S2', 'icoh', {'delta', 'theta', 'alpha'},                   'Phase relation'};
rows = {'FFC', 'seedmap', 'FFA'; 'PHA3', 'seedmap', 'PPA'; 'contrast', 'contrast', ''};
dots = struct('FFC', parcel_index(S.labels, {hcp_label(cfg.seed_ffa, 'L'), hcp_label(cfg.seed_ffa, 'R')}), ...
              'PHA3', parcel_index(S.labels, {hcp_label(cfg.seed_ppa, 'L'), hcp_label(cfg.seed_ppa, 'R')}), ...
              'contrast', []);

for f = 1:size(figs, 1)
    [name, metric, bands, label] = figs{f, :};
    nb = numel(bands);
    p = struct('file', {}, 'pos', {}, 'letter', {});
    for r = 1:3
        for b = 1:nb
            R = W.wb.(metric).(bands{b});
            v = [R.L.(rows{r, 1}).stat; R.R.(rows{r, 1}).stat];
            file = fullfile(pan, sprintf('figure%s_%s_%s.png', name, lower(rows{r, 1}), bands{b}));
            brain_figure(S, v, rows{r, 2}, 6, dots.(rows{r, 1}), file, ...
                struct('layout', 'stacked', 'colorbar', false, 'title', bandTitle.(bands{b})));
            letter = ''; if b == 1, letter = char('A' + r - 1); end
            p(end+1) = struct('file', file, 'pos', [0.01 + (b - 1) * 0.9 / nb, 1 - r / 3 + 0.005, 0.9 / nb - 0.005, 1 / 3 - 0.01], ...
                'letter', letter); %#ok<SAGROW>
        end
        if r < 3, lab = sprintf('%s (%s)', label, rows{r, 3}); else, lab = '\Delta (FFA - PPA)'; end
        cb = fullfile(pan, sprintf('figure%s_colorbar_%s.png', name, lower(rows{r, 1})));
        draw_colorbar([], rows{r, 2}, 6, lab, cb);
        p(end+1) = struct('file', cb, 'pos', [0.92, 1 - r / 3 + 0.03, 0.07, 1 / 3 - 0.06], 'letter', ''); %#ok<SAGROW>
    end
    panel_figure(fullfile(cfg.figures_dir, sprintf('figure%s.png', name)), p, 380 * nb + 200, 1500);
    fprintf('Figure %s written to %s\n', name, cfg.figures_dir);
end
