function varargout = freqresp_analyze_keysight(idexpresult, type, tfdef)

if strcmpi(type, 'PRBS')
    Y = fft(idexpresult.data);
    npts = size(Y,1);
    
    f = (0:npts-1)'*idexpresult.Fs/npts;
    
    idx_newFs = find(f <= idexpresult.excit_param.prbs_rate);
    idx_newFs = idx_newFs(end);
    
    idx = 2:idx_newFs;
    
    Y = Y(idx,:);
    f = f(idx);
elseif strcmpi(type, 'sin')
    Y = squeeze(idexpresult.fft_harmonics(1,:,:)).';
    f = idexpresult.freq';
end

for i=1:size(Y,2)
    if idexpresult.derivative(i) ~= 0
        Y(:,i) = Y(:,i).*(2*pi*f*1j).^(-idexpresult.derivative(i));
    end
end

npts_fresp = size(Y,1);
n_fresp = size(tfdef,1);
leg_fresp = cell(n_fresp,1);

fresp = zeros(npts_fresp, n_fresp);
for i = 1:n_fresp
    fresp(:,i) = Y(:,tfdef(i,2))./Y(:,tfdef(i,1));
    leg_fresp{i} = [idexpresult.name{tfdef(i,1)} ' -> ' idexpresult.name{tfdef(i,2)}];
end

r.fresp = fresp;
r.f = f;

if nargout < 1
    figure(1)
    subplot(211)
    semilogx(f, 20*log10(abs(fresp)), 'LineWidth', 2);
    legend(leg_fresp)
    grid on
    hold all
    xlim([f(1) f(end)])
    ylabel('Magnitude [dB]');
    subplot(212)
    semilogx(f, 180/pi*unwrap(angle(fresp)), 'LineWidth', 2);
    hold all
    grid on
    xlim([f(1) f(end)])
    ylabel('Phase [°]');
    xlabel('Frequency [Hz]');
else
    varargout = {r};
end