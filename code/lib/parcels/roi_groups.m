function G = roi_groups(cfg)
% ROI_GROUPS  The 33 Table 1 regions in the order of the circular graphs.
%
% G.names        33 x 1 region names (circle order of Figures 2B, 3B, 3C, S3)
% G.group        group abbreviation of each region (V, MT+, LO, ...)
% G.groups       the 11 groups in order, with
% G.group_names  their full names and
% G.group_colors their colours (Figure 3A)
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

T = readtable(fullfile(cfg.data_dir, 'atlas', 'roi_groups.csv'), 'TextType', 'string', 'Delimiter', ',');
T = sortrows(T, 'order');
G.names = cellstr(T.parcel);
G.group = cellstr(T.group);
[~, first] = unique(T.group, 'stable');
G.groups = cellstr(T.group(first));
G.group_names = cellstr(T.group_name(first));
G.group_colors = hex2rgb(T.group_color(first));
end

function rgb = hex2rgb(hex)
hex = char(erase(hex, "#"));
rgb = [hex2dec(hex(:, 1:2)), hex2dec(hex(:, 3:4)), hex2dec(hex(:, 5:6))] / 255;
end
