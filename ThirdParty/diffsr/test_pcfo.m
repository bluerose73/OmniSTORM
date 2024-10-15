clear

gain_list = [0.125 0.25 0.5 1 2 4 8];
offset_list = [0 500 1000 1500 2000];
n_repeat = 10;

% gain_list = [0.125 0.25];
% offset_list = [500];

gain_est_list = zeros(numel(gain_list), numel(offset_list), n_repeat);
offset_est_list = zeros(numel(gain_list), numel(offset_list), n_repeat);

total = numel(gain_est_list);

cnt = 0;
for i = 1:numel(gain_list)
    for j = 1:numel(offset_list)
        for k = 1:n_repeat
            cnt = cnt + 1;
            disp(cnt + " of " + total);

            im = poisson_sim();
            gain = gain_list(i);
            offset = offset_list(j);
            imdetect = im*gain + offset;
            [gain_est, offset_est] = pcfo(imdetect);
            recovered_image = (imdetect - offset_est) / gain_est;
    
            gain_est_list(i, j, k) = gain_est;
            offset_est_list(i, j, k) = offset_est;
        end
    end
end

gain_mat(:, 1, 1) = gain_list;
gain_err_list = gain_est_list - gain_mat;
offset_mat(1, :, 1) = offset_list;
offset_err_list = offset_est_list - offset_mat;

gain_rmsd = sqrt(mean(gain_err_list .^ 2, 3));
offset_rmsd = sqrt(mean(offset_err_list .^ 2, 3));

writematrix(gain_rmsd,"gain_rmsd.csv");
writematrix(offset_rmsd, "offset_rmsd.csv");