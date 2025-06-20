function config = LoadConfigFromHomeDir()
%LOADCONFIGFROMHOMEDIR Load the config struct from ~/.omnistorm/config.json
%   If the file does not exist, returns an empty array [].

home_dir = GetHomeDir();
path = fullfile(home_dir, 'config.json');
if exist(path, 'file')
    try
        config = readstruct(path);
    catch ME
        error('Failed to load config from %s: %s', path, ME.message);
    end
else
    fprintf('Config file not found at %s. Returning empty config.\n', path);
    config = [];

end

