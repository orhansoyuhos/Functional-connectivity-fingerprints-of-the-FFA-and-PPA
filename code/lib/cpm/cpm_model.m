function M = cpm_model(cfg, C, B, score, network, n_perm)
% CPM_MODEL  One CPM analysis: exclusions, LOO model and permutation test.
%
%   M = cpm_model(cfg, C, B, score, network, n_perm)
%
% C        371-subject connectivity (load_cpm_data): C.labels, C.data
% B        behaviour table (load_cpm_data): one row per subject
% score    behaviour column to predict, e.g. 'Emotion_Task_Face_Median_RT'
% network  parcel labels of the network (order as in network_order)
% n_perm   number of permutation iterations including the observed model
%          (1000 in the paper); 0 skips the test
%
% Exclusions (Section 4.6): mean framewise displacement > 0.15 mm, or a
% missing score.
%
% Permutation test (Section 4.7): in iteration it = 2..n_perm the scores
% are shuffled with rng(it + 123) and the whole LOO model is refitted.
% Iteration 1 is the observed model. p = fraction of iterations with
% r >= the observed r (one-sided).
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

idx  = parcel_index(C.labels, network);
conn = C.data(idx, idx, :);

y_all = B.(score);
fd    = B.mean_FD;
keep  = ~isnan(y_all) & ~(fd > cfg.cpm.motion_max);

y = y_all(keep);
conn = conn(:, :, keep);
for k = 1:size(conn, 3)
    slice = conn(:, :, k);
    slice(logical(eye(size(slice, 1)))) = 0;
    conn(:, :, k) = slice;
end

fit = cpm_loo(conn, y, cfg.cpm.threshold);

M.score = score;
M.network = network(:);
M.n = numel(y);
M.n_excluded_motion = sum(fd > cfg.cpm.motion_max);
M.n_excluded_missing = sum(isnan(y_all));
M.rows = find(keep);   % rows of data/behaviour_371subjs.csv in the final sample
M.actual = y;
M.fit = fit;

M.null = [];
M.p_neg = NaN;
if n_perm > 0
    null = zeros(n_perm, 1);
    null(1) = fit.r_neg;
    n = numel(y);
    thresh = cfg.cpm.threshold;
    nw = n_workers(cfg);
    parfor (it = 2:n_perm, nw)
        rng(it + 123, 'twister');
        y_perm = y(randperm(n)); %#ok<PFBNS> every iteration needs all scores
        f = cpm_loo(conn, y_perm, thresh);
        null(it) = f.r_neg;
    end
    M.null = null;
    M.p_neg = sum(null >= fit.r_neg) / n_perm;
end
end

function nw = n_workers(cfg)
% Number of parfor workers: 0 runs the loop in this MATLAB session.
nw = 0;
if cfg.cpm.parallel && license('test', 'Distrib_Computing_Toolbox') && ~isempty(ver('parallel'))
    pool = gcp('nocreate');
    if isempty(pool)
        pool = parpool;
    end
    nw = pool.NumWorkers;
end
end
