function t = gettime_keysight(fid, param)
  
vxi11_write(fid, ':WAV:XINC?');
xinc = str2double(char(vxi11_read(fid, param.nbytes2read)));
 
vxi11_write(fid, ':WAV:XOR?');
xor = str2double(char(vxi11_read(fid, param.nbytes2read)));
 
vxi11_write(fid, ':WAV:XREF?');
xref = str2double(char(vxi11_read(fid, param.nbytes2read)));

vxi11_write(fid, ':ACQ:POIN?');
npts = str2double(char(vxi11_read(fid, param.nbytes2read)));

vxi11_write(fid, ':MARK:PROP?');
prop = str2double(char(vxi11_read(fid, param.nbytes2read)));

t = (xinc*((0:npts-1)'-xref) + xor);
