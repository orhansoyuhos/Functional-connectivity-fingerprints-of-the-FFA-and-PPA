function panel_figure(file, panels, width_px, height_px)
% PANEL_FIGURE  Put image files together into one multi-panel figure.
%
%   panel_figure(file, panels, width_px, height_px)
%
% panels  struct array with fields
%           file    PNG of the panel
%           pos     [x y w h] in normalised figure units (0-1, from bottom left)
%           letter  panel letter ('' for none)
% The panel images keep their aspect ratio inside their box.
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

% Keep the window within the screen (MATLAB shrinks larger figures, which
% would distort the panels) and export at a higher resolution instead.
scale = min([1, 1600 / width_px, 900 / height_px]);
fig = figure('Visible', 'off', 'Color', 'w', 'Units', 'pixels', ...
    'Position', [0 0 round(width_px * scale) round(height_px * scale)]);
for k = 1:numel(panels)
    P = panels(k);
    ax = axes(fig, 'Position', P.pos);
    img = imread(P.file);
    image(ax, img);
    axis(ax, 'image', 'off');
    if isfield(P, 'letter') && ~isempty(P.letter)
        annotation(fig, 'textbox', [max(0, P.pos(1) - 0.005), min(0.96, max(0, P.pos(2) + P.pos(4) - 0.04)), 0.04, 0.04], ...
            'String', P.letter, 'FontSize', 20, 'EdgeColor', 'none', 'VerticalAlignment', 'top');
    end
end
folder = fileparts(file);
if ~exist(folder, 'dir'), mkdir(folder); end
exportgraphics(fig, file, 'Resolution', round(150 / scale), 'BackgroundColor', 'white');
close(fig);
end
