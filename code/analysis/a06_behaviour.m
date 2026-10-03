%% A06  Behaviour in the CPM samples (Section 2.4, Figure S4) and head motion (Section 4.6)
%
% For each task, the subjects of the CPM sample (mean FD <= 0.15 mm, score
% available): N, mean and SD of the median RT and of the accuracy.
% Head motion: Spearman correlation between the mean framewise displacement
% and the median RT, over all subjects with a score for the task.
% The RT-accuracy correlations and Figure S4 are made in R
% (code/R/figure_S4.R).
%
% Output
%   results/tables/behaviour_summary.csv
%   results/tables/behaviour_final_samples.csv   (input of figure_S4.R)
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

cfg = config();
[~, B] = load_cpm_data(cfg);
tasks = {'face-matching', 'Emotion_Task_Face_Median_RT', 'Emotion_Task_Face_Acc'; ...
         '0-back scene',  'WM_Task_0bk_Place_Median_RT', 'WM_Task_0bk_Place_Acc'; ...
         '2-back scene',  'WM_Task_2bk_Place_Median_RT', 'WM_Task_2bk_Place_Acc'};

summary = table();
samples = table();
for k = 1:size(tasks, 1)
    rt = B.(tasks{k, 2});
    acc = B.(tasks{k, 3});
    keep = ~isnan(rt) & ~(B.mean_FD > cfg.cpm.motion_max) & ~isnan(acc);
    [mot_r, mot_p] = corr(rt, B.mean_FD, 'Rows', 'complete', 'Type', 'Spearman');
    summary = [summary; table(string(tasks{k, 1}), string(tasks{k, 2}), string(tasks{k, 3}), sum(keep), ...
        mean(rt(keep)), std(rt(keep)), mean(acc(keep)), std(acc(keep)), mot_r, mot_p, ...
        'VariableNames', {'task', 'score_rt', 'score_acc', 'N', 'rt_mean', 'rt_sd', 'acc_mean', 'acc_sd', ...
        'motion_r', 'motion_p'})]; %#ok<AGROW>
    n = sum(keep);
    samples = [samples; table(repmat(string(tasks{k, 1}), n, 1), repmat(string(tasks{k, 2}), n, 1), ...
        B.row(keep), rt(keep), acc(keep), ...
        'VariableNames', {'task', 'score_rt', 'row', 'rt', 'accuracy'})]; %#ok<AGROW>
    fprintf('%-13s N = %d, RT %.2f (%.2f) ms, accuracy %.2f (%.2f) %%, head motion vs RT: r = %.2f (p = %.2f)\n', ...
        tasks{k, 1}, n, mean(rt(keep)), std(rt(keep)), mean(acc(keep)), std(acc(keep)), mot_r, mot_p);
end
write_csv_exact(summary, fullfile(cfg.tables_dir, 'behaviour_summary.csv'));
write_csv_exact(samples, fullfile(cfg.tables_dir, 'behaviour_final_samples.csv'));
