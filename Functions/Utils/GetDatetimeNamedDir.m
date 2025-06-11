function dateTimeDir = GetDatetimeNamedDir(root_dir, base_dir_name)
%GETDATETIMENAMEDDIR Get a directory string named like
%                    root_dir/OmniSTORM-base_dir_name-datetime/,
%                    or root_dir/OmniSTORM-datetime in case base_dir_name
%                    is emtpy.
%   dateTimeDir = GetDatetimeNamedDir(root_dir)
%   dateTimeDir = GetDatetimeNamedDir(root_dir, base_dir_name)

    % default for base_dir_name
    if nargin < 2
        base_dir_name = '';
    end

    % timestamp
    timeStr = datestr(datetime('now'), 'yyyy-mm-ddTHH-MM-SS');

    % build folder name
    if isempty(base_dir_name)
        dirName = sprintf('OmniSTORM-%s', timeStr);
    else
        dirName = sprintf('OmniSTORM-%s-%s', base_dir_name, timeStr);
    end

    % full path
    dateTimeDir = fullfile(root_dir, dirName);
end