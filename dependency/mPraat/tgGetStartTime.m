function t = tgGetStartTime(tg, tierInd)
% function t = tgGetStartTime(tg, tierInd)
%
% Returns start time. If tier index is specified, it returns start time
% of the tier, if it is not specified, it returns start time of the whole
% TextGrid.
% 
% tierInd ... [optional] tier index or 'name'
%
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgGetStartTime(tg)
%   tgGetStartTime(tg, 'phone')

if nargin  == 1
    t = tg.tmin;
    return;
end

if nargin ~= 2
    error('Wrong number of arguments.')
end

tierInd = tgI(tg, tierInd);

if tgIsPointTier(tg, tierInd)
    if length(tg.tier{tierInd}.T) < 1
        t = NaN;
    else
        t = tg.tier{tierInd}.T(1);
    end
elseif tgIsIntervalTier(tg, tierInd)
    if length(tg.tier{tierInd}.T1) < 1
        t = NaN;
    else
        t = tg.tier{tierInd}.T1(1);
    end
else
    error('unknown tier type')
end
