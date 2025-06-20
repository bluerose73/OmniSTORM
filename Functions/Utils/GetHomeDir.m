function omniStormDir = GetHomeDir()
%GETHOMEDIR Returns the path to HOME/.omnistorm directory
%   Creates the directory if it doesn't exist
%   Returns a string path to the .omnistorm directory in the user's home folder
%   Cross-platform compatible (Windows, macOS, Linux)

    % Get the user's home directory in a cross-platform way
    if ispc
        % Windows: use USERPROFILE environment variable
        homeDir = getenv('USERPROFILE');
        if isempty(homeDir)
            % Fallback to HOMEDRIVE + HOMEPATH
            homeDir = [getenv('HOMEDRIVE') getenv('HOMEPATH')];
        end
    else
        % Unix-like systems (macOS, Linux): use HOME environment variable
        homeDir = getenv('HOME');
    end
    
    % If we still don't have a home directory, use current directory as fallback
    if isempty(homeDir)
        homeDir = pwd();
        warning('Could not determine home directory, using current directory: %s', homeDir);
    end
    
    % Create the .omnistorm directory path
    omniStormDir = fullfile(homeDir, '.omnistorm');
    
    % Create the directory if it doesn't exist
    if ~exist(omniStormDir, 'dir')
        try
            mkdir(omniStormDir);
            fprintf('Created OmniSTORM directory: %s\n', omniStormDir);
        catch ME
            error('Failed to create OmniSTORM directory %s: %s', omniStormDir, ME.message);
        end
    end
    
end

