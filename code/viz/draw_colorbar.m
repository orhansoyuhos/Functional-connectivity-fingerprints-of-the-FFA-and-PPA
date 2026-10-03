function draw_colorbar(cax, style, cmax, label, file)
% DRAW_COLORBAR  Colour bar of the brain maps.
%
%   draw_colorbar(cax, style, cmax, label)        into the axes cax
%   draw_colorbar([], style, cmax, label, file)   as a separate PNG
%
% style 'seedmap' or 'contrast', cmax the end of the scale (brain_colors).
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

if isempty(cax)
    fig = figure('Visible', 'off', 'Color', 'w', 'Units', 'pixels', 'Position', [0 0 170 520]);
    cax = axes(fig, 'Position', [0.25 0.08 0.18 0.84]);
end
[~, cmap, clim_] = brain_colors(struct('parcel', 1), 0, style, cmax);
image(cax, [0 1], [clim_(1) clim_(2)], permute(cmap, [1 3 2]));
set(cax, 'YDir', 'normal', 'XTick', [], 'YAxisLocation', 'right', 'FontSize', 11, 'Box', 'on');
if strcmp(style, 'seedmap')
    ylim(cax, [0 cmax]); cax.YTick = [0 1.96 cmax];
else
    ylim(cax, [-cmax cmax]); cax.YTick = [-cmax -1.96 0 1.96 cmax];
end
ylabel(cax, label, 'FontSize', 12);
title(cax, 'z', 'FontSize', 11, 'FontWeight', 'normal');

if nargin >= 5
    folder = fileparts(file);
    if ~exist(folder, 'dir'), mkdir(folder); end
    exportgraphics(cax.Parent, file, 'Resolution', 200, 'BackgroundColor', 'white');
    close(cax.Parent);
end
end
