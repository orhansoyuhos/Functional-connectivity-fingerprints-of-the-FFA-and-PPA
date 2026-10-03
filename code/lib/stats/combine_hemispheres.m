function C = combine_hemispheres(RL, RR, is_contrast, cfg)
% COMBINE_HEMISPHERES  Combine the left- and right-hemisphere results (Figures 3 and S3).
%
%   C = combine_hemispheres(RL, RR, is_contrast, cfg)
%
% RL and RR are seed_test results for the same regions (same order) in the
% left and right hemisphere. As in the paper (Figure 3, Figure S3):
%   z = (z_L + z_R) / sqrt(2)
% where z_L and z_R are the signed z-scores, set to 0 where a hemisphere is
% not significant. A region is kept when it is significant in at least one
% hemisphere (|z| above the threshold of the test: norminv(1 - alpha/2) for
% the FFA-PPA contrast, norminv(1 - alpha) for the directed PDC analysis).
%
% C.value  combined z per region (0 = no line)
% C.zL, C.zR  the signed per-hemisphere z-scores
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

if is_contrast
    thr = norminv(1 - cfg.alpha / 2);
else
    thr = norminv(1 - cfg.alpha);
end

zL = RL.z .* sign(RL.stat);
zR = RR.z .* sign(RR.stat);
z = (zL + zR) / sqrt(2);
keep = abs(RL.z) > thr | abs(RR.z) > thr;

C.value = zeros(size(z));
C.value(keep) = z(keep);
C.zL = zL;
C.zR = zR;
end
