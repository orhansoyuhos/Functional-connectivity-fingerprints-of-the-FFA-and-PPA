%% Step 2 (fMRI): parcel time series and connectivity matrices
%
% For each subject, this script
%   1. averages the concatenated, normalised dense time series of Step 1
%      within each of the 360 HCP-MMP1 parcels (wb_command -cifti-parcellate,
%      method MEAN);
%   2. computes the 360 x 360 ridge-regularised partial correlation matrix
%      with FSLNets nets_netmats ('ridgep', rho = 0.01);
%   3. saves the matrix (r values) in the subject's folder.
% It then takes tanh of the matrices, puts the parcels in the order of
% data/atlas/hcp_mmp1_labels.csv (the order of the MEG matrices) and saves
% the group file in groupDir:
%   Outputs_<N>subjs_partialcorr_rfMRI_MEAN.mat
% It holds a struct group_results: data_perSubject (360 x 360 x N), data
% (mean over subjects), label and band. preprocessing/make_data.m reads the
% group files of the 55- and 371-subject cohorts.
%
% Requirements: Connectome Workbench (wb_command), cifti-matlab (cifti_read)
% and FSLNets v0.6.2 (nets_netmats). Edit the settings below, then run the
% script. The subject list is not part of this repository (see
% preprocessing/README.md); the order of its IDs is the order of the
% subjects in the outputs.
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

clear
close all

%% Settings (edit)
methodType = 'MEAN';   % parcel time series = mean over the parcel's grayordinates

toolboxDir   = 'C:/path/to/Toolboxes';
ciftiDir     = fullfile(toolboxDir, 'cifti-matlab-master');
fslnetsDir   = fullfile(toolboxDir, 'FSL-scripts-master', 'rsc', 'scripts', 'bin', 'FSLNets');
workbenchDir = fullfile(toolboxDir, 'workbench', 'bin_windows64');
subjectsDir  = 'C:/path/to/HCP_data/HCP_subjects';               % main_dir of Step 1
subjectList  = fullfile(subjectsDir, 'subject_list_file.txt');   % HCP subject IDs
groupDir     = fileparts(subjectsDir);                            % where the group files go

% Parcellation (HCP-MMP1.0, 32k_fs_LR) and the parcel order of the outputs
here      = fileparts(mfilename('fullpath'));
root      = fileparts(fileparts(here));
parcelDir = fullfile(here, 'parcellation', ...
    'Q1-Q6_RelatedValidation210.CorticalAreas_dil_Final_Final_Areas_Group_Colors.32k_fs_LR.dlabel.nii');
labelFile = fullfile(root, 'data', 'atlas', 'hcp_mmp1_labels.csv');

%% Paths: wb_command on the system PATH, cifti-matlab and FSLNets on the MATLAB path
wbDir = fullfile(workbenchDir);   % fullfile gives the system's file separators
if ~contains(getenv('PATH'), wbDir)
    setenv('PATH', [wbDir pathsep getenv('PATH')]);
end
addpath(ciftiDir)
addpath(fslnetsDir)

%% Loop over subjects
subjectIDs = split(strtrim(string(fileread(subjectList))));
warningIndices = [];   % subjects for which MATLAB gave a warning
for ii = 1:length(subjectIDs)

    % Reset the last warning
    lastwarn('');

    subj = subjectIDs(ii);
    disp(subj)

    fileName = ['rfMRI_concenatedFourRuns_' char(subj) '.dtseries.nii'];
    inputDir = fullfile(subjectsDir, char(subj), 'MNINonLinear', 'Results', fileName);

    outputName = ['rfMRI_concenatedFourRuns_' char(subj) '_MMP_' methodType '.ptseries.nii'];
    outputDir = fullfile(subjectsDir, char(subj), 'MNINonLinear', 'Results', outputName);

    command = ['wb_command -cifti-parcellate "' inputDir '" "' parcelDir '" COLUMN "' outputDir '" -method ' methodType];
    [status, cmdout] = system(command);
    if status ~= 0
        disp(cmdout)
        return
    end

    V = cifti_read(outputDir);
    ts = V.cdata';   % time x 360 parcels, in the order of the label keys (fMRI_label below)

    netmat2 = nets_netmats(ts, 0, 'ridgep', 0.01);  % ridge-regularised partial correlation

    % Check if there was a warning
    [warnMsg, ~] = lastwarn;
    if ~isempty(warnMsg)
        warningIndices = [warningIndices, subj];
    end

    rfMRI_connResults = struct;
    rfMRI_connResults.partialcorr = netmat2;

    filenameDir = fullfile(subjectsDir, char(subj), 'MNINonLinear', 'Results', ['rfMRI_partialCorrelation_' char(subj) '_MMP' lower(methodType) '.mat']);
    save(filenameDir, 'rfMRI_connResults')

    partialcorr_perSubject(:, :, ii) = tanh(netmat2);   % tanh of r

end

%% Parcel order of the parcellated files: the label keys of the dlabel file
% (keys 1-180 right hemisphere, 181-360 left; wb_command sorts the parcels by
% key; https://balsa.wustl.edu/file/show/3VLx)
tmp_label = "R_V1_ROI, R_MST_ROI, R_V6_ROI, R_V2_ROI, R_V3_ROI, R_V4_ROI, R_V8_ROI, R_4_ROI, R_3b_ROI, R_FEF_ROI, R_PEF_ROI, R_55b_ROI, R_V3A_ROI, R_RSC_ROI, R_POS2_ROI, R_V7_ROI, R_IPS1_ROI, R_FFC_ROI, R_V3B_ROI, R_LO1_ROI, R_LO2_ROI, R_PIT_ROI, R_MT_ROI, R_A1_ROI, R_PSL_ROI, R_SFL_ROI, R_PCV_ROI, R_STV_ROI, R_7Pm_ROI, R_7m_ROI, R_POS1_ROI, R_23d_ROI, R_v23ab_ROI, R_d23ab_ROI, R_31pv_ROI, R_5m_ROI, R_5mv_ROI, R_23c_ROI, R_5L_ROI, R_24dd_ROI, R_24dv_ROI, R_7AL_ROI, R_SCEF_ROI, R_6ma_ROI, R_7Am_ROI, R_7PL_ROI, R_7PC_ROI, R_LIPv_ROI, R_VIP_ROI, R_MIP_ROI, R_1_ROI, R_2_ROI, R_3a_ROI, R_6d_ROI, R_6mp_ROI, R_6v_ROI, R_p24pr_ROI, R_33pr_ROI, R_a24pr_ROI, R_p32pr_ROI, R_a24_ROI, R_d32_ROI, R_8BM_ROI, R_p32_ROI, R_10r_ROI, R_47m_ROI, R_8Av_ROI, R_8Ad_ROI, R_9m_ROI, R_8BL_ROI, R_9p_ROI, R_10d_ROI, R_8C_ROI, R_44_ROI, R_45_ROI, R_47l_ROI, R_a47r_ROI, R_6r_ROI, R_IFJa_ROI, R_IFJp_ROI, R_IFSp_ROI, R_IFSa_ROI, R_p9-46v_ROI, R_46_ROI, R_a9-46v_ROI, R_9-46d_ROI, R_9a_ROI, R_10v_ROI, R_a10p_ROI, R_10pp_ROI, R_11l_ROI, R_13l_ROI, R_OFC_ROI, R_47s_ROI, R_LIPd_ROI, R_6a_ROI, R_i6-8_ROI, R_s6-8_ROI, R_43_ROI, R_OP4_ROI, R_OP1_ROI, R_OP2-3_ROI, R_52_ROI, R_RI_ROI, R_PFcm_ROI, R_PoI2_ROI, R_TA2_ROI, R_FOP4_ROI, R_MI_ROI, R_Pir_ROI, R_AVI_ROI, R_AAIC_ROI, R_FOP1_ROI, R_FOP3_ROI, R_FOP2_ROI, R_PFt_ROI, R_AIP_ROI, R_EC_ROI, R_PreS_ROI, R_H_ROI, R_ProS_ROI, R_PeEc_ROI, R_STGa_ROI, R_PBelt_ROI, R_A5_ROI, R_PHA1_ROI, R_PHA3_ROI, R_STSda_ROI, R_STSdp_ROI, R_STSvp_ROI, R_TGd_ROI, R_TE1a_ROI, R_TE1p_ROI, R_TE2a_ROI, R_TF_ROI, R_TE2p_ROI, R_PHT_ROI, R_PH_ROI, R_TPOJ1_ROI, R_TPOJ2_ROI, R_TPOJ3_ROI, R_DVT_ROI, R_PGp_ROI, R_IP2_ROI, R_IP1_ROI, R_IP0_ROI, R_PFop_ROI, R_PF_ROI, R_PFm_ROI, R_PGi_ROI, R_PGs_ROI, R_V6A_ROI, R_VMV1_ROI, R_VMV3_ROI, R_PHA2_ROI, R_V4t_ROI, R_FST_ROI, R_V3CD_ROI, R_LO3_ROI, R_VMV2_ROI, R_31pd_ROI, R_31a_ROI, R_VVC_ROI, R_25_ROI, R_s32_ROI, R_pOFC_ROI, R_PoI1_ROI, R_Ig_ROI, R_FOP5_ROI, R_p10p_ROI, R_p47r_ROI, R_TGv_ROI, R_MBelt_ROI, R_LBelt_ROI, R_A4_ROI, R_STSva_ROI, R_TE1m_ROI, R_PI_ROI, R_a32pr_ROI, R_p24_ROI, L_V1_ROI, L_MST_ROI, L_V6_ROI, L_V2_ROI, L_V3_ROI, L_V4_ROI, L_V8_ROI, L_4_ROI, L_3b_ROI, L_FEF_ROI, L_PEF_ROI, L_55b_ROI, L_V3A_ROI, L_RSC_ROI, L_POS2_ROI, L_V7_ROI, L_IPS1_ROI, L_FFC_ROI, L_V3B_ROI, L_LO1_ROI, L_LO2_ROI, L_PIT_ROI, L_MT_ROI, L_A1_ROI, L_PSL_ROI, L_SFL_ROI, L_PCV_ROI, L_STV_ROI, L_7Pm_ROI, L_7m_ROI, L_POS1_ROI, L_23d_ROI, L_v23ab_ROI, L_d23ab_ROI, L_31pv_ROI, L_5m_ROI, L_5mv_ROI, L_23c_ROI, L_5L_ROI, L_24dd_ROI, L_24dv_ROI, L_7AL_ROI, L_SCEF_ROI, L_6ma_ROI, L_7Am_ROI, L_7PL_ROI, L_7PC_ROI, L_LIPv_ROI, L_VIP_ROI, L_MIP_ROI, L_1_ROI, L_2_ROI, L_3a_ROI, L_6d_ROI, L_6mp_ROI, L_6v_ROI, L_p24pr_ROI, L_33pr_ROI, L_a24pr_ROI, L_p32pr_ROI, L_a24_ROI, L_d32_ROI, L_8BM_ROI, L_p32_ROI, L_10r_ROI, L_47m_ROI, L_8Av_ROI, L_8Ad_ROI, L_9m_ROI, L_8BL_ROI, L_9p_ROI, L_10d_ROI, L_8C_ROI, L_44_ROI, L_45_ROI, L_47l_ROI, L_a47r_ROI, L_6r_ROI, L_IFJa_ROI, L_IFJp_ROI, L_IFSp_ROI, L_IFSa_ROI, L_p9-46v_ROI, L_46_ROI, L_a9-46v_ROI, L_9-46d_ROI, L_9a_ROI, L_10v_ROI, L_a10p_ROI, L_10pp_ROI, L_11l_ROI, L_13l_ROI, L_OFC_ROI, L_47s_ROI, L_LIPd_ROI, L_6a_ROI, L_i6-8_ROI, L_s6-8_ROI, L_43_ROI, L_OP4_ROI, L_OP1_ROI, L_OP2-3_ROI, L_52_ROI, L_RI_ROI, L_PFcm_ROI, L_PoI2_ROI, L_TA2_ROI, L_FOP4_ROI, L_MI_ROI, L_Pir_ROI, L_AVI_ROI, L_AAIC_ROI, L_FOP1_ROI, L_FOP3_ROI, L_FOP2_ROI, L_PFt_ROI, L_AIP_ROI, L_EC_ROI, L_PreS_ROI, L_H_ROI, L_ProS_ROI, L_PeEc_ROI, L_STGa_ROI, L_PBelt_ROI, L_A5_ROI, L_PHA1_ROI, L_PHA3_ROI, L_STSda_ROI, L_STSdp_ROI, L_STSvp_ROI, L_TGd_ROI, L_TE1a_ROI, L_TE1p_ROI, L_TE2a_ROI, L_TF_ROI, L_TE2p_ROI, L_PHT_ROI, L_PH_ROI, L_TPOJ1_ROI, L_TPOJ2_ROI, L_TPOJ3_ROI, L_DVT_ROI, L_PGp_ROI, L_IP2_ROI, L_IP1_ROI, L_IP0_ROI, L_PFop_ROI, L_PF_ROI, L_PFm_ROI, L_PGi_ROI, L_PGs_ROI, L_V6A_ROI, L_VMV1_ROI, L_VMV3_ROI, L_PHA2_ROI, L_V4t_ROI, L_FST_ROI, L_V3CD_ROI, L_LO3_ROI, L_VMV2_ROI, L_31pd_ROI, L_31a_ROI, L_VVC_ROI, L_25_ROI, L_s32_ROI, L_pOFC_ROI, L_PoI1_ROI, L_Ig_ROI, L_FOP5_ROI, L_p10p_ROI, L_p47r_ROI, L_TGv_ROI, L_MBelt_ROI, L_LBelt_ROI, L_A4_ROI, L_STSva_ROI, L_TE1m_ROI, L_PI_ROI, L_a32pr_ROI, L_p24_ROI";
fMRI_label = split(tmp_label, ', ');

for ii=1:360
    tmp_name = fMRI_label{ii};
    H = tmp_name(1);
    fMRI_label{ii} = [tmp_name ' ' H];
end

%% Reorder the parcels as in the MEG matrices (data/atlas/hcp_mmp1_labels.csv)
L = readtable(labelFile, 'TextType', 'char', 'Delimiter', ',');
MEG_label = L.label;

partialcorr_perSubject_ordered = reorder_labels(partialcorr_perSubject, MEG_label, fMRI_label, subjectIDs);

%% Group file
group_results = struct;
group_results.band = 'partialcorr_rfMRI';
group_partialcorr = mean(partialcorr_perSubject_ordered, 3);
group_results.data = group_partialcorr;
group_results.data_perSubject = partialcorr_perSubject_ordered;
group_results.label = MEG_label;
group_results.subjectids = 'Restricted';

filename = fullfile(groupDir, ['Outputs_' char(string(length(subjectIDs))) 'subjs_partialcorr_rfMRI_' methodType '.mat']);
save(filename, 'group_results')


function reordered_perSubject = reorder_labels(fMRI_data_perSubject, MEG_label, fMRI_label, subjectIDs)
nSub = length(subjectIDs);
reordered_perSubject = zeros(360,360);
for subj = 1:nSub
    for ii = 1:360
        idx1_parcel = find(strcmp(fMRI_label, MEG_label{ii}));
        for kk = 1:360
            idx2_parcel = find(strcmp(fMRI_label, MEG_label{kk}));
            reordered_perSubject(ii, kk, subj) = fMRI_data_perSubject(idx1_parcel, idx2_parcel, subj);
        end
    end
end
end
