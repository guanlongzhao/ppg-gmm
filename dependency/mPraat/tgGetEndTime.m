function t = tgGetEndTime(tg, tierInd)
% function t = tgGetEndTime(tg, tierInd)
%
% Returns end time. If tier index is specified, it returns end time
% of the tier, if it is not specified, it returns end time of the whole
% TextGrid.
%
% tierInd ... [optional] tier index or 'name'
%
% v1.0, Tomas Boril, borilt@gmail.com
% 
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgGetEndTime(tg)
%   tgGetEndTime(tg, 'phone')

if nargin  == 1
    t = tg.tmax;
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
        t = tg.tier{tierInd}.T(end);
    end
elseif tgIsIntervalTier(tg, tierInd)
    if length(tg.tier{tierInd}.T2) < 1
        t = NaN;
    else
        t = tg.tier{tierInd}.T2(end);
    end
else
    error('unknown tier type')
end
