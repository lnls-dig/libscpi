function scpiset(fid, param, cmd, val)
%SCPISET   Set parameter value to instrument using SCPI protocol
%
%   wvf = scpiset(fid, param, cmd, type)
%
%   Inputs:
%       fid:    Connection identifier - must be open with VXI11 function
%       param:  Reserved for future use
%       cmd:    SCPI command string
%       val:    Value to be set - may be a string or numeric value
%
%   Outputs:
%       n:      Number of bytes written
%
%   See also VXI11, SCPIPARAM, SCPIGET.

if isnumeric(val)
    val_txt = sprintf(' %g', val);
elseif ischar(val)
    val_txt = [' ' val];
else
    error('Invalid data type');
end

n = vxi11_write(fid, [cmd val_txt]);
