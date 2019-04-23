function c = tgCountLabels(tg, tierInd, label)
% function c = tgCountLabels(tg, tierInd, label)
%
% Returns number of labels with the specified label.
%
% tierInd ... tier index or 'name'
% label ... label to be counted
% 
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgCountLabels(tg, 'phone', 'a')

if nargin ~= 3
    error('Wrong number of arguments.')
end

tierInd = tgI(tg, tierInd);

c = 0; % count

for I = 1: length(tg.tier{tierInd}.Label)
    if strcmp(tg.tier{tierInd}.Label{I}, label) == 1
        c = c + 1;
    end
end
