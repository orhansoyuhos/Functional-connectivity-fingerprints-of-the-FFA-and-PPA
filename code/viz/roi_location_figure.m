function roi_location_figure(S, G, seeds, file)
% ROI_LOCATION_FIGURE  The 33 target regions on the left hemisphere (Figure 3A).
%
%   roi_location_figure(S, G, seeds, file)
%
% S      load_surface(cfg); G roi_groups(cfg)
% seeds  {FFA parcel label, PPA parcel label} for the red and blue dots
% file   output PNG
%
% Lateral, medial and ventral views of the left hemisphere; each region is
% coloured by its group (legend: legend_image(..., 'groups_colored')) and
% outlined in white.
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

base = [0.78 0.78 0.78];
colorOf = repmat(base, 361, 1);           % row p+1 = colour of parcel p (row 1: medial wall)
isRoi = false(361, 1);
for k = 1:numel(G.names)
    p = parcel_index(S.labels, hcp_label(G.names{k}, 'L'));
    colorOf(p + 1, :) = G.group_colors(strcmp(G.groups, G.group{k}), :);
    isRoi(p + 1) = true;
end

% one parcel per triangle (the most common one among its corners)
F = S.faces;
fp = mode(S.parcel(F), 2);
faceRGB = colorOf(fp + 1, :);

% outline: mesh edges between triangles of different parcels, one of them a region
E = [F(:, [1 2]); F(:, [2 3]); F(:, [3 1])];
face_id = repmat((1:size(F, 1))', 3, 1);
[E, ~, ic] = unique(sort(E, 2), 'rows');
f1 = accumarray(ic, face_id, [], @min);
f2 = accumarray(ic, face_id, [], @max);
differ = fp(f1) ~= fp(f2) & (isRoi(fp(f1) + 1) | isRoi(fp(f2) + 1));
outline = E(differ, :);

mk = [S.marker(parcel_index(S.labels, seeds{1}), :); S.marker(parcel_index(S.labels, seeds{2}), :)];
seed_colors = [0.8039 0 0; 0 0 0.8039];   % FFA red, PPA blue
o = struct('edges', false, 'resolution', 200, 'outline', outline);
views = {'lateral', 'medial', 'ventral'};
imgs = cell(1, 3);
for k = 1:3
    m = mk;
    if k < 3, m = zeros(0, 3); end      % seed dots on the ventral view only
    o.marker_color = seed_colors(1:size(m, 1), :);
    imgs{k} = render_brain_view(S, faceRGB, [], [], 'L', views{k}, m, o);
end
W = max(cellfun(@(x) size(x, 2), imgs));
col = [];
for k = 1:3
    d = W - size(imgs{k}, 2);
    h = size(imgs{k}, 1);
    x = [255 * ones(h, floor(d / 2), 3, 'uint8'), imgs{k}, 255 * ones(h, d - floor(d / 2), 3, 'uint8')];
    col = [col; x; 255 * ones(20, W, 3, 'uint8')]; %#ok<AGROW>
end
folder = fileparts(file);
if ~exist(folder, 'dir'), mkdir(folder); end
imwrite(col, file);
end
