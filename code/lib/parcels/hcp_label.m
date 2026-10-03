function label = hcp_label(name, hemi)
% HCP_LABEL  Full HCP-MMP1 parcel label from a bare name and a hemisphere.
%
%   hcp_label('FFC', 'L')  ->  'L_FFC_ROI L'
%   hcp_label({'V4','MT'}, 'R')  ->  {'R_V4_ROI R', 'R_MT_ROI R'}
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

hemi = upper(char(hemi));
if iscell(name)
    label = cellfun(@(n) sprintf('%s_%s_ROI %s', hemi, n, hemi), name, 'UniformOutput', false);
else
    label = sprintf('%s_%s_ROI %s', hemi, char(name), hemi);
end
end
