function [name, hemi] = bare_name(label)
% BARE_NAME  Bare region name and hemisphere of an HCP-MMP1 parcel label.
%
%   [name, hemi] = bare_name('L_FFC_ROI L')  ->  name 'FFC', hemi 'L'
%
% Works on a char label or a cell array of labels.
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

if iscell(label)
    [name, hemi] = cellfun(@bare_name, label, 'UniformOutput', false);
    return
end
tok = regexp(char(label), '^([LR])_(.+)_ROI [LR]$', 'tokens', 'once');
assert(~isempty(tok), 'Not an HCP-MMP1 label: %s', char(label));
hemi = tok{1};
name = tok{2};
end
