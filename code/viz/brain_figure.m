function brain_figure(S, values, style, cmax, seeds, file, opts)
% BRAIN_FIGURE  Six-view brain map of both hemispheres, as in Figures 1C/D, 2A, S1, S2.
%
%   brain_figure(S, values, style, cmax, seeds, file, opts)
%
% S       load_surface(cfg)
% values  360 x 1 signed z per parcel (left parcels from the left-hemisphere
%         analysis, right parcels from the right-hemisphere analysis)
% style   'seedmap' or 'contrast' (see brain_colors)
% cmax    upper end of the colour scale
% seeds   parcel indices that get a green dot ([] for none)
% file    output PNG
% opts    .label (colour-bar label), .title, .resolution (dpi of the views),
%         .layout 'wide' (default) or 'stacked' (right hemisphere below the
%         left, as in Figures S1 and S2), .colorbar (default true)
%
% Layout: left hemisphere lateral and medial with the ventral view below,
% then the right hemisphere medial and lateral with its ventral view, and
% the colour bar.
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

if nargin < 7, opts = struct(); end
if ~isfield(opts, 'label'), opts.label = ''; end
if ~isfield(opts, 'title'), opts.title = ''; end
if ~isfield(opts, 'resolution'), opts.resolution = 200; end
if ~isfield(opts, 'layout'), opts.layout = 'wide'; end
if ~isfield(opts, 'colorbar'), opts.colorbar = true; end

[vdata, cmap, clim_] = brain_colors(S, values, style, cmax);
blocks = cell(1, 2);
split = zeros(1, 2);   % x position between the two top views of each block
hemis = {'L', 'R'};
for h = 1:2
    mk = S.marker(seeds(seeds > 180 * (h - 1) & seeds <= 180 * h), :);
    if h == 1, top = {'lateral', 'medial'}; else, top = {'medial', 'lateral'}; end
    a = render_brain_view(S, vdata, cmap, clim_, hemis{h}, top{1}, mk, opts);
    b = render_brain_view(S, vdata, cmap, clim_, hemis{h}, top{2}, mk, opts);
    v = render_brain_view(S, vdata, cmap, clim_, hemis{h}, 'ventral', mk, opts);
    [blocks{h}, split(h)] = hemisphere_block(a, b, v);
end
if strcmp(opts.layout, 'stacked')
    Wmax = max(size(blocks{1}, 2), size(blocks{2}, 2));
    gap = 255 * ones(round(0.05 * size(blocks{1}, 1)), Wmax, 3, 'uint8');
    img = [pad_cols(blocks{1}, Wmax); gap; pad_cols(blocks{2}, Wmax)];
    labpos = [split(1), 0.12 * size(blocks{1}, 1); split(2), size(blocks{1}, 1) + size(gap, 1) + 0.12 * size(blocks{2}, 1)];
else
    Hmax = max(size(blocks{1}, 1), size(blocks{2}, 1));
    gap = 255 * ones(Hmax, round(0.04 * size(blocks{1}, 2)), 3, 'uint8');
    img = [pad_rows(blocks{1}, Hmax), gap, pad_rows(blocks{2}, Hmax)];
    labpos = [split(1), 0.1 * Hmax; split(2) + size(blocks{1}, 2) + size(gap, 2), 0.1 * Hmax];
end

% Final figure: the image, hemisphere labels and the colour bar
[H, W, ~] = size(img);
wfrac = 0.86;
if ~opts.colorbar, wfrac = 1; end
% window within the screen (larger figures are shrunk by MATLAB)
figW = min(1400, 850 * W / H / wfrac);
fig = figure('Visible', 'off', 'Color', 'w', 'Units', 'pixels', 'Position', [0 0 figW figW * H / W * wfrac]);
ax = axes(fig, 'Position', [0 0 wfrac 1]);
image(ax, img); axis(ax, 'image', 'off');
text(ax, labpos(1, 1), labpos(1, 2), 'LH', 'FontSize', 13, 'HorizontalAlignment', 'center');
text(ax, labpos(2, 1), labpos(2, 2), 'RH', 'FontSize', 13, 'HorizontalAlignment', 'center');
if ~isempty(opts.title)
    text(ax, W / 2, 0.02 * H, opts.title, 'FontSize', 14, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end
if opts.colorbar
    cax = axes(fig, 'Position', [0.89 0.12 0.022 0.76]);
    draw_colorbar(cax, style, cmax, opts.label);
end

folder = fileparts(file);
if ~exist(folder, 'dir'), mkdir(folder); end
exportgraphics(fig, file, 'Resolution', 200, 'BackgroundColor', 'white');
close(fig);
end

function [blk, split] = hemisphere_block(a, b, v)
% [a b] on top, v centred below and moved up into the gap a little.
% split: x position between a and b.
a = pad_rows(a, size(b, 1)); b = pad_rows(b, size(a, 1));
top = [a, 255 * ones(size(a, 1), 10, 3, 'uint8'), b];
W = max(size(top, 2), size(v, 2));
split = size(a, 2) + 5 + floor((W - size(top, 2)) / 2);
top = pad_cols(top, W);
v = pad_cols(v, W);
overlap = round(0.25 * size(v, 1));
H = size(top, 1) + size(v, 1) - overlap;
blk = 255 * ones(H, W, 3, 'uint8');
blk(1:size(top, 1), :, :) = top;
r = H - size(v, 1) + 1:H;
blk(r, :, :) = min(blk(r, :, :), v);   % darker pixel wins where they overlap
end

function x = pad_rows(x, n)
if size(x, 1) >= n, return, end
d = n - size(x, 1); t = floor(d / 2);
x = [255 * ones(t, size(x, 2), 3, 'uint8'); x; 255 * ones(d - t, size(x, 2), 3, 'uint8')];
end

function x = pad_cols(x, n)
if size(x, 2) >= n, return, end
d = n - size(x, 2); l = floor(d / 2);
x = [255 * ones(size(x, 1), l, 3, 'uint8'), x, 255 * ones(size(x, 1), d - l, 3, 'uint8')];
end
