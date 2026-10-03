function N = define_networks(RL, RR, seed1, seed2)
% DEFINE_NETWORKS  Seed networks from the whole-hemisphere seed contrast.
%
%   N = define_networks(RL, RR, 'FFC', 'PHA3')
%
% RL and RR are the seed1-vs-seed2 contrasts over the 180 parcels of the
% left and right hemisphere (seed_test, mode 'contrast'). A parcel instance
% (region x hemisphere) belongs to the seed1 network when it is
% significantly more connected with seed1 (z > 0), and to the seed2 network
% when z < 0 (Table 1). Each network also contains its two seed parcels.
%
% N.targets1, N.targets2   significant instances, without the seeds
% N.net1, N.net2           networks used for CPM (seeds + targets), in the
%                          order of network_order
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

labels = [RL.labels; RR.labels];
stat   = [RL.stat;   RR.stat];
names  = bare_name(labels);
is_seed = strcmp(names, seed1) | strcmp(names, seed2);

N.seed1 = seed1;
N.seed2 = seed2;
N.targets1 = network_order(labels(stat > 0 & ~is_seed));
N.targets2 = network_order(labels(stat < 0 & ~is_seed));
N.net1 = network_order([{hcp_label(seed1, 'L'); hcp_label(seed1, 'R')}; N.targets1]);
N.net2 = network_order([{hcp_label(seed2, 'L'); hcp_label(seed2, 'R')}; N.targets2]);
end
