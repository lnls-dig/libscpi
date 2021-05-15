function r = freqresp_keysight(fid_instr, channel, excit_param)
%FREQRESP_KEYSIGHT   Frequency response experiment with Keysight
%   oscilloscope and arbitrary waveform generator
%
%   See EXAMPLE_FREQRESP_KEYSIGHT for more info.

% Parameters
param = scpiparam;

scpiset(fid_instr.osc, param, 'WAV:FORM', 'FLO');
if excit_param.navg > 1
    scpiset(fid_instr.osc, param, 'ACQ:AVER:COUN', excit_param.navg);
end
scpiset(fid_instr.gen, param, 'SOUR1:VOLT:UNIT', 'VPP')

r.name = {channel.name};
r.expdate = datestr(now);
r.derivative = [channel.derivative];
r.excit_param = excit_param;

% Pre-process parameter data
Fs = excit_param.npts*excit_param.df;

% Set parameters to instruments
scpiset(fid_instr.osc, param, 'ACQ:POIN', excit_param.npts);
scpiset(fid_instr.osc, param, 'ACQ:SRAT', Fs);
scpiset(fid_instr.osc, param, 'TIM:REF', 'LEFT');

pause(0.5);

npts = scpiget(fid_instr.osc, param, 'WAV:POIN', 'double');
param.nbytes2read = 4*npts + 20;
Fs = scpiget(fid_instr.osc, param, 'ACQ:SRAT', 'double');

scpiset(fid_instr.gen, param, 'SOUR1:VOLT:OFFS', excit_param.Voffset);

data = zeros(npts, length(channel));

if strcmpi(excit_param.type, 'PRBS')
    prbs_nbits_txt = sprintf('PN%d', excit_param.prbs_nbits);
    
    scpiset(fid_instr.gen, param, 'OUTP:SYNC', 'ON');
    scpiset(fid_instr.gen, param, 'SOUR1:VOLT', excit_param.Vpeak2peak);
    
    scpiset(fid_instr.gen, param, 'SOUR1:FUNC', 'PRBS');
    scpiset(fid_instr.gen, param, 'SOUR1:FUNC:PRBS:BRAT', excit_param.prbs_rate);
    scpiset(fid_instr.gen, param, 'SOUR1:FUNC:PRBS:DATA', prbs_nbits_txt);
    scpiset(fid_instr.gen, param, 'SOUR1:FUNC:PRBS:TRAN', excit_param.prbs_transition);
    
    pause(0.2);
    
    wait_averages(fid_instr.osc, excit_param);
    
    % Get data from scope
    for i=1:size(data,2)
        fprintf('Acquiring %s...\n', channel(i).name_instr);
        data(:,i) = getwave_keysight(fid_instr.osc, param, channel(i).name_instr, 'float');
    end
    
    r.data = data;
    r.Fs = Fs;
    
elseif strcmpi(excit_param.type, 'sin')
    scpiset(fid_instr.gen, param, 'SOUR1:FUNC', 'SIN');
    scpiset(fid_instr.gen, param, 'SOUR1:PHAS', 90);
    
    if isfield(excit_param, 'sin_gain')
        sin_gain = excit_param.sin_gain;
    else
        sin_gain = ones(1, length(excit_param.sin_freq));
    end
    
    Vpp = excit_param.Vpeak2peak*sin_gain;
    idx = round(excit_param.sin_freq/excit_param.df);
    freq_actual = idx*excit_param.df;
    
    fft_harmonics = zeros(excit_param.nharm, length(channel), length(excit_param.sin_freq));
    
    for i=1:length(freq_actual)
        scpiset(fid_instr.gen, param, 'SOUR1:FREQ', freq_actual(i));
        scpiset(fid_instr.gen, param, 'SOUR1:VOLT', Vpp(i));
        scpiset(fid_instr.gen, param, 'OUTP:SYNC', 'ON');
        
        pause(0.2);
        
        fprintf('-- Frequency %f Hz ---\n', freq_actual(i));
        fprintf('-- Vpp %f V ---\n', Vpp(i));
        wait_averages(fid_instr.osc, excit_param);
        
        scpiset(fid_instr.gen, param, 'OUTP:SYNC', 'OFF');
        
        scpiset(fid_instr.osc, param, 'STOP', '');
        scpiget(fid_instr.osc, param, 'ADER');
        scpiset(fid_instr.osc, param, 'SING', '');
        
        fprintf('Acquiring...');
        
        while scpiget(fid_instr.osc, param, 'AER', 'double') == 0
            fprintf('.')
            pause(0.2);
        end
        
        while scpiget(fid_instr.osc, param, 'ADER', 'double') == 0
            fprintf('.')
            pause(0.2);
        end
        fprintf('\n');
        
        % Get data from scope
        for j=1:length(channel)
            fprintf('Retrieving %s data...\n', channel(j).name_instr);
            data(:,j) = getwave_keysight(fid_instr.osc, param, channel(j).name_instr, 'float');
        end
        
        Y = fft(data);
        fft_harmonics(:, :, i) = Y(idx(i)*(1:size(fft_harmonics,1))+1, :);
        fprintf('\n')
    end
    
    r.fft_harmonics = fft_harmonics;
    r.freq = freq_actual;
end


function wait_averages(fid_osc, excit_param)

param = scpiparam;

if excit_param.navg > 1
    scpiset(fid_osc, param, 'ACQ:AVER', 'OFF');
    pause(0.2);
    scpiset(fid_osc, param, 'ACQ:AVER', 'ON');
    
    % Wait for averages
    fprintf('Waiting scope to perform %d averages...', excit_param.navg);
    pause(0.5);
    
    cnt = 0;
    j = 40;
    while cnt < excit_param.navg
        pause(0.5);
        cnt = scpiget(fid_osc, param, 'WAV:COUNT', 'double');
        fprintf('.');
        if mod(j,50) == 0
            fprintf(' (%d averages)\n', cnt);
        end
        j = j+1;
    end
    fprintf('DONE!\n');
else
    scpiset(fid_osc, param, 'ACQ:AVER', 'OFF');
end
