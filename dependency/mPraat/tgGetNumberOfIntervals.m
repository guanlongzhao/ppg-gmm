function c = tgGetNumberOfIntervals(tg, tierInd)
% function c = tgGetNumberOfIntervals(tg, tierInd)
%
% Returns number of intervals in the given interval tier.
%
% v1.0, Tomas Boril, borilt@gmail.com
% 
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgGetNumberOfIntervals(tg, 'phone')

if nargin ~= 2
    error('Wrong number of arguments.')
end

tierInd = tgI(tg, tierInd);

if ~tgIsIntervalTier(tg, tierInd)
    error(['tier ' num2str(tierInd) ' is not IntervalTier']);
end

c = length(tg.tier{tierInd}.T1);
