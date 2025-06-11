function [oddFrames, evenFrames] = SplitLocalizationsForFRC(localizations)
    % Function to split a struct into odd and even frames based on the field 'F'
    %
    % Inputs:
    %   - localizations: A struct with fields X, Y, F, intensity
    % Outputs:
    %   - oddFrames: A struct containing localizations with odd frame numbers
    %   - evenFrames: A struct containing localizations with even frame numbers
    
    % Validate that the input struct has the required fields
    requiredFields = {'X', 'Y', 'F', 'intensity'};
    for i = 1:length(requiredFields)
        if ~isfield(localizations, requiredFields{i})
            error('The input struct must contain the field "%s".', requiredFields{i});
        end
    end
    
    % Find the indices for odd and even frames
    oddIndices = mod(localizations.F, 2) == 1; % Logical array for odd frames
    evenIndices = mod(localizations.F, 2) == 0; % Logical array for even frames
    
    % Split the struct into odd and even frames
    oddFrames = struct( ...
        'X', localizations.X(oddIndices), ...
        'Y', localizations.Y(oddIndices), ...
        'F', localizations.F(oddIndices), ...
        'intensity', localizations.intensity(oddIndices) ...
    );
    
    evenFrames = struct( ...
        'X', localizations.X(evenIndices), ...
        'Y', localizations.Y(evenIndices), ...
        'F', localizations.F(evenIndices), ...
        'intensity', localizations.intensity(evenIndices) ...
    );
end