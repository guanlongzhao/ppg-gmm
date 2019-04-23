function b = tgIsIntervalTier(tg, tierInd)
% function b = tgIsIntervalTier(tg, tierInd)
%
% Returns true if the tier is IntervalTier, false otherwise.
%
% tierInd ... tier index or 'name'
% 
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgIsIntervalTier(tg, 1)
%   tgIsIntervalTier(tg, 'word')


tierInd = tgI(tg, tierInd);

if strcmp(tg.tier{tierInd}.type, 'interval') == 1
    b = true;
else
    b = false;
end
