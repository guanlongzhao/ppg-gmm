function tgNew = tgRemoveTier(tg, tierInd)
% function tgNew = tgRemoveTier(tg, tierInd)
%
% Removes tier of the given index.
%
% tierInd ... tier index or 'name'
%
% v1.0, Tomas Boril, borilt@gmail.com
% 
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgPlot(tg);
%   tg2 = tgRemoveTier(tg, 'word');
%   figure, tgPlot(tg2);


if nargin ~= 2
    error('Wrong number of arguments.')
end

tierInd = tgI(tg, tierInd);

ntiers = tgGetNumberOfTiers(tg);

tgNew = tg;

for I = tierInd: ntiers - 1
    tgNew.tier{I} = tgNew.tier{I+1};
end

tgNew.tier(ntiers) = [];
