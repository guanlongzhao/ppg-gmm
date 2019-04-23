function tgNew = tgInsertNewPointTier(tg, tierInd, tierName)
% function tgNew = tgInsertNewPointTier(tg, tierInd, tierName)
%
% Inserts new point tier to the specified index (existing tiers are
% shifted).
%
% tierInd ... new tier index (1 = the first)
% tierName ... new tier name
% 
% v1.0, Tomas Boril, borilt@gmail.com
%
%   tg = tgRead('demo/H.TextGrid');
%   tg2 = tgInsertNewPointTier(tg, 1, 'POINTS');
%   tg2 = tgInsertPoint(tg2, 'POINTS', 3, 'MY POINT');
%   tgPlot(tg2);

if nargin ~= 3
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
tNew.type = 'point';
tNew.T = [];
tNew.Label = {};
for I = ntiers + 1: -1: tierInd+1
    tgNew.tier{I} = tgNew.tier{I-1};
end

tgNew.tier{tierInd} = tNew;
