%% A01  Whole-brain fMRI connectivity of the FFA and PPA seeds (Figure 1C/D, Tables S2/S3)
%
% For each seed (FFA = FFC, PPA = PHA3) and hemisphere, the seed's partial
% correlation with each of the 180 ipsilateral parcels is compared with the
% subject's mean connectivity over the whole 360 x 360 matrix (one-sided
% Wilcoxon signed-rank test, FDR over the 180 parcels, z from the adjusted
% p-values). The seed itself is one of the 180 tested parcels (its
% self-connection is set to 1).
%
% Output
%   results/analysis/fmri_seed_maps.mat          per-parcel results (figures)
%   results/tables/fmri_seed_maps_all_parcels.csv
%   results/tables/table_S2_FFA_seed_map.csv     significant regions, FFA
%   results/tables/table_S3_PPA_seed_map.csv     significant regions, PPA
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

cfg = config();
D = load_connectivity(cfg, 'fmri');
hemis = {'L', 'R'};
seeds = {cfg.seed_ffa, cfg.seed_ppa};
table_names = {'table_S2_FFA_seed_map', 'table_S3_PPA_seed_map'};

maps = struct();
long = table();
for s = 1:numel(seeds)
    for h = 1:2
        targets = D.labels((1:180) + 180 * (h - 1));
        R = seed_test(D, 'mean', hcp_label(seeds{s}, hemis{h}), targets, 1, cfg);
        maps.(seeds{s}).(hemis{h}) = R;
        long = [long; results_long(R, struct('seed', seeds{s}))]; %#ok<AGROW>
    end
    T = hemisphere_table(maps.(seeds{s}).L, maps.(seeds{s}).R, seeds(s));
    T.sign = [];
    write_csv_exact(T, fullfile(cfg.tables_dir, [table_names{s} '.csv']));
    fprintf('%s seed map: %d regions (left %d, right %d)\n', seeds{s}, height(T), ...
        sum(~isnan(T.L_z)), sum(~isnan(T.R_z)));
end

if ~exist(fullfile(cfg.results_dir, 'analysis'), 'dir'), mkdir(fullfile(cfg.results_dir, 'analysis')); end
save(fullfile(cfg.results_dir, 'analysis', 'fmri_seed_maps.mat'), 'maps');
write_csv_exact(long, fullfile(cfg.tables_dir, 'fmri_seed_maps_all_parcels.csv'));
