function t = tgGetTotalDuration(tg, tierInd)
% function t = tgGetTotalDuration(tg, tierInd)
%
% Returns total duration. If tier index is specified, it returns duration
% of the tier, if it is not specified, it returns total duration of the
% TextGrid.
% 
% tierInd ... [optional] tier index or 'name'
%
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgGetTotalDuration(tg)
%   tgGetTotalDuration(tg, 'phone')


if nargin  == 1
    t = tgGetEndTime(tg) - tgGetStartTime(tg);
elseif nargin == 2
    t = tgGetEndTime(tg, tierInd) - tgGetStartTime(tg, tierInd);
else
    error('Wrong number of arguments.')
end
