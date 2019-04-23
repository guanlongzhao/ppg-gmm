function tgNew = tgInsertNewIntervalTier(tg, tierInd, tierName, tStart, tEnd)
% function tgNew = tgInsertNewIntervalTier(tg, tierInd, tierName, tStart, tEnd)
%
% Inserts new interval tier to the specified index (existing tiers are
% shifted). The new tier contains one empty interval from beginning to end.
% Then, if we add new boundaries, this interval is divided to smaller
% pieces.
% 
% tierInd ... new tier index (1 = the first)
% tierName ... new tier name
% tStart ... [optional] start time of the new tier
% tEnd ... [optional] end time of the new tier
%
% v1.0, Tomas Boril, borilt@gmail.com
%
%   tg = tgRead('demo/H.TextGrid');
%   tg2 = tgInsertNewIntervalTier(tg, 1, 'INTERVALS');
%   tg2 = tgInsertBoundary(tg2, 'INTERVALS', 0.8);
%   tg2 = tgInsertBoundary(tg2, 'INTERVALS', 0.1, 'Interval A');
%   tg2 = tgInsertInterval(tg2, 'INTERVALS', 1.2, 2.5, 'Interval B');
%   tgPlot(tg2);


if nargin ~= 3 && nargin ~= 5
    error('Wrong number of arguments.')
end

if ~isInt(tierInd)
    error(['tierInd must be integer >= 1 [' num2str(tierInd) ']']);
end

ntiers = tgGetNumberOfTiers(tg);
if tierInd < 1 || tierInd>ntiers+1
    error(['tierInd out of range [1; ntiers+1], tierInd = ' num2str(tierInd) ', ntiers = ' num2str(ntiers)]);
end

tgNew = tg;

tNew.name = tierName;
tNew.type = 'interval';
if nargin == 5
    if tStart >= tEnd
        error(['tStart [' num2str(tStart) '] must be lower than tEnd [' num2str(tEnd) ']']);
    end
    tNew.T1(1) = tStart;
    tNew.T2(1) = tEnd;
    tgNew.tmin = min(tg.tmin, tStart);
    tgNew.tmax = max(tg.tmax, tEnd);
else
    tNew.T1(1) = tg.tmin;
    tNew.T2(1) = tg.tmax;
end
tNew.Label{1} = '';
for I = ntiers + 1: -1: tierInd+1
    tgNew.tier{I} = tgNew.tier{I-1};
end

tgNew.tier{tierInd} = tNew;
