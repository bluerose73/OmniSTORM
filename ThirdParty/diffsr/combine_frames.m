function result = combine_frames(img_stack, window_size)
    [height, width, n_frames] = size(img_stack);
    n_steps = floor(n_frames / window_size);
    result = zeros([height, width, n_steps], class(img_stack));

    for i = 1:n_steps
        start_id = (i - 1) * window_size + 1;
        slice = img_stack(:, :, start_id : start_id + window_size - 1);
        result(:, :, i) = mean(slice, 3);
    end
end
