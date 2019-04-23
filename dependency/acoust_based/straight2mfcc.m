function mfcc = straight2mfcc(s,fs,nmel,delta)
%straight2mfcc - Convert STRAIGHT spectra into MFCCs using DCT
% Syntax:  mfcc = straight2mfcc(s,fs,nmel,delta)
%
% Inputs:
%    s - STRAIGHT spectral envelope 
%    fs - sampling rate of acoustic waveform
%    nmel - number of mel cepstral components to compute
%    delta - number of delta values to computer [0-2]
%
% Outputs:
%    mfcc - [N x nmel*(delta+1)] matrix of cepstral values on derivatives
%
% Example: Compute the first 13 cepstral coeffients plus their derivatives for the wav.
%    mfcc = straight2mfcc(s,fs,13,1)
%
% Other m-files required: fft2melmx (RASTAMAT)
% Subfunctions: none
% MAT-files required: none
%
% See also: fft2melmx

% Author: Daniel Felps
% email: dlfelps@gmail.com
% Jan 2011; Last revision: 2/28/2011

%------------- BEGIN CODE --------------
if nargin<4
    delta=0;
end
if nargin<3
    nmel=13;
end

% Generate filter bank
% fbank = melbankm(nmel,2*size(s,1)-1,fs);
% fbank(:,end) = []; % Function returns one more frequency bin than needed
fbank=fft2melmx(size(s,1)*2-2,fs,nmel,1,0,fs/2,1);%dlf 10/13/10
fbank=fbank(:,1:size(s,1));


% Mel -> log -> DCT
mfcc = dct(fbank*(log(s)));
% log_temp = log(s');
% mfcc = dct(fbank*((log_temp - repmat(mean(log_temp), size(s, 2), 1))')); % Cepstral Mean Substraction

% Remove MFCC_0, which is speaker dependent (WRONG)
% The first cepstral coefficient is speaker dependent, not MFCC_0
% mfcc(1,:) = [];

% Smoothing kernel for delta and delta-delta
% sker = [0.15 0.20 0.4 0.20 0.10];
% sker = sker/sum(sker);
d1ker = fliplr([ 1 -8   0  8 -1]/12);
d2ker = fliplr([-1 16 -30 16 -1]/12);

% Include delta and delta-delta coefficients
switch delta
  case 0
    % Do nothing
  case 1
    d1   = conv2(mfcc, d1ker, 'same');
    mfcc = [mfcc; d1];
    
    %     d    = diff(mfcc')';
    %     d    = conv2(d, sker, 'same');
    %     mfcc = [mfcc; [d d(:,end)]];
  case 2
    d1   = conv2(mfcc, d1ker, 'same');
    d2   = conv2(mfcc, d2ker, 'same');
    mfcc = [mfcc; d1; d2];
    
    %     d    = diff(mfcc')';
    %     d    = conv2(d, sker, 'same');
    %     dd   = diff(d')';
    %     dd   = conv2(dd, sker, 'same');
    %     mfcc = [mfcc; [d d(:,end)]; [dd dd(:,end) dd(:,end)] ];
end

% Cepstral Mean Subtraction
% mfcc = (mfcc - repmat(mean(mfcc')',1, size(mfcc,2)))./repmat(std(mfcc')',1, size(mfcc,2));
% mfcc = mfcc - repmat(mean(mfcc')',1, size(mfcc,2));

end

