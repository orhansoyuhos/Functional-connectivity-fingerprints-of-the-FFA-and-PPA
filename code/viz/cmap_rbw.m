function cmap = cmap_rbw(nSteps)
% CMAP_RBW  Dark blue -> white -> dark red colour map (2 * nSteps colours).
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

if nargin < 1, nSteps = 128; end
blue  = [0, 0, 0.8039216];
white = [1, 1, 1];
red   = [0.8039216, 0, 0];
c1 = [linspace(blue(1), white(1), nSteps)', linspace(blue(2), white(2), nSteps)', linspace(blue(3), white(3), nSteps)'];
c2 = [linspace(white(1), red(1), nSteps)', linspace(white(2), red(2), nSteps)', linspace(white(3), red(3), nSteps)'];
cmap = [c1; c2];
end
