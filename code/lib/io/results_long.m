function T = results_long(R, extra)
% RESULTS_LONG  One row per target parcel of a seed_test result.
%
%   T = results_long(R, struct('analysis', 'contrast', 'band', 'beta'))
%
% Columns: the fields of 'extra' (repeated), hemisphere, parcel, label,
% p, p_fdr, z, stat, significant.
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

[names, hemi] = bare_name(R.labels);
n = numel(R.labels);
T = table();
if nargin > 1
    f = fieldnames(extra);
    for k = 1:numel(f)
        T.(f{k}) = repmat(string(extra.(f{k})), n, 1);
    end
end
T.hemisphere  = string(hemi);
T.parcel      = string(names);
T.label       = string(R.labels);
T.p           = R.p;
T.p_fdr       = R.p_fdr;
T.z           = R.z;
T.stat        = R.stat;
T.significant = double(R.sig);
end
