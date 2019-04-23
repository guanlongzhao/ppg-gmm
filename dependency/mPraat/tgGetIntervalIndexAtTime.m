function ind = tgGetIntervalIndexAtTime(tg, tierInd, time)
% function ind = tgGetIntervalIndexAtTime(tg, tierInd, time)
%
% Returns index of interval which includes the given time, i.e.
% tStart <= time < tEnd. Tier index must belong to interval tier. 
%
% tierInd ... tier index or 'name'
% time ... time which is going to be found in intervals
% 
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgGetIntervalIndexAtTime(tg, 'word', 0.5)


if nargin ~= 3
    error('Wrong number of arguments.')
end

tierInd = tgI(tg, tierInd);
if ~tgIsIntervalTier(tg, tierInd)
    error(['tier ' num2str(tierInd) ' is not IntervalTier']);
end

ind = NaN;
nint = length(tg.tier{tierInd}.T1);
for I = 1: nint
    if tg.tier{tierInd}.T1(I) <= time  && time < tg.tier{tierInd}.T2(I)
        ind = I;
        break;
    end
end
