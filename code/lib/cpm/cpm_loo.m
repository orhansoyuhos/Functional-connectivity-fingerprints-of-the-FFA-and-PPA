function M = cpm_loo(conn, behav, thresh)
% CPM_LOO  Connectome-based predictive modelling with leave-one-out CV.
%
%   M = cpm_loo(conn, behav, thresh)
%
% conn    nNodes x nNodes x nSubjects connectivity (diagonal set to 0)
% behav   nSubjects x 1 behavioural scores
% thresh  edge-selection threshold (0.05 in the paper)
%
% For each left-out subject (Shen et al., 2017):
%   1. every entry of the connectivity matrix is correlated with behaviour
%      across the training subjects (Spearman); entries with r < 0 and
%      p < thresh form the mask of negative edges;
%   2. each training subject's summary score is the sum of its selected
%      entries over the full matrix, halved (each edge appears twice);
%   3. behaviour = m * score + b is fitted on the training subjects
%      (regress) and applied to the left-out subject.
% The model's performance is the Spearman correlation between predicted and
% observed scores.
%
% The Spearman correlations come from spearman_ties, with ranks that are
% updated for each left-out subject instead of re-ranking. This gives the
% same values as corr and is much faster for the permutation test.
%
% Output M:
%   r_neg                    prediction correlation
%   pred_neg                 predicted scores (leave-one-out)
%   neg_consistency          fraction of folds in which each edge was
%                            selected (Figures 5C, 6B, 6D, S5)
%   folds_without_neg_edges  folds in which no edge passed
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

n = size(conn, 3);
nn = size(conn, 1);
p = nn * nn;
behav = behav(:);

pred_neg  = zeros(n, 1);
neg_count = zeros(nn, nn);
no_neg = 0;

X = reshape(conn, p, n)';                       % subjects x matrix entries
[R, adj] = tiedrank(X, 0);
tied = adj > 0;                                 % columns with tied values
const = tied & all(X == X(1, :), 1);            % constant columns (the diagonal)
other = tied & ~const;
[rc, ac] = tiedrank(X(1:n-1, const), 0);        % same in every fold
n1 = n - 1;
sxx = repmat(n1 * (n1 + 1) * (2 * n1 + 1) / 6, 1, p);   % ranks 1..n-1 without ties
sxx(const) = sum(rc.^2, 1);
w = warning('off', 'stats:regress:RankDefDesignMat');

for i = 1:n
    train = [1:i-1, i+1:n];
    train_behav = behav(train);
    n_train = n - 1;

    % 1. edge selection
    xr = R(train, :);
    xr = xr - (xr > R(i, :));                   % ranks without subject i (columns without ties)
    xadj = zeros(1, p);
    xr(:, const) = rc;
    xadj(const) = ac;
    s = sxx;
    if any(other)
        [xr(:, other), xadj(other)] = tiedrank(X(train, other), 0);
        s(other) = sum(xr(:, other).^2, 1);
    end
    [yr, yadj] = tiedrank(train_behav, 0);
    if ~any(xadj > 0) && yadj == 0
        [r_vec, p_vec] = corr(X(train, :), train_behav, 'Type', 'Spearman');   % no ties at all
    else
        [r_vec, p_vec] = spearman_ties(xr, xadj, yr, yadj, s);
    end
    r_mat = reshape(r_vec, nn, nn);
    p_mat = reshape(p_vec, nn, nn);
    neg_mask = double(r_mat < 0 & p_mat < thresh);
    neg_count = neg_count + neg_mask;
    no_neg = no_neg + ~any(neg_mask(:));

    % 2. summary scores (full matrix, halved)
    train_mats = conn(:, :, train);
    train_sumneg = reshape(sum(sum(train_mats .* neg_mask, 1), 2), n_train, 1) / 2;

    % 3. linear model, applied to the left-out subject
    fit_neg = regress(train_behav, [train_sumneg, ones(n_train, 1)]);
    test_mat = conn(:, :, i);
    test_sumneg = sum(sum(test_mat .* neg_mask)) / 2;
    pred_neg(i) = fit_neg(1) * test_sumneg + fit_neg(2);
end
warning(w);

M.r_neg = corr(pred_neg, behav, 'Type', 'Spearman');
M.pred_neg = pred_neg;
M.neg_consistency = neg_count / n;
M.folds_without_neg_edges = no_neg;
end
