function legend_image(file, kind, G)
% LEGEND_IMAGE  Small legend panels of Figures 2 and 3.
%
%   legend_image(file, 'groups', G)          V = Visual areas, ... (Figure 2B)
%   legend_image(file, 'groups_colored', G)  the same with the group colours (Figure 3A)
%   legend_image(file, 'contrast')           FFA-PPA (Figure 3B)
%   legend_image(file, 'directed')           seed -> ROIs / ROIs -> seed (Figures 3C, S3)
%   legend_image(file, 'seeds')              FFA / PPA dots (Figure 3A)
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

fig = figure('Visible', 'off', 'Color', 'w', 'Units', 'pixels', 'Position', [0 0 520 420]);
ax = axes(fig, 'Position', [0 0 1 1]); hold(ax, 'on'); axis(ax, 'off');
xlim(ax, [0 1]); ylim(ax, [0 1]);
switch kind
    case {'groups', 'groups_colored'}
        n = numel(G.groups);
        for g = 1:n
            y = 1 - (g - 0.5) / n;
            col = [1 1 1]; tc = 'k';
            if strcmp(kind, 'groups_colored')
                col = G.group_colors(g, :);
                if mean(col) < 0.45, tc = 'w'; end
            end
            rectangle(ax, 'Position', [0.02, y - 0.5 / n, 0.96, 1 / n], 'FaceColor', col, 'EdgeColor', 'none');
            text(ax, 0.04, y, sprintf('%s = %s', G.groups{g}, G.group_names{g}), 'FontSize', 15, 'Color', tc);
        end
        rectangle(ax, 'Position', [0.02 0 0.96 1], 'EdgeColor', [0.3 0.3 0.3]);
    case 'contrast'
        fig.Position(4) = 90;
        rectangle(ax, 'Position', [0.05 0.1 0.45 0.8], 'FaceColor', [0.8039 0 0], 'EdgeColor', 'k');
        rectangle(ax, 'Position', [0.50 0.1 0.45 0.8], 'FaceColor', [0 0 0.8039], 'EdgeColor', 'k');
        text(ax, 0.275, 0.5, 'FFA', 'Color', 'w', 'FontSize', 22, 'HorizontalAlignment', 'center');
        text(ax, 0.725, 0.5, 'PPA', 'Color', 'w', 'FontSize', 22, 'HorizontalAlignment', 'center');
    case 'directed'
        fig.Position(4) = 140;
        rectangle(ax, 'Position', [0.05 0.52 0.9 0.4], 'FaceColor', [240 50 230] / 255, 'EdgeColor', 'k');
        rectangle(ax, 'Position', [0.05 0.08 0.9 0.4], 'FaceColor', [60 180 75] / 255, 'EdgeColor', 'k');
        text(ax, 0.5, 0.72, 'FFA | PPA \rightarrow ROIs', 'Color', 'w', 'FontSize', 20, 'HorizontalAlignment', 'center');
        text(ax, 0.5, 0.28, 'ROIs \rightarrow FFA | PPA', 'Color', 'w', 'FontSize', 20, 'HorizontalAlignment', 'center');
    case 'seeds'
        fig.Position(4) = 110;
        plot(ax, 0.06, 0.7, 'o', 'MarkerSize', 12, 'MarkerFaceColor', [0.8039 0 0], 'MarkerEdgeColor', [0.8039 0 0]);
        plot(ax, 0.06, 0.3, 'o', 'MarkerSize', 12, 'MarkerFaceColor', [0 0 0.8039], 'MarkerEdgeColor', [0 0 0.8039]);
        text(ax, 0.12, 0.7, 'FFA = Fusiform face area', 'FontSize', 17);
        text(ax, 0.12, 0.3, 'PPA = Parahippocampal place area', 'FontSize', 17);
end
folder = fileparts(file);
if ~exist(folder, 'dir'), mkdir(folder); end
exportgraphics(fig, file, 'Resolution', 150, 'BackgroundColor', 'white');
close(fig);
end
