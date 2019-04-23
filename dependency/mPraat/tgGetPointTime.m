function t = tgGetPointTime(tg, tierInd, index)
% function t = tgGetPointTime(tg, tierInd, index)
%
% Return time of point at the specified index in point tier.
% 
% tierInd ... tier index or 'name'
% index ... index of point
%
% v1.0, Tomas Boril, borilt@gmail.com
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgGetPointTime(tg, 'phoneme', 4)


if nargin ~= 3
    error('Wrong number of arguments.')
end

tierInd = tgI(tg, tierInd);

if ~tgIsPointTier(tg, tierInd)
    error(['tier ' num2str(tierInd) ' is not PointTier']);
end

if ~isInt(index)
    error(['index must by integer >= 1 [' num2str(index) ']']);
end

npoints = tgGetNumberOfPoints(tg, tierInd);
if index < 1 || index>npoints
    error(['indexout of range, index = ' num2str(index) ', npoints = ' num2str(npoints)]);
end


t = tg.tier{tierInd}.T(index);
