%% A04  MEG connectivity of the FFA and PPA with the 33 target regions (Figures 3B, 3C, S3)
%
% Targets: the 33 regions of Table 1, tested in each hemisphere (FDR over
% the 33 regions), then combined across hemispheres (combine_hemispheres):
%   oPEC, iCOH  FFA vs PPA contrast (Figure 3B: oPEC beta and gamma; the
%               iCOH result is reported in the text, Section 2.3)
%   PDC         for each seed, seed -> region vs region -> seed (Figure 3C:
%               beta and gamma; Figure S3: delta, theta, alpha)
%
% Output
%   results/analysis/meg_roi.mat
%   results/tables/meg_roi_lines.csv   one row per analysis, band and region:
%       zL, zR (signed per-hemisphere z, 0 = not significant) and value
%       (combined z drawn in the figures; 0 = no line). Positive = FFA
%       (contrast) or seed -> region (PDC).
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

cfg = config();
G = roi_groups(cfg);
hemis = {'L', 'R'};

analyses = {'oPEC',     'opec', 'contrast', cfg.seed_ffa, cfg.seed_ppa; ...
            'iCOH',     'icoh', 'contrast', cfg.seed_ffa, cfg.seed_ppa; ...
            'PDC_FFC',  'pdc',  'directed', cfg.seed_ffa, ''; ...
            'PDC_PHA3', 'pdc',  'directed', cfg.seed_ppa, ''};

roi = struct();
lines = table();
for a = 1:size(analyses, 1)
    [name, metric, mode, s1, s2] = analyses{a, :};
    D = load_connectivity(cfg, metric);
    for b = 1:numel(D.bands)
        R = struct();
        for h = 1:2
            targets = hcp_label(G.names, hemis{h});
            if strcmp(mode, 'contrast')
                seeds = {hcp_label(s1, hemis{h}), hcp_label(s2, hemis{h})};
            else
                seeds = {hcp_label(s1, hemis{h})};
            end
            R.(hemis{h}) = seed_test(D, mode, seeds, targets, b, cfg);
        end
        C = combine_hemispheres(R.L, R.R, strcmp(mode, 'contrast'), cfg);
        R.combined = C;
        roi.(name).(D.bands{b}) = R;
        n = numel(G.names);
        lines = [lines; table(repmat(string(name), n, 1), repmat(string(D.bands{b}), n, 1), ...
            string(G.names), C.zL, C.zR, C.value, ...
            'VariableNames', {'analysis', 'band', 'parcel', 'zL', 'zR', 'value'})]; %#ok<AGROW>
        fprintf('%-8s %-5s  lines: %2d positive, %2d negative\n', name, D.bands{b}, ...
            sum(C.value > 0), sum(C.value < 0));
    end
end

if ~exist(fullfile(cfg.results_dir, 'analysis'), 'dir'), mkdir(fullfile(cfg.results_dir, 'analysis')); end
save(fullfile(cfg.results_dir, 'analysis', 'meg_roi.mat'), 'roi');
write_csv_exact(lines, fullfile(cfg.tables_dir, 'meg_roi_lines.csv'));
