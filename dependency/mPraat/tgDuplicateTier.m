function tgNew = tgDuplicateTier(tg, originalInd, newInd)
% function tgNew = tgDuplicateTier(tg, originalInd, newInd)
%
% Duplicates tier originalInd to new tier with specified index newInd
% (existing tiers are shifted).
% After this operation, it is highly recommended to set a name to the new
% tier with tgSetTierName. Otherwise, both original and new tiers have the
% same name which is permitted but not recommended. In such a case, we
% cannot use the comfort of using tier name instead of its index in other
% functions.
% 
% originalInd ... tier index or 'name'
% newInd ... new tier index (1 = the first)
%
% v1.0, Tomas Boril, borilt@gmail.com
%
%   tg = tgRead('demo/H.TextGrid');
%   tg2 = tgDuplicateTier(tg, 'word', 1);
%   tg2 = tgSetTierName(tg2, 1, 'NEW');
%   tgPlot(tg2);



if nargin ~= 3
    error('Wrong number of arguments.')
end

originalInd = tgI(tg, originalInd);
if ~isInt(newInd)
    error(['newInd must be integer >= 1 [' num2str(newInd) ']']);
end

ntiers = tgGetNumberOfTiers(tg);
if newInd < 1 || newInd>ntiers+1
    error(['newInd out of range [1; ntiers+1], newInd = ' num2str(newInd) ', ntiers = ' num2str(ntiers)]);
end

tgNew = tg;

tOrig = tg.tier{originalInd};

for I = ntiers + 1: -1: newInd+1
    tgNew.tier{I} = tgNew.tier{I-1};
end

tgNew.tier{newInd} = tOrig;
