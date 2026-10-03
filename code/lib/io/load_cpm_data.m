function [C, B] = load_cpm_data(cfg)
% LOAD_CPM_DATA  Connectivity and behaviour of the 371-subject CPM cohort.
%
% C.labels  parcel labels (the parcels of all CPM networks)
% C.data    nParcels x nParcels x 371 fMRI partial correlations
% B         table, one row per subject in the same order: median RTs and
%           accuracies of the three tasks and mean_FD (mm)
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

S = load(fullfile(cfg.data_dir, 'fmri_371subjs_network_connectivity.mat'), 'cpm');
C = S.cpm;
B = readtable(fullfile(cfg.data_dir, 'behaviour_371subjs.csv'), 'TreatAsMissing', 'NA');
assert(height(B) == size(C.data, 3), 'Behaviour and connectivity have different numbers of subjects.');
end
