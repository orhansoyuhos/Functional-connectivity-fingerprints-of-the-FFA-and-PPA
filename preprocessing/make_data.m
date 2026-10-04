function make_data(source_dir)
% MAKE_DATA  Build the files in data/ from the complete connectivity matrices.
%
%   addpath('preprocessing')            % from the repository root
%   make_data(source_dir)
%
% This is the last step of preprocessing/ (see preprocessing/README.md). It
% needs the complete per-subject 360 x 360 connectivity matrices, which are not
% part of this repository (about 1.5 GB):
%
%   source_dir/connMatrices/rfMRI/Outputs_55subjs_partialcorr_rfMRI_MEAN.mat   (fmri/step2_parcellate_netmats.m,
%   source_dir/connMatrices/rfMRI/Outputs_371subjs_partialcorr_rfMRI_MEAN.mat   55 and 371 subjects)
%   source_dir/connMatrices/rMEG/Outputs_2s_55subjs_{opec,icoh,pdc}.mat        (MEG pipeline, meg/README.md)
%   source_dir/behaviScores/behavioral_data_371subjs.mat
%   source_dir/headMotion/rfMRI_headMotion_371subjs.mat
%   source_dir/fsaverage/fsaverage_inflated_0.mat, fsaverage_inflated_70.mat
%
% Nothing is written outside this repository's data/ folder.
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

cfg = config();
out = cfg.data_dir;
fprintf('Writing data files to %s\n', out);

seed_names = {cfg.seed_ffa, cfg.seed_ppa, cfg.seed_appa};
ROI = roi_groups(cfg);   % the 33 target regions of Table 1

% Only the connectivity that the analyses use is kept: each seed with the
% parcels of its own hemisphere (for PDC only the 33 target regions); all
% other entries are NaN.

%% 55 subjects, fMRI partial correlation (seed rows)
G = load(fullfile(source_dir, 'connMatrices', 'rfMRI', 'Outputs_55subjs_partialcorr_rfMRI_MEAN.mat'), 'group_results');
X = G.group_results.data_perSubject;              % 360 x 360 x 55
labels = G.group_results.label(:);
conn = struct();
conn.description = ['Resting-state fMRI, ridge-regularised partial correlation (FSLNets ridgep 0.01), ' ...
                    'HCP-MMP1 parcels, 55 subjects. Values only for the parcels in the hemisphere ' ...
                    'of the seed (NaN elsewhere)'];
conn.labels = labels;
conn.seeds = [hcp_label(seed_names, 'L'), hcp_label(seed_names, 'R')]';
conn.rows = keep_used(extract_rows(X, labels, conn.seeds), used_parcels(labels, conn.seeds, false, ROI));
conn.wb_mean = whole_brain_mean(X);
conn.n_subjects = size(X, 3);
save(fullfile(out, 'fmri_55subjs_seed_connectivity.mat'), 'conn', '-v7');
fprintf('  fMRI 55: rows %s\n', mat2str(size(conn.rows)));
clear X G

%% 55 subjects, MEG (FFC and PHA3 only)
meg_seeds = [hcp_label({cfg.seed_ffa, cfg.seed_ppa}, 'L'), hcp_label({cfg.seed_ffa, cfg.seed_ppa}, 'R')]';
names = struct('opec', 'orthogonalised power-envelope correlation (amplitude coupling)', ...
               'icoh', 'imaginary part of coherency (phase coupling)', ...
               'pdc',  'partial directed coherence (directed; rows = seed -> parcel, cols = parcel -> seed)');
for metric = {'opec', 'icoh', 'pdc'}
    m = metric{1};
    G = load(fullfile(source_dir, 'connMatrices', 'rMEG', sprintf('Outputs_2s_55subjs_%s.mat', m)), 'group_results');
    gr = G.group_results;
    assert(isequal(gr(1).label(:), labels), 'MEG labels differ from fMRI labels.');
    nb = numel(gr);
    pdc = strcmp(m, 'pdc');
    used = used_parcels(labels, meg_seeds, pdc, ROI);
    conn = struct();
    conn.description = sprintf('Resting-state MEG (2-s epochs), %s, HCP-MMP1 parcels, 55 subjects', names.(m));
    if pdc
        conn.description = [conn.description '. Values only for the 33 target regions of Table 1 ' ...
                            'in the hemisphere of the seed (NaN elsewhere)'];
    else
        conn.description = [conn.description '. Values only for the parcels in the hemisphere ' ...
                            'of the seed (NaN elsewhere)'];
    end
    conn.labels = labels;
    conn.seeds = meg_seeds;
    conn.bands = cellfun(@char, {gr.band}, 'UniformOutput', false);
    conn.band_edges = gr(1).freq_bands;
    conn.rows = [];
    for b = 1:nb
        X = gr(b).data_perSubject;
        conn.rows(:, :, :, b) = keep_used(extract_rows(X, labels, conn.seeds), used);
        if pdc
            conn.cols(:, :, :, b) = keep_used(extract_cols(X, labels, conn.seeds), used);
        else
            conn.wb_mean(:, b) = whole_brain_mean(X);   % the baseline of the seed maps
        end
    end
    conn.n_subjects = size(gr(1).data_perSubject, 3);
    save(fullfile(out, sprintf('meg_55subjs_seed_connectivity_%s.mat', m)), 'conn', '-v7');
    fprintf('  MEG %s: rows %s, bands %s\n', m, mat2str(size(conn.rows)), strjoin(conn.bands, ' '));
    clear G gr X
end

%% Networks used for CPM -> parcels to keep from the 371-subject matrices
D = load_connectivity(cfg, 'fmri');
keepParcels = {};
for s2 = {cfg.seed_ppa, cfg.seed_appa}
    RL = seed_test(D, 'contrast', {hcp_label(cfg.seed_ffa, 'L'), hcp_label(s2{1}, 'L')}, D.labels(1:180), 1, cfg);
    RR = seed_test(D, 'contrast', {hcp_label(cfg.seed_ffa, 'R'), hcp_label(s2{1}, 'R')}, D.labels(181:360), 1, cfg);
    N = define_networks(RL, RR, cfg.seed_ffa, s2{1});
    keepParcels = [keepParcels; N.net1; N.net2]; %#ok<AGROW>
end
keepIdx = sort(parcel_index(labels, unique(keepParcels)));

%% 371 subjects, fMRI partial correlation among the network parcels
G = load(fullfile(source_dir, 'connMatrices', 'rfMRI', 'Outputs_371subjs_partialcorr_rfMRI_MEAN.mat'), 'group_results');
assert(isequal(G.group_results.label(:), labels), '371-subject labels differ.');
cpm = struct();
cpm.description = ['Resting-state fMRI, ridge-regularised partial correlation, 371 subjects (one per family), ' ...
                   'restricted to the parcels of the CPM networks'];
cpm.labels = labels(keepIdx);
cpm.data = G.group_results.data_perSubject(keepIdx, keepIdx, :);
save(fullfile(out, 'fmri_371subjs_network_connectivity.mat'), 'cpm', '-v7');
fprintf('  fMRI 371: %d parcels, %s\n', numel(keepIdx), mat2str(size(cpm.data)));
clear G

%% Behaviour and head motion, 371 subjects (same order as the matrices)
S = load(fullfile(source_dir, 'behaviScores', 'behavioral_data_371subjs.mat'), 'behavioral_data');
H = load(fullfile(source_dir, 'headMotion', 'rfMRI_headMotion_371subjs.mat'), 'rfMRI_headMotion');
cols = {'Emotion_Task_Face_Median_RT', 'Emotion_Task_Face_Acc', ...
        'WM_Task_0bk_Place_Median_RT', 'WM_Task_0bk_Place_Acc', ...
        'WM_Task_2bk_Place_Median_RT', 'WM_Task_2bk_Place_Acc'};
T = S.behavioral_data(:, cols);
T.mean_FD = H.rfMRI_headMotion(:);
T = [table((1:height(T))', 'VariableNames', {'row'}), T];
write_csv_exact(T, fullfile(out, 'behaviour_371subjs.csv'));
fprintf('  behaviour: %d subjects, %d columns\n', height(T), width(T));

%% Cortical surface (fsaverage, 15002 vertices, inflated 70%) with HCP-MMP1
F0 = load(fullfile(source_dir, 'fsaverage', 'fsaverage_inflated_0.mat'), 'fsaverage');
F70 = load(fullfile(source_dir, 'fsaverage', 'fsaverage_inflated_70.mat'), 'Vertices', 'Faces');
fs = F0.fsaverage;
iAtlas = find(strcmp({fs.Atlas.Name}, 'HCP-MMP1.0'));
scouts = fs.Atlas(iAtlas).Scouts;
assert(isequal({scouts.Label}', labels), 'Surface atlas labels differ.');
parcel = zeros(size(fs.Vertices, 1), 1);
for k = 1:numel(scouts)
    parcel(scouts(k).Vertices) = k;
end
iStruct = find(strcmp({fs.Atlas.Name}, 'Structures'));
st = fs.Atlas(iStruct).Scouts;
hemi = zeros(size(parcel));
for k = 1:numel(st)
    switch st(k).Region(1)
        case 'L', hemi(st(k).Vertices) = 1;
        case 'R', hemi(st(k).Vertices) = 2;
    end
end
assert(all(hemi(parcel >= 1 & parcel <= 180) == 1) && all(hemi(parcel >= 181) == 2), ...
    'Hemisphere coding does not match the parcels.');
surface = struct();
surface.description = ['fsaverage cortical surface (Brainstorm, 15002 vertices), inflated 70%, ' ...
                       'coordinates in mm (x anterior, y left, z superior), HCP-MMP1.0 parcellation'];
surface.vertices = F70.Vertices * 1000;
surface.faces = F70.Faces;
surface.parcel = parcel;
surface.hemi = hemi;
surface.labels = labels;
save(fullfile(out, 'surface', 'fsaverage_15k_inflated70_hcpmmp1.mat'), 'surface', '-v7');
fprintf('  surface: %d vertices, %d faces, %d hemisphere-coded\n', size(surface.vertices, 1), size(surface.faces, 1), nnz(hemi));

%% Parcel labels
write_csv_exact(table((1:360)', labels, 'VariableNames', {'index', 'label'}), ...
    fullfile(out, 'atlas', 'hcp_mmp1_labels.csv'));
end

function R = extract_rows(X, labels, seeds)
% nSeeds x 360 x nSubjects: connectivity of each seed (row) with every parcel.
R = zeros(numel(seeds), size(X, 2), size(X, 3));
for s = 1:numel(seeds)
    i = parcel_index(labels, seeds{s});
    R(s, :, :) = X(i, :, :);
end
end

function C = extract_cols(X, labels, seeds)
% nSeeds x 360 x nSubjects: connectivity of every parcel (row) with each seed (column).
C = zeros(numel(seeds), size(X, 1), size(X, 3));
for s = 1:numel(seeds)
    i = parcel_index(labels, seeds{s});
    C(s, :, :) = reshape(X(:, i, :), 1, size(X, 1), size(X, 3));
end
end

function m = whole_brain_mean(X)
% Each subject's mean over the whole matrix: squeeze(mean(mean(X, 'omitnan'))).
% The fMRI diagonal is 0 and counts; the MEG diagonal is NaN and is left out.
m = squeeze(mean(mean(X, 'omitnan')));
m = m(:);
end

function used = used_parcels(labels, seeds, pdc, ROI)
% nSeeds x nParcels, true where the analyses use a seed's connectivity: the
% parcels of the seed's own hemisphere; for PDC only the 33 target regions.
isL = startsWith(labels(:)', 'L_');
target = true(1, numel(labels));
if pdc
    target(:) = false;
    target(parcel_index(labels, [hcp_label(ROI.names, 'L'); hcp_label(ROI.names, 'R')])) = true;
end
used = false(numel(seeds), numel(labels));
for s = 1:numel(seeds)
    used(s, :) = (isL == startsWith(seeds{s}, 'L_')) & target;
end
end

function R = keep_used(R, used)
% Set the entries that the analyses do not use to NaN (R: nSeeds x nParcels x nSubjects).
R(repmat(~used, 1, 1, size(R, 3))) = NaN;
end
