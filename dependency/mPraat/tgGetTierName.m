function n = tgGetTierName(tg, tierInd)
% function n = tgGetTierName(tg, tierInd)
%
% Returns name of the tier.
% 
% tierInd ... tier index or 'name'
%
% v1.0, Tomas Boril, borilt@gmail.com
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgGetTierName(tg, 2)

if nargin ~= 2
    error('Wrong number of arguments.')
end

tierInd = tgI(tg, tierInd);

n = tg.tier{tierInd}.name;
