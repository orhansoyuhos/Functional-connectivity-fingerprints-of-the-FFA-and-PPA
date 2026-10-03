function seconds = run_step(script)
% RUN_STEP  Run one analysis or figure script in its own workspace.
%
%   seconds = run_step('code/analysis/a01_fmri_seed_maps.m')
%
% Scripts share variable names (cfg, S, R, ...); running each one inside
% this function keeps them from overwriting each other. Returns the run time.
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

run_step_start_ = tic;   % a name the scripts do not use (they run in this workspace)
fprintf('\n== %s\n', script);
run(script);
seconds = toc(run_step_start_);
fprintf('   done in %.1f s\n', seconds);
end
