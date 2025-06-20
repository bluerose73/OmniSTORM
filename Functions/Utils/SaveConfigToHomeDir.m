function SaveConfigToHomeDir(config)
%SAVECONFIGTOHOMEDIR Save the config struct to ~/.omnistorm/config.json

home_dir = GetHomeDir();
path = fullfile(home_dir, 'config.json');
writestruct(config, path, PrettyPrint=true);

end

