function data = getwave_keysight(fid, param, source, type)

if nargin < 4 || isempty(type)
    type = 'txt';
end

% Select trace
vxi11_write(fid, sprintf(':WAV:SOUR %s', source));
pause(param.sleep_write);

% Ask for trace data
vxi11_write(fid, ':WAV:DATA?');
pause(param.sleep_query);

if strcmpi(type, 'txt')
    data = textscan(char(vxi11_read(fid, param.nbytes2read)), '%f,');
    data = data{1};
elseif strcmpi(type, 'float')
    data = uint32(vxi11_read(fid, param.nbytes2read));
    npts_sizechar = str2double(char(data(2)));
    npts = str2double(char(data(3:2 + npts_sizechar)));
    idx_start = npts_sizechar + 3;
    idx_end = npts_sizechar + npts + 2;
    data = data(idx_start:4:idx_end) + bitshift(data(idx_start+1:4:idx_end), 8) + bitshift(data(idx_start+2:4:idx_end), 16) + bitshift(data(idx_start+3:4:idx_end), 24);
    data = typecast(data, 'single')';
end
