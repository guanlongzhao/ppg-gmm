function b = tgIsPointTier(tg, tierInd)
% function b = tgIsPointTier(tg, tierInd)
%
% Returns true if the tier is PointTier, false otherwise.
% 
% tierInd ... tier index or 'name'
%
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgIsPointTier(tg, 1)
%   tgIsPointTier(tg, 'word')


tierInd = tgI(tg, tierInd);

if strcmp(tg.tier{tierInd}.type, 'point') == 1
    b = true;
else
    b = false;
end
