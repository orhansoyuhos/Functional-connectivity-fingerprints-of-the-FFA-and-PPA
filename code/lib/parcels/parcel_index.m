function idx = parcel_index(labels, wanted)
% PARCEL_INDEX  Positions of parcel labels within a label list.
%
%   idx = parcel_index(labels, 'L_FFC_ROI L')
%   idx = parcel_index(labels, {'L_FFC_ROI L', 'R_FFC_ROI R'})
%
% Errors if a label is missing or not unique. The match ignores case.
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

if ~iscell(wanted), wanted = {wanted}; end
idx = zeros(1, numel(wanted));
for k = 1:numel(wanted)
    i = find(strcmpi(labels, wanted{k}));
    assert(isscalar(i), 'Parcel "%s" not found (or not unique).', wanted{k});
    idx(k) = i;
end
end
