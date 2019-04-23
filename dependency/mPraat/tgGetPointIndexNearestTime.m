function ind = tgGetPointIndexNearestTime(tg, tierInd, time)
% function ind = tgGetPointIndexNearestTime(tg, tierInd, time)
%
% Returns index of point which is nearest the given time (from both sides).
% Tier index must belong to point tier. 
% 
% tierInd ... tier index or 'name'
% time ... time which is going to be found in points
%
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgGetPointIndexNearestTime(tg, 'phoneme', 0.5)


if nargin ~= 3
    error('Wrong number of arguments.')
end

tierInd = tgI(tg, tierInd);

if ~tgIsPointTier(tg, tierInd)
    error(['tier ' num2str(tierInd) ' is not PointTier']);
end

npoints = length(tg.tier{tierInd}.T);
minDist = inf;
minInd = NaN;
for I = 1: npoints
    dist = abs(tg.tier{tierInd}.T(I) - time);
    if dist < minDist
        minDist = dist;
        minInd = I;
    end
end

ind = minInd;
