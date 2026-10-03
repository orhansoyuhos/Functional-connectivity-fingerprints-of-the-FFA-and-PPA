function R = seed_test(D, mode, seeds, targets, band, cfg)
% SEED_TEST  Test the connectivity of a seed (or two seeds) with target parcels.
%
%   R = seed_test(D, 'contrast', {seed1, seed2}, targets, band, cfg)
%       seed1 vs seed2: is a target more strongly connected with seed1
%       or with seed2? Two-sided. Positive = seed1.
%   R = seed_test(D, 'mean', {seed}, targets, band, cfg)
%       Is a target more strongly connected with the seed than the
%       subject's whole-brain mean connectivity? One-sided (right).
%   R = seed_test(D, 'directed', {seed}, targets, band, cfg)
%       PDC seed -> target vs target -> seed. Two-sided.
%       Positive = seed -> target (outgoing).
%
% D comes from load_connectivity, seeds and targets are HCP-MMP1 labels and
% band is the band index (ignored for fMRI). The tests and the FDR family
% are the targets given (180 parcels of a hemisphere, or the 33 ROIs).
%
% Each seed's connectivity with itself is set to 1 before testing. This
% matters only when a seed is among the targets (the 180-parcel analyses),
% where the seed is then tested like any other parcel and counted in the
% FDR family.
%
% R holds the target labels and the fields of wilcoxon_fdr.
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

if ~iscell(seeds), seeds = {seeds}; end
if ~iscell(targets), targets = {targets}; end
if nargin < 5 || isempty(band), band = 1; end

idxT = parcel_index(D.labels, targets);

switch mode
    case 'contrast'
        i1 = parcel_index(D.labels, seeds{1});
        i2 = parcel_index(D.labels, seeds{2});
        A = seed_rows(D, 'rows', seeds{1}, band);
        B = seed_rows(D, 'rows', seeds{2}, band);
        A(i1, :) = 1;
        B(i2, :) = 1;
        T = wilcoxon_fdr(A(idxT, :), B(idxT, :), 'both', cfg);

    case 'mean'
        i1 = parcel_index(D.labels, seeds{1});
        A = seed_rows(D, 'rows', seeds{1}, band);
        A(i1, :) = 1;
        baseline = D.wb_mean(:, band)';
        B = repmat(baseline, numel(D.labels), 1);
        T = wilcoxon_fdr(A(idxT, :), B(idxT, :), 'right', cfg);

    case 'directed'
        A = seed_rows(D, 'rows', seeds{1}, band);   % seed -> target
        B = seed_rows(D, 'cols', seeds{1}, band);   % target -> seed
        A(isnan(A)) = 1;   % the seed's own entry is NaN in the PDC data
        B(isnan(B)) = 1;
        T = wilcoxon_fdr(A(idxT, :), B(idxT, :), 'both', cfg);

    otherwise
        error('mode must be ''contrast'', ''mean'' or ''directed''.');
end

R = T;
R.labels = targets(:);
R.mode = mode;
R.seeds = seeds;
R.band = band;
end

function X = seed_rows(D, field, seed, band)
% 360 x nSubjects connectivity of one seed (one band).
s = find(strcmp(D.seeds, seed));
assert(isscalar(s), 'Seed "%s" is not in the data file.', seed);
V = D.(field);
X = reshape(V(s, :, :, band), size(V, 2), size(V, 3));
end
