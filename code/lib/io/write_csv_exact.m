function write_csv_exact(T, file)
% WRITE_CSV_EXACT  Write a table to CSV with full double precision.
%
% Numbers are written with 17 significant digits, so reading the file back
% (MATLAB readtable, R read.csv) gives exactly the same doubles. NaN is
% written as NA. Text columns are written as they are, quoted when they
% contain a comma or a quote.
%
% Author: Orhan Soyuhos, 2026
% License: GPL-3.0 (see LICENSE)

folder = fileparts(file);
if ~isempty(folder) && ~exist(folder, 'dir'), mkdir(folder); end

names = T.Properties.VariableNames;
nr = height(T);
cells = cell(nr, numel(names));
for j = 1:numel(names)
    v = T.(names{j});
    if isnumeric(v) || islogical(v)
        v = double(v);
        s = arrayfun(@(x) sprintf('%.17g', x), v, 'UniformOutput', false);
        s(isnan(v)) = {'NA'};
    else
        s = cellstr(string(v));
        s(ismissing(string(v))) = {'NA'};
        needq = contains(s, ',') | contains(s, '"');
        s(needq) = strcat('"', strrep(s(needq), '"', '""'), '"');
    end
    cells(:, j) = s(:);
end

fid = fopen(file, 'w');
assert(fid > 0, 'Cannot write %s', file);
fprintf(fid, '%s\n', strjoin(names, ','));
for i = 1:nr
    fprintf(fid, '%s\n', strjoin(cells(i, :), ','));
end
fclose(fid);
end
