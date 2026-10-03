%% A02  FFA vs PPA fMRI connectivity contrast (Figure 2, Table 1) and the CPM networks
%
% For each hemisphere, each of the 180 ipsilateral parcels is tested for
% stronger partial correlation with the FFA seed (FFC) or the PPA seed
% (PHA3): paired two-sided Wilcoxon signed-rank test, FDR over the 180
% parcels, z from the adjusted p-values (positive = FFA). Both seeds are
% among the 180 tested parcels, with their self-connection set to 1.
%
% The significant regions are Table 1 and the target ROIs of all later
% analyses. The CPM networks (Section 4.6) are the seeds plus their
% preferentially connected parcel instances: FFA network 37 regions, PPA
% network 23 regions. The same contrast with the anterior PPA seed (PHA2)
% gives the control networks of Section 2.5 (44 and 18 regions).
%
% Output
%   results/analysis/fmri_contrast.mat        per-parcel results and networks
%   results/tables/fmri_contrast_all_parcels.csv
%   results/tables/table1_FFA_vs_PPA.csv
%   results/tables/table_FFA_vs_PHA2_control.csv
%   results/tables/cpm_networks.csv
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

cfg = config();
D = load_connectivity(cfg, 'fmri');
hemis = {'L', 'R'};
contrasts = {cfg.seed_ppa, cfg.seed_appa};   % FFC vs PHA3 (main), FFC vs PHA2 (control)

res = struct();
long = table();
for c = 1:numel(contrasts)
    s2 = contrasts{c};
    for h = 1:2
        targets = D.labels((1:180) + 180 * (h - 1));
        R = seed_test(D, 'contrast', {hcp_label(cfg.seed_ffa, hemis{h}), hcp_label(s2, hemis{h})}, ...
            targets, 1, cfg);
        res.(s2).(hemis{h}) = R;
        long = [long; results_long(R, struct('contrast', [cfg.seed_ffa ' vs ' s2]))]; %#ok<AGROW>
    end
    res.(s2).networks = define_networks(res.(s2).L, res.(s2).R, cfg.seed_ffa, s2);
end

% Table 1 (FFC vs PHA3) and the PHA2 control table
names = {'table1_FFA_vs_PPA', 'table_FFA_vs_PHA2_control'};
for c = 1:numel(contrasts)
    s2 = contrasts{c};
    T = hemisphere_table(res.(s2).L, res.(s2).R, {cfg.seed_ffa, s2});
    assert(~any(isnan(T.sign)), 'A region prefers different seeds in the two hemispheres.');
    network = repmat("FFA", height(T), 1);
    network(T.sign < 0) = string(s2);
    if strcmp(s2, cfg.seed_ppa), network(T.sign < 0) = "PPA"; end
    T = [table(network), T(:, {'parcel', 'L_p_fdr', 'L_z', 'R_p_fdr', 'R_z'})];
    T = ffa_rows_first(T);
    write_csv_exact(T, fullfile(cfg.tables_dir, [names{c} '.csv']));
    n1 = res.(s2).networks;
    fprintf('FFC vs %s: %d regions, %d instances; networks %d (FFA) and %d (%s)\n', s2, height(T), ...
        numel(n1.targets1) + numel(n1.targets2), numel(n1.net1), numel(n1.net2), s2);
end

% CPM networks
nets = {'FFA', res.(cfg.seed_ppa).networks.net1; ...
        'PPA', res.(cfg.seed_ppa).networks.net2; ...
        'FFA_without_seeds', setdiff_keep(res.(cfg.seed_ppa).networks.net1, both_hemis(cfg.seed_ffa)); ...
        'PPA_without_seeds', setdiff_keep(res.(cfg.seed_ppa).networks.net2, both_hemis(cfg.seed_ppa)); ...
        'FFA_PHA2_contrast', res.(cfg.seed_appa).networks.net1; ...
        'anterior_PPA',      res.(cfg.seed_appa).networks.net2};
NT = table();
for k = 1:size(nets, 1)
    lab = nets{k, 2};
    NT = [NT; table(repmat(string(nets{k, 1}), numel(lab), 1), (1:numel(lab))', string(lab), ...
        'VariableNames', {'network', 'position', 'label'})]; %#ok<AGROW>
end
write_csv_exact(NT, fullfile(cfg.tables_dir, 'cpm_networks.csv'));
networks = cell2struct(nets(:, 2), nets(:, 1), 1);

if ~exist(fullfile(cfg.results_dir, 'analysis'), 'dir'), mkdir(fullfile(cfg.results_dir, 'analysis')); end
save(fullfile(cfg.results_dir, 'analysis', 'fmri_contrast.mat'), 'res', 'networks');
write_csv_exact(long, fullfile(cfg.tables_dir, 'fmri_contrast_all_parcels.csv'));

function T = ffa_rows_first(T)
% FFA rows first, then the other network; within each, the character order
% of hemisphere_table.
first = T.network == "FFA";
T = [T(first, :); T(~first, :)];
end

function out = setdiff_keep(a, b)
% Remove b from a, keeping the order of a.
out = a(~ismember(a, b));
end

function c = both_hemis(name)
c = {hcp_label(name, 'L'); hcp_label(name, 'R')};
end
