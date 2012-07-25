function d = signal_deconvolution(r,t,fs,highpass,lowpass)
% SIGNAL_DECONVOLUTION deconvolves some raw data with some given template in order
%   to improve the detection of miniature epsp's, and ipsp's. 
%
% d = SIGNAL_DECONVOLUTION(raw,template,samplerate,highpass,lowpass)
% ... SIGNAL_DECONVOLUTION(raw,template,samplerate,[highpass,lowpass])
% ... SIGNAL_DECONVOLUTION(raw,template,samplerate,[lowpass, highpass])
%
% INPUT:
%    raw: raw data (a Nx1 data vector)
%    template: template (a Mx1 data vector)
%	it is assumed that the template starts immidiately with the first sample 		
%    samplerate: sampling rate in Hz
%    highpass: edge frequency of highpass filter in Hz, default 0.1 Hz.
%    lowpass: edge frequency of lowpass filter in Hz, default 100 Hz. 
% 	
% Output: 
%    d: detection trace 
%
% see also: get_local_maxima_above_threshold
%
% References: 
%  A. Pernía-Andrade, S.P. Goswami, Y. Stickler, U. Fröbe, A. Schlögl, and P. Jonas 2012
%  A deconvolution-based method with high sensitivity and temporal resolution for detection of spontaneous synaptic currents in vitro and in vivo
%  IST Austria

%  $Id$
%  Copyright (C) 2012 by Alois Schloegl, IST Austria <alois.schloegl@ist.ac.at>	
%  This is part of the BIOSIG-toolbox http://biosig.sf.net/


%% check filter settings - input arguments
if numel(highpass)==2, 
	B = highpass;
else
	B = [lowpass, highpass]; 
end; 
B = [min(B),max(B)]; 

%% transform into frequency domain 
H = fft(t,size(r,1));
R = fft(r); 

%% compute deconvolution in frequency domain
D = R./H;

%% filter in frequency domain
f = [0:size(r,1)-1] * fs / size(r,1);
ixf = ( ( B(1)<f & f<B(2) ) | ( fs-B(2)<f & f < fs-B(1) ) ); 
D(~ixf) = 0; 

%% convert from frequency domain into time domain. 
d = real(ifft(D));
	

