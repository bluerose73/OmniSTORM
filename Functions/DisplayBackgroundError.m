% Display the error message in background jobs.
% f is the future object
function DisplayBackgroundError(f)
    wait(f); % Wait for the Future object to complete
    if ~isempty(f.Error)
        disp(getReport(f.Error));
    end
end