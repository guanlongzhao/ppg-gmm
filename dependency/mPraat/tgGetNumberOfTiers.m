function ntiers = tgGetNumberOfTiers(tg)
% function ntiers = tgGetNumberOfTiers(tg)
%
% Returns number of tiers.
%
% v1.0, Tomas Boril, borilt@gmail.com
% 
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgGetNumberOfTiers(tg)


ntiers = length(tg.tier);
