function out = network_order(labels)
% NETWORK_ORDER  Order of the parcels in a CPM network.
%
% Right-hemisphere parcels first, then left-hemisphere parcels, each in
% character (ASCII) order of the label. The order does not change which
% edges are selected, but it fixes the order of the floating-point sums of
% the CPM.
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

labels = labels(:);
isR = startsWith(labels, 'R_');
out = [sort(labels(isR)); sort(labels(~isR))];
end
