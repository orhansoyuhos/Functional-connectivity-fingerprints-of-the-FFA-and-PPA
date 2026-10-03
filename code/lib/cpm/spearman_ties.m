function [coef, pval] = spearman_ties(xrank, xadj, yrank, yadj, sxx)
% SPEARMAN_TIES  Spearman correlation of many columns with one vector, from ranks.
%
%   [coef, pval] = spearman_ties(xrank, xadj, yrank, yadj)
%   [coef, pval] = spearman_ties(xrank, xadj, yrank, yadj, sxx)
%
% xrank  n x p ranks of the columns of X, [xrank, xadj] = tiedrank(X, 0)
% yrank  n x 1 ranks of y,                [yrank, yadj] = tiedrank(y, 0)
% sxx    optional 1 x p sums of squared ranks, sum(xrank.^2) (saves time)
%
% Returns the same values as corr(X, y, 'Type', 'Spearman') (two-sided)
% when the data contain ties, which is always the case in the CPM (the
% diagonal of the connectivity matrices is constant): Spearman's D
% statistic with the tie correction (Gibbons, 1985) and p-values from the
% t approximation. It is written out here, vectorised over the columns,
% because with ties corr works one column at a time, which is much slower
% for the CPM permutations.
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

n = size(xrank, 1);
n3const = (n + 1) * n * (n - 1) ./ 3;

% D = sum((xrank - yrank).^2). Ranks are integers or half-integers, so every
% term and every partial sum is exact and the expansion below gives the
% same value to the last bit, with one matrix-vector product.
if nargin < 5, sxx = sum(xrank.^2, 1); end
D = sxx - 2 * (yrank' * xrank) + sum(yrank.^2);
meanD = (n3const - (xadj + yadj) ./ 3) ./ 2;
stdD = sqrt((n3const ./ 2 - xadj ./ 3) .* (n3const ./ 2 - yadj ./ 3) ./ (n - 1));
n3const2 = (n + 1) * n * (n - 1) / 2;
stdD((xadj == n3const2) | (yadj == n3const2)) = 0;   % a constant column

coef = (meanD - D) ./ (sqrt(n - 1) * stdD);

% p-value: t approximation, two-sided
Dp = D;
Dp(stdD == 0) = NaN;
r = (meanD - Dp) ./ (sqrt(n - 1) * stdD);
t = Inf * sign(r);
ok = abs(r) < 1;
t(ok) = r(ok) .* sqrt((n - 2) ./ (1 - r(ok).^2));
pval = 2 * tcdf(-abs(t), n - 2);

% limit to [-1, 1] (keeps NaN)
k = abs(coef) > 1;
coef(k) = coef(k) ./ abs(coef(k));

coef = coef(:);
pval = pval(:);
end
