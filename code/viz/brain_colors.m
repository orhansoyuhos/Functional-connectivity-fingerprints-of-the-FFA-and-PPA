function [vdata, cmap, clim_] = brain_colors(S, values, style, cmax)
% BRAIN_COLORS  Per-vertex colour data for a parcel map (brain figures).
%
%   [vdata, cmap, clim_] = brain_colors(S, values, style, cmax)
%
% S       load_surface(cfg)
% values  360 x 1 signed z per parcel (0 = not significant)
% style   'seedmap'  hot colours for z > 0 (Figures 1C/D, S1A/B, S2A/B)
%         'contrast' red (> 0) / blue (< 0) (Figures 2A, S1C, S2C)
% cmax    upper end of the colour scale (8 for fMRI, 6 for MEG)
%
% The vertex values are interpolated across the triangles and then mapped
% through the colour map, which gives the significant regions darker
% outlines. Non-significant parcels are drawn white, the medial wall black
% (seed maps) or grey (contrasts).
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

values = values(:);
vdata = zeros(size(S.parcel));
in = S.parcel > 0;
switch style
    case 'seedmap'
        v = values;
        v(v <= 0) = -0.02 * cmax;          % not significant -> white
        vdata(in) = v(S.parcel(in));        % medial wall stays 0 -> black
        h = hot(256);
        cmap = [1 1 1; h(1:end-10, :)];
        clim_ = [-0.1, cmax];
    case 'contrast'
        v = values;
        v(v == 0) = 0.02 * cmax;            % not significant -> white
        vdata(in) = v(S.parcel(in));        % medial wall stays 0 -> grey
        rbw = cmap_rbw(128);
        cmap = [rbw(1:128, :); 0.827 0.827 0.827; rbw(129:256, :)];
        clim_ = [-cmax, cmax];
    otherwise
        error('style must be ''seedmap'' or ''contrast''.');
end
end
