function fig = circle_graph(G, values, mode, opts)
% CIRCLE_GRAPH  Circular graph of seed-to-region connections (Figures 2B, 3B, 3C, S3).
%
%   fig = circle_graph(G, values, mode, opts)
%
% G       roi_groups(cfg): the 33 regions in circle order, with groups
% values  33 x 1 values per region (z; 0 = no line)
% mode    'contrast'  two seeds (FFA above, PPA below): positive values are
%                     drawn from the FFA (red), negative values from the PPA
%                     (blue)
%         'directed'  one seed: positive = seed -> region (magenta),
%                     negative = region -> seed (green)
% opts    struct, optional fields:
%   seed_labels  {'FFA', 'PPA'} or {'FFA'} (default by mode)
%   ring_colors  true: fill the group ring with the group colours (Figure 3B)
%   title        text above the circle
%   width_coef   line width per unit of |z| in points (default 1.2)
%   font_size    font size of the region labels; the other text scales with
%                it (default 13)
%   visible      'off' (default) or 'on'
%
% Layout: the seeds sit at 9 o'clock, the regions
% run clockwise from V3B (just above the seeds) to PEF (just below), each
% line is a circular arc meeting the circle at right angles, and the line
% width is proportional to |z|.
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

if nargin < 4, opts = struct(); end
nR = numel(G.names);
values = values(:);
assert(numel(values) == nR, 'values must have one entry per region.');
contrast = strcmp(mode, 'contrast');
def = struct('seed_labels', {{'FFA', 'PPA'}}, 'ring_colors', false, 'title', '', ...
             'width_coef', 1.2, 'visible', 'off', 'font_size', 13);
if ~contrast, def.seed_labels = {'FFA'}; end
f = fieldnames(def);
for k = 1:numel(f)
    if ~isfield(opts, f{k}), opts.(f{k}) = def.(f{k}); end
end

red = [0.8039 0 0]; blue = [0 0 0.8039];
magenta = [240 50 230] / 255; green = [60 180 75] / 255;

% Node order around the circle: seeds first, then the regions in reverse,
% at angles -pi ... pi.
nS = 1 + contrast;
n = nS + nR;
theta = linspace(-pi, pi, n + 1);
theta = theta(1:n);
pos = [cos(theta)', sin(theta)'];
regionNode = nS + (nR:-1:1);          % node index of region k

fig = figure('Visible', opts.visible, 'Color', 'w', 'Position', [100 100 760 760]);
ax = axes(fig, 'Position', [0.02 0.02 0.96 0.96]);
hold(ax, 'on'); axis(ax, 'equal', 'off');
lim = 1.42;
xlim(ax, [-lim lim]); ylim(ax, [-lim lim]);

% Group ring
r1 = 1.01; r2 = 1.09;
groupIdx = cellfun(@(g) find(strcmp(G.groups, g)), G.group);
dth = 2 * pi / n;
for g = 1:numel(G.groups)
    a = theta(regionNode(groupIdx == g));
    a1 = max(a) + dth / 2; a0 = min(a) - dth / 2;
    if opts.ring_colors
        t = linspace(a0, a1, 40);
        patch(ax, [r1 * cos(t), r2 * cos(fliplr(t))], [r1 * sin(t), r2 * sin(fliplr(t))], ...
            G.group_colors(g, :), 'EdgeColor', 'none');
    end
    for b = [a0, a1]
        plot(ax, [r1 r2] * cos(b), [r1 r2] * sin(b), 'k-', 'LineWidth', 0.8);
    end
    am = (a0 + a1) / 2;
    tc = 'k';
    if opts.ring_colors && mean(G.group_colors(g, :)) < 0.45, tc = 'w'; end
    rot = rad2deg(am) - 90;
    if sin(am) < 0, rot = rot + 180; end
    text(ax, 1.05 * cos(am), 1.05 * sin(am), G.groups{g}, 'Rotation', rot, 'Color', tc, ...
        'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', 'FontSize', opts.font_size - 4);
end
tc = linspace(0, 2 * pi, 361);
plot(ax, r1 * cos(tc), r1 * sin(tc), 'k-', 'LineWidth', 1.2);
plot(ax, r2 * cos(tc), r2 * sin(tc), 'k-', 'LineWidth', 1.2);

% Lines: draw thin ones first so thick ones stay on top
[~, order] = sort(abs(values));
for k = order'
    v = values(k);
    if v == 0, continue, end
    if contrast
        if v > 0, s = 1; col = red; else, s = 2; col = blue; end
    else
        s = 1;
        if v > 0, col = magenta; else, col = green; end
    end
    [x, y] = arc(pos(s, :), pos(regionNode(k), :));
    plot(ax, x, y, '-', 'Color', col, 'LineWidth', max(opts.width_coef * abs(v), 0.1));
    plot(ax, pos(regionNode(k), 1), pos(regionNode(k), 2), 'o', 'MarkerSize', 3.5, ...
        'MarkerEdgeColor', col, 'MarkerFaceColor', 'w', 'LineWidth', 0.8);
end

% Region labels
for k = 1:nR
    a = theta(regionNode(k));
    rot = rad2deg(a);
    ha = 'left';
    if cos(a) < 0, rot = rot + 180; ha = 'right'; end
    text(ax, 1.12 * cos(a), 1.12 * sin(a), G.names{k}, 'Rotation', rot, ...
        'HorizontalAlignment', ha, 'VerticalAlignment', 'middle', 'FontSize', opts.font_size);
end

% Seed labels and dots
for s = 1:nS
    if contrast
        col = red; if s == 2, col = blue; end
    else
        col = 'k';
    end
    plot(ax, pos(s, 1), pos(s, 2), 'o', 'MarkerSize', 4, 'MarkerFaceColor', col, 'MarkerEdgeColor', col);
    text(ax, 1.12 * pos(s, 1), 1.12 * pos(s, 2), opts.seed_labels{s}, 'Color', col, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'right', 'VerticalAlignment', 'middle', 'FontSize', opts.font_size + 1);
end

if ~isempty(opts.title)
    text(ax, 0, 1.38, opts.title, 'HorizontalAlignment', 'center', 'FontSize', opts.font_size + 3);
end
end

function [x, y] = arc(u, w)
% Circular arc between two points on the unit circle, orthogonal to it
% (a straight line when the points are opposite).
u = u(:); w = w(:);
den = u(1) * w(2) - u(2) * w(1);
if abs(den) < 1e-9
    x = [u(1) w(1)]; y = [u(2) w(2)];
    return
end
x0 = -(u(2) - w(2)) / den;
y0 =  (u(1) - w(1)) / den;
r = sqrt(x0^2 + y0^2 - 1);
a1 = atan2(u(2) - y0, u(1) - x0);
a2 = atan2(w(2) - y0, w(1) - x0);
% take the shorter way round (the arc inside the unit circle)
if abs(a2 - a1) > pi
    if a1 < a2, a1 = a1 + 2 * pi; else, a2 = a2 + 2 * pi; end
end
t = linspace(a1, a2, 100);
x = x0 + r * cos(t);
y = y0 + r * sin(t);
end
