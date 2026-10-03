%% A03  Whole-brain MEG connectivity of the FFA and PPA (Figures S1 and S2)
%
% Same tests as for fMRI (A01, A02), for each MEG frequency band:
%   seed maps  each seed vs the subject's whole-brain mean connectivity
%              (one-sided, FDR over the 180 ipsilateral parcels)
%   contrast   FFA vs PPA (two-sided, FDR over the 180 parcels)
% for amplitude coupling (oPEC, Figure S1) and phase coupling (iCOH,
% Figure S2). The seeds are among the 180 tested parcels, with their
% self-connection set to 1.
%
% Output
%   results/analysis/meg_wholebrain.mat
%   results/tables/meg_wholebrain_all_parcels.csv
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

cfg = config();
hemis = {'L', 'R'};
metrics = {'opec', 'icoh'};

wb = struct();
long = table();
for m = 1:numel(metrics)
    D = load_connectivity(cfg, metrics{m});
    for b = 1:numel(D.bands)
        for h = 1:2
            targets = D.labels((1:180) + 180 * (h - 1));
            sF = hcp_label(cfg.seed_ffa, hemis{h});
            sP = hcp_label(cfg.seed_ppa, hemis{h});
            R = struct();
            R.FFC = seed_test(D, 'mean', sF, targets, b, cfg);
            R.PHA3 = seed_test(D, 'mean', sP, targets, b, cfg);
            R.contrast = seed_test(D, 'contrast', {sF, sP}, targets, b, cfg);
            wb.(metrics{m}).(D.bands{b}).(hemis{h}) = R;
            for a = {'FFC', 'PHA3', 'contrast'}
                long = [long; results_long(R.(a{1}), struct('metric', metrics{m}, 'band', D.bands{b}, ...
                    'analysis', a{1}))]; %#ok<AGROW>
            end
        end
        n = @(x) sum(wb.(metrics{m}).(D.bands{b}).L.(x).sig) + sum(wb.(metrics{m}).(D.bands{b}).R.(x).sig);
        fprintf('%s %-5s  significant parcels (both hemispheres, seeds included): FFC %3d, PHA3 %3d, contrast %3d\n', ...
            metrics{m}, D.bands{b}, n('FFC'), n('PHA3'), n('contrast'));
    end
end

if ~exist(fullfile(cfg.results_dir, 'analysis'), 'dir'), mkdir(fullfile(cfg.results_dir, 'analysis')); end
save(fullfile(cfg.results_dir, 'analysis', 'meg_wholebrain.mat'), 'wb');
write_csv_exact(long, fullfile(cfg.tables_dir, 'meg_wholebrain_all_parcels.csv'));
