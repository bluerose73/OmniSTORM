function M = poisson_matrix(m, n, a, b)
    % Create a matrix where each element follows a Poisson distribution
    % The mean for each row spans evenly from a (first row) to b (last row)
    %
    % Inputs:
    %   m - number of rows
    %   n - number of columns
    %   a - mean of Poisson distribution for the first row
    %   b - mean of Poisson distribution for the last row
    %
    % Output:
    %   M - m x n matrix with Poisson-distributed elements

    % Linearly spaced means for each row
    lambda_values = linspace(a, b, m); 
    
    % Preallocate matrix
    M = zeros(m, n);
    
    % Generate Poisson-distributed values for each row
    for i = 1:m
        M(i, :) = poissrnd(lambda_values(i), 1, n);
    end
end
