function val = scpiget(fid, param, cmd, type)
%SCPIGET   Get parameter value from instrument using SCPI protocol
%
%   wvf = scpiget(fid, param, cmd, type)
%
%   Inputs:
%       fid:    Connection identifier - must be open with VXI11 function
%       param:  Connection parameters - default parameters can be set with SCPIPARAM
%       cmd:    SCPI command string
%       type:   Variable type to convert return value (optional / default = 'char')
%
%   Outputs:
%       val:    Return value on specified Type.
%
%   See also VXI11, SCPIPARAM, SCPISET.
if nargin < 4
    type = 'char';
end

%if ~contains(cmd, '?')
if ~size(strfind(cmd, '?'),1)
    cmd = [cmd '?'];
end

vxi11_write(fid, cmd);
val_txt = char(vxi11_read(fid, param.nbytes2read));

switch type
    case 'double'
        val = str2double(val_txt);
    otherwise
        val = val_txt;
end
