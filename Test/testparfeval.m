f(1) = parfeval(backgroundPool, @foo, 2);
f(2) = parfeval(backgroundPool, @foo, 2);

% afterAll(f, @CheckResult, 0);

% f
% f(1)

arrayError = f.Error
error = f(1).Error