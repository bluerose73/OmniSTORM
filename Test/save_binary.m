function save_binary(mat, filename, precision)
    fileID = fopen(filename, 'wb');
    fwrite(fileID, mat, precision);
    fclose(fileID);
end