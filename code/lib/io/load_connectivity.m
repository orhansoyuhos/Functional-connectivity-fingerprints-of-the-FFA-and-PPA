function D = load_connectivity(cfg, metric)
% LOAD_CONNECTIVITY  Load the seed-based connectivity data of the 55 subjects.
%
%   D = load_connectivity(cfg, 'fmri')   % ridge-regularised partial correlation
%   D = load_connectivity(cfg, 'opec')   % MEG orthogonalised power-envelope correlation
%   D = load_connectivity(cfg, 'icoh')   % MEG imaginary part of coherency
%   D = load_connectivity(cfg, 'pdc')    % MEG partial directed coherence
%
% Fields of D (see data/README.md):
%   labels   360 x 1 HCP-MMP1 parcel labels
%   seeds    seed parcel labels (rows of 'rows' and 'cols')
%   rows     nSeeds x 360 x nSubjects [x nBands]: seed -> parcel, for the
%            parcels of the seed's hemisphere (NaN for the other hemisphere;
%            PDC: only the 33 target regions)
%   cols     same size, parcel -> seed (PDC only)
%   wb_mean  nSubjects x 1 [x nBands]: each subject's mean over the whole
%            360 x 360 matrix (the baseline of the seed maps; not for PDC)
%   bands    band names (MEG)
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

files = struct('fmri', 'fmri_55subjs_seed_connectivity.mat', ...
               'opec', 'meg_55subjs_seed_connectivity_opec.mat', ...
               'icoh', 'meg_55subjs_seed_connectivity_icoh.mat', ...
               'pdc',  'meg_55subjs_seed_connectivity_pdc.mat');
assert(isfield(files, metric), 'Unknown metric "%s".', metric);
S = load(fullfile(cfg.data_dir, files.(metric)), 'conn');
D = S.conn;
D.metric = metric;
end
