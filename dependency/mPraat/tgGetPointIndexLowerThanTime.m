function ind = tgGetPointIndexLowerThanTime(tg, tierInd, time)
% function ind = tgGetPointIndexLowerThanTime(tg, tierInd, time)
%
% Returns index of point which is nearest the given time from left, i.e.
% pointTime <= time. Tier index must belong to point tier. 
%
% tierInd ... tier index or 'name'
% time ... time which is going to be found in points
% 
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgGetPointIndexLowerThanTime(tg, 'phoneme', 0.5)


if nargin ~= 3
    error('Wrong number of arguments.')
end

tierInd = tgI(tg, tierInd);
if ~tgIsPointTier(tg, tierInd)
    error(['tier ' num2str(tierInd) ' is not PointTier']);
end

ind = NaN;
npoints = length(tg.tier{tierInd}.T);
for I = npoints: -1: 1
    if time >= tg.tier{tierInd}.T(I)
        ind = I;
        break;
    end
end
