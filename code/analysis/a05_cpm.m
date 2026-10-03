%% A05  Connectome-based predictive modelling (Figures 5, 6 and S5; Section 2.5)
%
% Twelve CPM analyses (cpm_model_list): median RTs of the face-matching,
% 0-back and 2-back scene tasks predicted from the fMRI partial correlations
% within the FFA and PPA networks (A02), the seed-excluded networks and the
% PHA2 control networks. 371 subjects from different families; subjects
% with mean FD > 0.15 mm or a missing score are excluded (N = 350 / 352).
% Leave-one-out CV, Spearman edge selection at p < .05, negative edges.
% Permutation test with cfg.cpm.n_permutations iterations (1000 in the paper;
% config.m).
%
% Output (results/cpm/, results/tables/)
%   <model>.mat                     full results
%   <model>_predictions.csv         observed and predicted RTs
%   <model>_neg_consistency.csv     edge-selection consistency (Figures 5C, 6B, 6D, S5)
%   <model>_null.csv                permutation null distribution (iteration 1 = observed;
%                                   only when the permutation test is run)
%   tables/cpm_summary.csv          r, N and permutation p of every model
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

cfg = config();
[C, B] = load_cpm_data(cfg);
S = load(fullfile(cfg.results_dir, 'analysis', 'fmri_contrast.mat'), 'networks');
list = cpm_model_list();
if ~exist(cfg.cpm_dir, 'dir'), mkdir(cfg.cpm_dir); end

summary = table();
for k = 1:size(list, 1)
    [id, score, netname, where, desc] = list{k, :};
    net = S.networks.(netname);
    t0 = tic;
    M = cpm_model(cfg, C, B, score, net, cfg.cpm.n_permutations);
    M.id = id;
    M.network_name = netname;
    M.where = where;
    M.description = desc;
    save(fullfile(cfg.cpm_dir, [id '.mat']), 'M');

    write_csv_exact(table(M.rows, M.actual, M.fit.pred_neg, ...
        'VariableNames', {'row', 'actual', 'predicted_neg'}), ...
        fullfile(cfg.cpm_dir, [id '_predictions.csv']));
    short = cpm_short_labels(net);
    T = array2table(M.fit.neg_consistency, 'VariableNames', short);
    write_csv_exact([table(string(short(:)), 'VariableNames', {'label'}), T], ...
        fullfile(cfg.cpm_dir, [id '_neg_consistency.csv']));
    null_file = fullfile(cfg.cpm_dir, [id '_null.csv']);
    if ~isempty(M.null)
        write_csv_exact(table((1:numel(M.null))', M.null, ...
            'VariableNames', {'iteration', 'r_neg'}), null_file);
    elseif isfile(null_file)
        delete(null_file);   % from an earlier run with permutations
    end

    row = table(string(id), string(where), string(desc), string(score), string(netname), numel(net), ...
        M.n, M.n - 2, M.fit.r_neg, M.p_neg, numel(M.null), ...
        M.fit.folds_without_neg_edges, M.n_excluded_motion, M.n_excluded_missing, toc(t0), ...
        'VariableNames', {'model', 'figure', 'description', 'score', 'network', 'n_regions', ...
        'N', 'df', 'r_neg', 'p_perm', 'n_perm', ...
        'folds_without_neg_edges', 'excluded_motion', 'excluded_missing', 'seconds'});
    summary = [summary; row]; %#ok<AGROW>
    fprintf('%-11s N = %d, %d regions: r = %.3f, permutation p = %.3f (%d iterations), %.0f s\n', ...
        id, M.n, numel(net), M.fit.r_neg, M.p_neg, numel(M.null), toc(t0));
end
write_csv_exact(summary, fullfile(cfg.tables_dir, 'cpm_summary.csv'));

function short = cpm_short_labels(labels)
% 'R_FFC_ROI R' -> 'R-FFC' (the label style of the R figures)
[name, hemi] = bare_name(labels);
short = strcat(hemi, '-', name);
end
