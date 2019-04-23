function c = tgGetNumberOfPoints(tg, tierInd)
% function c = tgGetNumberOfPoints(tg, tierInd)
%
% Returns number of points in the given point tier.
%
% v1.0, Tomas Boril, borilt@gmail.com
% 
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgGetNumberOfPoints(tg, 'phoneme')

if nargin ~= 2
    error('Wrong number of arguments.')
end

tierInd = tgI(tg, tierInd);

if ~tgIsPointTier(tg, tierInd)
    error(['tier ' num2str(tierInd) ' is not PointTier']);
end

c = length(tg.tier{tierInd}.T);
