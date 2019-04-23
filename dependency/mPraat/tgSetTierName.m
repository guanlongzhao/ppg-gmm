function tgNew = tgSetTierName(tg, tierInd, name)
% function tgNew = tgSetTierName(tg, tierInd, name)
%
% Sets (changes) name of tier of the given index.
%
% tierInd ... tier index or 'name'
% name ... new 'name'
% 
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tg2 = tgSetTierName(tg, 'word', 'WORDTIER');
%   tgGetTierName(tg2, 4)


if nargin ~= 3
    error('Wrong number of arguments.')
end

tierInd = tgI(tg, tierInd);

tgNew = tg;
tgNew.tier{tierInd}.name = name;
