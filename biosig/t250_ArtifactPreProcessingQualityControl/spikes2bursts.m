function [H, s] = spikes2bursts(fn, varargin)
% spikes2bursts convert spike trains into bursts. 
%  Spikes with an interspike interval smaller  
%  than 75 ms are considered a burst. The results are stored as an 
% event table. 
%
% HDR = spikes2bursts(filename)
% ... = spikes2bursts(HDR)
% ... = spikes2bursts(... [, dT_Burst ])
% ... = spikes2bursts(... [, dT_Burst [, dT_Exclude] ])
% ... = spikes2bursts(... , 'dT_Burst', dT_Burst)
% ... = spikes2bursts(... , 'dT_Exclude', dT_Exclude)
% ... = spikes2bursts(... , '-o',eventFilename)
% ... = spikes2bursts(... , '-b',burstFilename)
%   
% Input: 
%	filename  name of file containing spikes in the event table
%	HDR	header structure obtained by SOPEN, SLOAD, or meXSLOAD
%	dT_Burst	[default: 50e-3 s] am inter-spike-interval (ISI) exceeding this value, 
%		marks the beginning of a new burst
%	dT_Exclude an interspike interval smaller than this value, indicates a
%		double detection, and the second detection is deleted.
%		in case of several consecutive ISI's smaller than this value,
%		all except the first spikes are deleted.
%	eventFilename
%		filename to store event inforamation in GDF format. this is similar to 
%		the outputFile, except that the signal data is not included and is, therefore,
%		much smaller than the outputFile
%	burstFilename
%		filename for the "burst table", containing basic properties of each burst,
%		(it is an ASCII file in <tab>-delimited format)
%
% Output:  
%     HDR	header structure as defined in biosig
%     HDR.EVENT includes the detected spikes and bursts. 
%     HDR.BurstTable contains for each burst (each in a row) the following 5 numbers:
%	channel number, sweep number, OnsetTime within sweep [s], 
%	number of spikes within burst, and average inter-spike interval (ISI) [ms]
%     data	signal data, one channel per column
%		between segments, NaN values for 0.1s are introduced
%	
% References: 
%

%	$Id: detect_spikes_bursts.m 2739 2011-07-13 15:42:05Z schloegl $
%	Copyright (C) 2011 by Alois Schloegl <alois.schloegl@gmail.com>	
%    	This is part of the BIOSIG-toolbox http://biosig.sf.net/
%
%    BioSig is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    BioSig is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with BioSig.  If not, see <http://www.gnu.org/licenses/>.

if nargin < 1, 
	help spikes2bursts;
end;

%%%%% default settings %%%%%
dT_Burst = 50e-3;	%%% smaller ISI is a burst [s]
dT_Exclude = [];	%%% for identifying double detections, spikes with smaller ISI are excluded
evtFile = [];
burstFile = [];


%%%%% analyze input arguments %%%%%
k = 1;
K = 0;
while k <= length(varargin)
	if ischar(varargin{k})
		if (strcmp(varargin{k},'-e'))
			k = k + 1;
			evtFile = varargin{k};
		elseif (strcmp(varargin{k},'-b'))
			k = k + 1;
			burstFile = varargin{k};
		elseif (strcmpi(varargin{k},'dT_Burst'))
			k = k + 1;
			dT_Burst = varargin{k};
		elseif (strcmpi(varargin{k},'dT_Exclude'))
			k = k + 1;
			dT_Exclude = varargin{k};
		else
			warning(sprintf('unknown input argument <%s>- ignored',varargin{k}));
		end;
	elseif isnumeric(varargin{k})
		K = K + 1
		switch (K)
		case {1}
			dT_Burst = varargin{k};
		case {2}
			dT_Exclude = varargin{k};
		otherwise
			warning(sprintf('unknown input argument <%f> - ignored',varargin{k}));
		end;
	end;
	k = k+1;
end;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%	load data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	if ischar(fn) && exist(fn,'file')
		[s, HDR] = sload(fn);
	elseif isstruct(fn)
		HDR = fn;
	else
		help(mfilename); 
	end


	EVENT = HDR.EVENT;
	ix = (EVENT.TYP ~= hex2dec('0202'));
	if ~all(ix) warning('previously defined bursts are overwritten'); end;
	HDR.EVENT.POS = HDR.EVENT.POS(ix);
	HDR.EVENT.TYP = HDR.EVENT.TYP(ix);
	if ~isfield(EVENT,'DUR');
		EVENT.DUR = zeros(size(EVENT.POS));
	end; 
	if ~isfield(EVENT,'CHN');
		EVENT.CHN = zeros(size(EVENT.TYP));
	end; 

	Fs = HDR.SampleRate; 
	chan = unique(EVENT.CHN);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%	Set Parameters for Burst Detection 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	HDR.BurstTable = [];

	for ch = chan(:)';	% look for each channel 	
		OnsetSpike = EVENT.POS((EVENT.CHN==ch) & (EVENT.TYP==hex2dec('0201'))); 	%% spike onset time [samples]
		if isempty(OnsetSpike)
			continue;
		end;

		if ~isempty(dT_Exclude)
			% --- remove double detections < 1 ms
			OnsetSpike = OnsetSpike([1; 1+find(diff(OnsetSpike) > Fs * dT_Exclude)]);
		end; 
		
		%%%%%%% Burst Detection %%%%%%%%%%%%%%%%%%%
		OnsetBurst = OnsetSpike ( [1; 1 + find( diff(OnsetSpike) > Fs * dT_Burst ) ] );

		OnsetBurst(end+1) = HDR.SPR*HDR.NRec + 1;
		DUR        = repmat(NaN, size(OnsetBurst));
		BurstTable = repmat(NaN, length(OnsetBurst), 6);

		m2    = 0;
		t0    = [1; EVENT.POS(EVENT.TYP==hex2dec('7ffe'))];
		for m = 1:length(OnsetBurst)-1,	% loop for each burst candidate 
			tmp = OnsetSpike( OnsetBurst(m) <= OnsetSpike & OnsetSpike < OnsetBurst(m+1) );
			d   = diff(tmp);
			if length(tmp) > 1,
				m2 = m2 + 1;
				DUR(m) = length(tmp)*mean(d);
				ix = sum(t0 < OnsetBurst(m));
				T0 = t0(ix);
				BurstTable(m,:) = [ch, ix, (OnsetBurst(m) - T0)/HDR.SampleRate, length(tmp), 1000*mean(d)/HDR.SampleRate, 1000*min(d)/HDR.SampleRate];
			% else 
			% 	single spikes are not counted as bursts, DUR(m)==NaN marks them as invalid 
			end;
		end;

		% remove single spike bursts 
		ix             = find(~isnan(DUR));
		HDR.BurstTable = [HDR.BurstTable; BurstTable(ix,:)];
		OnsetBurst     = OnsetBurst(ix);
		DUR            = DUR(ix);
		
		EVENT.TYP = [EVENT.TYP; repmat(hex2dec('0202'), size(OnsetBurst))];
		EVENT.POS = [EVENT.POS; OnsetBurst];
		EVENT.DUR = [EVENT.DUR; DUR];
		EVENT.CHN = [EVENT.CHN; repmat(ch, size(DUR,1), 1) ];
	end; 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%	Output 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	HDR.EVENT = EVENT;
	H = HDR;

	if ~isempty(evtFile)
		%%% write data to output
		HDR.TYPE  = 'EVENT';
		HDR.VERSION = 3;
		%[p,f,e]=fileparts(fn);
		HDR.FILE = [];
		HDR.FileName  = evtFile;
		HDR.FILE.Path = '';
		HDR.NRec = 0;
		HDR.SPR = 0;
		HDR.Dur = 1/HDR.SampleRate;
		HDR = rmfield(HDR,'AS');
		HDR = sopen(HDR,'w');
	if (HDR.FILE.FID<0) fprintf(2,'Warning can not open file <%s> - GDF file can not be written\n',HDR.FileName); break; end;
		%HDR = swrite(HDR,s);
		HDR = sclose(HDR);
	end;

	if ~isempty(burstFile),
		fid = fopen(burstFile,'w');
	if (fid<0) fprintf(2,'Warning can not open file <%s> - burst table not written\n',burstFile); break; end;
		fprintf(fid,'#Burst\t#chan\t#sweep\tOnset [s] \t#spikes\tavgISI [ms] \tminISI [ms] \n');
		for m = 1:size(HDR.BurstTable,1);
			fprintf(fid,'%3d\t%d\t%d\t%9.5f\t%d\t%6.2f\t%6.2f\n', m, HDR.BurstTable(m,:) );
		end;
		if (fid>3) fclose(fid); end;
	end;


