function rt_pooraudioproxy(cfg)

% RT_POORAUDIOPROXY reads continuous data from the sound card using the 
% standard Matlab API and writes it to a FieldTrip buffer. This proxy has
% poor timing and will produce dropped audio frames between blocks. Also
% the Matlab documentation warns about using this API for long recordings
% because this will fill up memory and degrade performance.
%
% The FieldTrip buffer is a network transparent server that allows the
% acquisition client to stream data to it. An analysis client can connect
% to read the data upon request. Multiple clients can connect simultaneously,
% each analyzing a specific aspect of the data concurrently.
%
% Use as
%   rt_pooraudioproxy(cfg)
%
% The audio-specific configuration structure can contain
%   cfg.channel     = number of channels (1 or 2, default=2)
%   cfg.blocksize   = size of recorded audio blocks in seconds (default=1)
%   cfg.fsample     = audio sampling frequency in Hz (default = 44100)
%   cfg.nbits       = recording depth in bits (default = 16)
% Note that currently, the sound will be buffered in double precision irrespective of the sampling bit depth.
%
% The target to write the data to is configured as
%   cfg.target.datafile      = string, target destination for the data (default = 'buffer://localhost:1972')
%   cfg.target.dataformat    = string, default is determined automatic
%
% To stop this realtime function, you have to press Ctrl-C

% Copyright (C) 2010, Stefan Klanke / Robert Oostenveld

% set the defaults
if ~isfield(cfg, 'target'),             cfg.target = [];                                  end
if ~isfield(cfg, 'blocksize'),          cfg.blocksize = 1;                                end % in seconds
if ~isfield(cfg, 'channel'),            cfg.channel = 2;                                  end % default is stereo
if ~isfield(cfg, 'fsample'),            cfg.fsample = 44100;                              end % in Hz
if ~isfield(cfg, 'nbits'),              cfg.nbits = 16;                                   end % default 16 bit
if ~isfield(cfg.target, 'datafile'),    cfg.target.datafile = 'buffer://localhost:1972';  end
if ~isfield(cfg.target, 'dataformat'),  cfg.target.dataformat = [];                       end % default is to use autodetection of the output format
if ~isfield(cfg.target, 'eventfile'),   cfg.target.eventfile = 'buffer://localhost:1972'; end
if ~isfield(cfg.target, 'eventformat'), cfg.target.eventformat = [];                      end % default is to use autodetection of the output format

hdr = [];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create a fieldtrip compatible header structure
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hdr.Fs                 = cfg.fsample;								  
hdr.nChans             = cfg.channel;					                  
hdr.nSamples           = 0;                                   
hdr.nSamplesPre        = 0;
hdr.nTrials            = 1;                           
if cfg.channel == 2
	hdr.label              = {'Audio Left','Audio Right'};
elseif cfg.channel == 1
	hdr.label              = {'Audio Left'};
else
	error 'Invalid channel number (only 1 or 2 are allowed)';
end
hdr.FirstTimeStamp     = nan;
hdr.TimeStampPerSample = nan;

REC = audiorecorder(cfg.fsample, cfg.nbits, cfg.channel);

count = 0;
numRead = 0;

while true
	recordblocking(REC, cfg.blocksize);	
	x = getaudiodata(REC);
	numRead = numRead + size(x,1);
	fprintf(1,'Total samples read so far: %d\n',numRead);
	
	count = count+1;
	
	if count==1
      % flush the file, write the header and subsequently write the data segment
      write_data(cfg.target.datafile, x', 'header', hdr, 'dataformat', cfg.target.dataformat, 'append', false);
    else
      % write the data segment
      %write_data(cfg.target.datafile, x', 'header', hdr, 'dataformat', cfg.target.dataformat, 'append', true);
	  write_data(cfg.target.datafile, x', 'append', true);
    end % if count==1

	hdr.nSamples = numRead;
	
end % while again
