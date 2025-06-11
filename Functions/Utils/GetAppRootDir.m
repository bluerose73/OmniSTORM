function userDir = GetAppRootDir()
%GETAPPROOTDIR Get the root dir for saving app-related data
    userDir = fullfile(getenv('USERPROFILE'), 'Documents', 'OmniSTORMData');
end

