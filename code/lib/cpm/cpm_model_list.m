function list = cpm_model_list()
% CPM_MODEL_LIST  The 12 CPM analyses of the paper.
%
% Columns: model id, behavioural score, network (see a02_fmri_contrast),
% where it is reported, and a description.
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

face = 'Emotion_Task_Face_Median_RT';
zero = 'WM_Task_0bk_Place_Median_RT';
two  = 'WM_Task_2bk_Place_Median_RT';

list = {
    'face_FFA37', face, 'FFA',               'Figure 5A', 'Face-matching RT from the FFA network'
    'face_PPA23', face, 'PPA',               'Figure 5B', 'Face-matching RT from the PPA network (control)'
    '0bk_PPA23',  zero, 'PPA',               'Figure 6A', '0-back scene RT from the PPA network'
    '2bk_PPA23',  two,  'PPA',               'Figure 6C', '2-back scene RT from the PPA network'
    '0bk_FFA37',  zero, 'FFA',               'Figure 6E', '0-back scene RT from the FFA network (control)'
    '2bk_FFA37',  two,  'FFA',               'Figure 6F', '2-back scene RT from the FFA network (control)'
    'face_FFA35', face, 'FFA_without_seeds', 'Figure S5A', 'Face-matching RT, FFA network without the FFA seeds'
    '0bk_PPA21',  zero, 'PPA_without_seeds', 'Figure S5B', '0-back scene RT, PPA network without the PPA seeds'
    '2bk_PPA21',  two,  'PPA_without_seeds', 'Figure S5C', '2-back scene RT, PPA network without the PPA seeds'
    'face_FFA44', face, 'FFA_PHA2_contrast', 'Section 2.5', 'Face-matching RT, FFA network of the FFC vs PHA2 contrast'
    '0bk_aPPA18', zero, 'anterior_PPA',      'Section 2.5', '0-back scene RT, anterior PPA (PHA2) network'
    '2bk_aPPA18', two,  'anterior_PPA',      'Section 2.5', '2-back scene RT, anterior PPA (PHA2) network'
    };
end
