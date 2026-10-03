function T = wilcoxon_fdr(A, B, tail, cfg)
% WILCOXON_FDR  Per-parcel Wilcoxon signed-rank tests, FDR, z-scores.
%
%   T = wilcoxon_fdr(A, B, tail, cfg)
%
% This is the statistical procedure of the paper (Section 4.7):
%   1. for each target parcel i, a paired Wilcoxon signed-rank test of
%      A(i,:) against B(i,:) across subjects (signrank, alpha = cfg.alpha);
%   2. Benjamini-Hochberg FDR over all tested parcels (fdr_bh, 'pdep',
%      q = cfg.q_fdr);
%   3. the adjusted p-values are turned into z-scores:
%         two-sided test ('both'):  z = |norminv(p_adj / 2)|
%         one-sided test ('right'): z = |norminv(p_adj)|
%   4. the signed statistic is z * sign(effect), and 0 where the FDR test
%      is not significant. The effect is mean(A - B) for a paired contrast
%      and mean(A) for a test against a per-subject baseline.
%
% Inputs
%   A, B  nTargets x nSubjects. For a test against the whole-brain mean,
%         B holds that mean repeated for every target (seed_test, mode 'mean').
%   tail  'both' (contrast, directionality) or 'right' (seed vs mean)
%
% Output struct T (all nTargets x 1)
%   p      raw p-values
%   p_fdr  FDR-adjusted p-values
%   z      z-scores of the adjusted p-values (unsigned)
%   stat   signed z-score, 0 where not significant
%   sig    logical, FDR-significant
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

nT = size(A, 1);
assert(isequal(size(A), size(B)), 'A and B must have the same size.');

P = zeros(nT, 1);
for i = 1:nT
    P(i) = signrank(A(i, :)', B(i, :)', 'Alpha', cfg.alpha, 'Tail', tail);
end
assert(~any(isnan(P)), 'A test returned NaN.');

[h_adj, ~, ~, p_adj] = fdr_bh(P, cfg.q_fdr, 'pdep', 'no');
p_adj = p_adj(:);
h_adj = logical(h_adj(:));

switch tail
    case 'both'
        z = abs(norminv(p_adj / 2));
        effect = mean(A - B, 2);
    case 'right'
        z = abs(norminv(p_adj));
        effect = mean(A, 2);
    otherwise
        error('tail must be ''both'' or ''right''.');
end

effect(~h_adj) = 0;

T.p     = P;
T.p_fdr = p_adj;
T.z     = z;
T.stat  = z .* sign(effect);
T.sig   = h_adj;
end
