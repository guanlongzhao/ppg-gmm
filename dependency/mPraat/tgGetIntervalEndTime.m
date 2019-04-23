function t = tgGetIntervalEndTime(tg, tierInd, index)
% function t = tgGetIntervalEndTime(tg, tierInd, index)
%
% Return end time of interval in interval tier.
%
% tierInd ... tier index or 'name'
% index ... index of interval
%
% v1.0, Tomas Boril, borilt@gmail.com
% 
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgGetIntervalEndTime(tg, 'phone', 5)

if nargin ~= 3
    error('Wrong number of arguments.')
end

tierInd = tgI(tg, tierInd);
if ~tgIsIntervalTier(tg, tierInd)
    error(['tier ' num2str(tierInd) ' is not IntervalTier']);
end

if ~isInt(index)
    error(['index must be integer >= 1 [' num2str(index) ']']);
end

nint = tgGetNumberOfIntervals(tg, tierInd);
if index < 1 || index>nint
    error(['index out of range, index = ' num2str(index) ', nint = ' num2str(nint)]);
end


t = tg.tier{tierInd}.T2(index);
