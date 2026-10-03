function S = load_surface(cfg)
% LOAD_SURFACE  fsaverage surface (15002 vertices, inflated) with the HCP-MMP1 parcels.
%
% S.vertices  mm, x anterior, y left, z superior
% S.faces     triangles
% S.parcel    parcel index (1-360) of each vertex, 0 = medial wall
% S.hemi      1 = left, 2 = right
% S.labels    360 parcel labels
% S.marker    360 x 3: for each parcel, the vertex nearest to its centroid
%             (position of the seed dots)
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

L = load(fullfile(cfg.data_dir, 'surface', 'fsaverage_15k_inflated70_hcpmmp1.mat'), 'surface');
S = L.surface;
S.marker = nan(360, 3);
for p = 1:360
    v = find(S.parcel == p);
    if isempty(v), continue, end
    c = mean(S.vertices(v, :), 1);
    [~, j] = min(sum((S.vertices(v, :) - c).^2, 2));
    S.marker(p, :) = S.vertices(v(j), :);
end
end
