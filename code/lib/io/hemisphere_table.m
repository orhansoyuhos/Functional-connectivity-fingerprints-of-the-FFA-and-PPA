function T = hemisphere_table(RL, RR, exclude)
% HEMISPHERE_TABLE  Significant regions of a left and right analysis, side by side.
%
%   T = hemisphere_table(RL, RR, {'FFC', 'PHA3'})
%
% RL and RR are seed_test results over the 180 parcels of each hemisphere.
% One row per region that is significant in at least one hemisphere, in
% character order of the region name (as in Tables 1, S2 and S3); regions
% in 'exclude' (the seeds) are left out. Columns:
%   parcel, sign (+1/-1, the direction; NaN if the hemispheres disagree),
%   L_p_fdr, L_z, R_p_fdr, R_z (NaN where not significant).
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

if nargin < 3, exclude = {}; end
nameL = bare_name(RL.labels);
nameR = bare_name(RR.labels);
assert(isequal(nameL, nameR), 'Left and right parcels must be in the same order.');

sig = (RL.stat ~= 0) | (RR.stat ~= 0);
sig = sig & ~ismember(nameL, exclude);
names = nameL(sig);
[names, order] = sort(names);
k = find(sig);
k = k(order);

T = table(names, 'VariableNames', {'parcel'});
sL = sign(RL.stat(k));
sR = sign(RR.stat(k));
s = sL + sR;
direction = sign(s);
direction(sL ~= 0 & sR ~= 0 & sL ~= sR) = NaN;
T.sign = direction;
T.L_p_fdr = masked(RL.p_fdr(k), RL.stat(k));
T.L_z     = masked(RL.z(k),     RL.stat(k));
T.R_p_fdr = masked(RR.p_fdr(k), RR.stat(k));
T.R_z     = masked(RR.z(k),     RR.stat(k));
end

function v = masked(v, stat)
v(stat == 0) = NaN;
end
