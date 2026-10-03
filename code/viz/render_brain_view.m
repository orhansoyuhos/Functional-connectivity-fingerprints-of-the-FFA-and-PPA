function img = render_brain_view(S, vdata, cmap, clim_, hemi, view_name, markers, opts)
% RENDER_BRAIN_VIEW  One view of one hemisphere, returned as an RGB image.
%
%   img = render_brain_view(S, vdata, cmap, clim_, hemi, view_name, markers, opts)
%
% S          load_surface(cfg)
% vdata      per-vertex values (with cmap and clim_), per-vertex RGB
%            (nVertices x 3, cmap empty) or per-face RGB (nFaces x 3, cmap
%            empty: flat colours)
% hemi       'L' or 'R'
% view_name  'lateral', 'medial' or 'ventral'
% markers    k x 3 positions (mm) of seed dots, or []; opts.marker_color
%            gives one colour per row (default green)
% opts       .resolution (dpi, default 200), .edges (true: draw faint mesh
%            lines), .outline (k x 2 vertex pairs drawn as thin white
%            lines)
%
% All views share the same scale, so the images can be put side by side.
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

if nargin < 7, markers = []; end
if nargin < 8, opts = struct(); end
if ~isfield(opts, 'resolution'), opts.resolution = 200; end
if ~isfield(opts, 'edges'), opts.edges = true; end
if ~isfield(opts, 'outline'), opts.outline = zeros(0, 2); end
if ~isfield(opts, 'marker_color'), opts.marker_color = repmat([0 0.9 0], size(markers, 1), 1); end

h = 1 + strcmpi(hemi, 'R');
keepV = S.hemi == h;
faceMask = all(keepV(S.faces), 2);
faces = S.faces(faceMask, :);

fig = figure('Visible', 'off', 'Color', 'w', 'Position', [0 0 1000 800], 'InvertHardcopy', 'off');
ax = axes(fig, 'Position', [0 0 1 1]);
hold(ax, 'on');
if isempty(cmap) && size(vdata, 1) == size(S.faces, 1)
    p = patch(ax, 'Faces', faces, 'Vertices', S.vertices, 'FaceVertexCData', vdata(faceMask, :), ...
        'FaceColor', 'flat', 'EdgeColor', 'none');
elseif isempty(cmap)
    p = patch(ax, 'Faces', faces, 'Vertices', S.vertices, 'FaceVertexCData', vdata, ...
        'FaceColor', 'interp', 'EdgeColor', 'none');
else
    p = patch(ax, 'Faces', faces, 'Vertices', S.vertices, 'FaceVertexCData', vdata(:), ...
        'FaceColor', 'interp', 'CDataMapping', 'scaled', 'EdgeColor', 'none');
    colormap(ax, cmap);
    caxis(ax, clim_); %#ok<CAXIS> clim needs R2022a or later
end
if opts.edges
    p.EdgeColor = [0.69 0.69 0.69];
    p.LineStyle = ':';
    p.LineWidth = 0.1;
end
p.FaceLighting = 'gouraud';
p.EdgeLighting = 'none';
p.AmbientStrength = 0.45;
p.DiffuseStrength = 0.6;
p.SpecularStrength = 0.05;

% outlines, moved slightly outwards so that they are not hidden by the surface
if ~isempty(opts.outline)
    e = opts.outline(all(keepV(opts.outline), 2), :);
    c = mean(S.vertices(keepV, :), 1);
    out = S.vertices - c;
    V = S.vertices + 0.6 * out ./ vecnorm(out, 2, 2);
    X = [V(e(:, 1), 1), V(e(:, 2), 1), nan(size(e, 1), 1)]';
    Y = [V(e(:, 1), 2), V(e(:, 2), 2), nan(size(e, 1), 1)]';
    Z = [V(e(:, 1), 3), V(e(:, 2), 3), nan(size(e, 1), 1)]';
    plot3(ax, X(:), Y(:), Z(:), '-', 'Color', [1 1 1], 'LineWidth', 0.6);
end

% markers (small spheres)
[sx, sy, sz] = sphere(20);
for m = 1:size(markers, 1)
    surf(ax, 1.6 * sx + markers(m, 1), 1.6 * sy + markers(m, 2), 1.6 * sz + markers(m, 3), ...
        'FaceColor', opts.marker_color(m, :), 'EdgeColor', 'none', 'FaceLighting', 'gouraud');
end

% camera: x anterior, y left, z up (orthographic, fixed scale for all views)
switch [lower(hemi(1)) '-' view_name]
    case {'l-lateral', 'r-medial'},  az = 180; el = 0;
    case {'l-medial', 'r-lateral'},  az = 0;   el = 0;
    case 'l-ventral',                az = 180; el = -90;
    case 'r-ventral',                az = 0;   el = -90;
    otherwise, error('Unknown view %s', view_name);
end
axis(ax, 'equal', 'off');
lim = 115;
xlim(ax, [-lim lim]); ylim(ax, [-lim lim]); zlim(ax, [-lim lim]);
ax.CameraTarget = mean(S.vertices(keepV, :), 1);
view(ax, az, el);
camproj(ax, 'orthographic');
ax.CameraViewAngleMode = 'manual';
ax.CameraViewAngle = 11;
camlight(ax, 'headlight');
material(ax, 'dull');

img = print(fig, '-RGBImage', sprintf('-r%d', opts.resolution));
close(fig);
img = crop_white(img);
end

function img = crop_white(img)
nonwhite = any(img < 250, 3);
r = find(any(nonwhite, 2));
c = find(any(nonwhite, 1));
pad = 4;
r = max(1, r(1) - pad):min(size(img, 1), r(end) + pad);
c = max(1, c(1) - pad):min(size(img, 2), c(end) + pad);
img = img(r, c, :);
end
