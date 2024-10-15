% Compute Pairwise frame difference

function result = pairwise_frame_difference(image_stack)
    [height, width, n_frames] = size(image_stack);
    result = zeros([height, width, n_frames * (n_frames - 1)]);
    idx = 1;
    for i = 1:n_frames
        for j = 1:n_frames
            if i == j
                continue;
            end
            result(:, :, idx) = max(image_stack(:, :, i) - image_stack(:, :, j), 0);
            idx = idx + 1;
        end
    end
end