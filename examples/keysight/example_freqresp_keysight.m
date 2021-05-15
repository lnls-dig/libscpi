fid_instr.osc = vxi11('KEYSIGH-LOH3DDN.abtlus.org.br');
fid_instr.gen = vxi11('A-33521A-01494.abtlus.org.br');

excit_param = struct;

excit_param.npts = 1e6;
excit_param.Voffset = 0;
excit_param.df = 50;
excit_param.type = 'sin';

excit_param.nharm = 10;
excit_param.sin_freq = [5e2:1e2:10e2 2e3:1e3:10e3 20e3:10e3:500e3];
excit_param.navg = 1;

channel = struct( ...
    'name_instr', {'CHAN1', 'CHAN2'}, ...
    'name', {'V_{feedback}', 'V_{OUT}'}, ...
    'derivative', {0 0} ...
    );
   
param = scpiparam;
    expdef = [ ...
         0     50e-3
        ];

for i=1:size(expdef,1)
    excit_param.Voffset = expdef(i,1);
    excit_param.Vpeak2peak = expdef(i,2);
    
    r = freqresp_keysight(fid_instr, channel, excit_param);
    fname = sprintf('exp_Voffset%dmV_Vpp%dmV_%s.mat', round(excit_param.Voffset*1e3),  round(excit_param.Vpeak2peak*1e3), datestr(now, 'yyyy-mm-dd_HH-MM-SS'));
    save(fname, 'r', '-v7');
end
