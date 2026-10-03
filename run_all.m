function run_all(varargin)
% RUN_ALL  Run all analyses and make the tables and figures of the paper.
%
%   run_all                        % everything, as in the paper
%   run_all('Permutations', 0)     % skip the CPM permutation tests (fast)
%   run_all('Parallel', false)     % permutations without the parallel pool
%   run_all('RunR', false)         % MATLAB part only
%   run_all('Rscript', 'C:\Program Files\R\R-4.4.1\bin\Rscript.exe')
%
% Steps (each script can also be run on its own after config):
%   code/analysis/a01-a06   statistics -> results/tables, results/analysis, results/cpm
%   code/figures/f01-f05    brain maps and circular graphs -> results/figures
%   code/R/*.R              Figures 5, 6, S4, S5, bootstrap CIs, formatted tables
% A log with the run time of each step is written to results/RUN_LOG.md.
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

ip = inputParser;
addParameter(ip, 'Permutations', []);
addParameter(ip, 'Parallel', []);
addParameter(ip, 'RunR', []);
addParameter(ip, 'Rscript', []);
parse(ip, varargin{:});
opts = struct();
for f = fieldnames(ip.Results)'
    if ~isempty(ip.Results.(f{1})), opts.(f{1}) = ip.Results.(f{1}); end
end
setappdata(0, 'face_scene_options', opts);
cleanup = onCleanup(@() rmappdata_safe());

cfg = config();
for d = {cfg.results_dir, cfg.tables_dir, cfg.figures_dir, cfg.cpm_dir, fullfile(cfg.results_dir, 'analysis')}
    if ~exist(d{1}, 'dir'), mkdir(d{1}); end
end
fprintf('Face/scene connectivity: running the analyses (CPM permutations: %d)\n', cfg.cpm.n_permutations);

steps = {'code/analysis/a01_fmri_seed_maps.m', ...
         'code/analysis/a02_fmri_contrast.m', 'code/analysis/a03_meg_wholebrain.m', ...
         'code/analysis/a04_meg_roi.m', 'code/analysis/a05_cpm.m', 'code/analysis/a06_behaviour.m', ...
         'code/figures/f01_figure1.m', 'code/figures/f02_figure2.m', 'code/figures/f03_figure3.m', ...
         'code/figures/f04_figures_S1_S2.m', 'code/figures/f05_figure_S3.m'};
run_log = {};
t_all = tic;
for k = 1:numel(steps)
    s = run_step(fullfile(cfg.root, steps{k}));
    run_log{end+1} = sprintf('| %s | %.0f |', steps{k}, s); %#ok<AGROW>
end

% R: Figures 5, 6, S4, S5, bootstrap CIs and formatted tables
if cfg.run_R
    rs = find_rscript(cfg);
    if isempty(rs)
        warning('Rscript not found: the R figures and tables were not made. Set cfg.rscript in config.m or run code/R/*.R yourself.');
    else
        for r = {'figure_S4.R', 'cpm_figures.R', 'tables.R'}
            t0 = tic;
            fprintf('\n== code/R/%s\n', r{1});
            status = system(sprintf('"%s" "%s" "%s"', rs, fullfile(cfg.root, 'code', 'R', r{1}), cfg.root));
            if status ~= 0, warning('R script %s failed.', r{1}); end
            run_log{end+1} = sprintf('| code/R/%s | %.0f |', r{1}, toc(t0)); %#ok<AGROW>
        end
    end
end

total = toc(t_all);

v = ver('MATLAB');
stamp = char(datetime('now', 'Format', 'yyyy-MM-dd HH:mm'));
txt = [{'# Run log', '', sprintf('%s, MATLAB %s, CPM permutations %d, total %.0f s (%.1f min).', ...
        stamp, v.Version, cfg.cpm.n_permutations, total, total / 60), '', ...
        '| step | seconds |', '|---|---|'}, run_log];
fid = fopen(fullfile(cfg.results_dir, 'RUN_LOG.md'), 'w');
fprintf(fid, '%s\n', txt{:});
fclose(fid);
fprintf('\nDone in %.1f min. Results in %s\n', total / 60, cfg.results_dir);
end

function rs = find_rscript(cfg)
rs = cfg.rscript;
if ~isempty(rs) && isfile(rs), return, end
rs = '';
if ispc
    [st, out] = system('where Rscript');
else
    [st, out] = system('which Rscript');
end
if st == 0
    lines = strtrim(strsplit(strtrim(out), newline));
    rs = lines{1};
    return
end
if ispc
    d = dir(fullfile(getenv('ProgramFiles'), 'R', 'R-*'));
    if ~isempty(d)
        [~, i] = sort({d.name});
        c = fullfile(d(i(end)).folder, d(i(end)).name, 'bin', 'Rscript.exe');
        if isfile(c), rs = c; end
    end
end
end

function rmappdata_safe()
if isappdata(0, 'face_scene_options'), rmappdata(0, 'face_scene_options'); end
end
