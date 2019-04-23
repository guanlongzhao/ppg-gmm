function ptNew = ptHz2ST(pt, ref)
% function ptNew = ptHz2ST(pt, ref)
%
% Converts Hz to Semitones with given reference (default 0 ST = 100 Hz).
%
% pt ... PitchTier object
% ref ... [optional] reference value (in Hz) for 0 ST. Default: 100 Hz.
% 
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   pt = ptRead('demo/H.PitchTier');
%   pt2 = ptHz2ST(pt);
%   pt3 = ptHz2ST(pt, 200);
%   subplot(3,1,1)
%   ptPlot(pt); ylabel('F0 (Hz)')
%   subplot(3,1,2)
%   ptPlot(pt2); ylabel('F0 (ST re 100 Hz)')
%   subplot(3,1,3)
%   ptPlot(pt3); ylabel('F0 (ST re 200 Hz)')

if nargin ~= 1 && nargin ~= 2
    error('Wrong number of arguments.')
end

if nargin == 1
    ref = 100;
elseif (~isnumeric(ref) | length(ref) ~= 1 | ref <= 0)
    error('ref must be a positive number.')
end

ptNew = pt;
ptNew.f = 12*log(pt.f/ref) / log(2);

