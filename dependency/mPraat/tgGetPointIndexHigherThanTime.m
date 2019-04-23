function ind = tgGetPointIndexHigherThanTime(tg, tierInd, time)
% function ind = tgGetPointIndexHigherThanTime(tg, tierInd, time)
%
% Returns index of point which is nearest the given time from right, i.e.
% time <= pointTime. Tier index must belong to point tier. 
%
% tierInd ... tier index or 'name'
% time ... time which is going to be found in points
% 
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgGetPointIndexHigherThanTime(tg, 'phoneme', 0.5)


if nargin ~= 3
    error('Wrong number of arguments.')
end

tierInd = tgI(tg, tierInd);
if ~tgIsPointTier(tg, tierInd)
    error(['tier ' num2str(tierInd) ' is not PointTier']);
end

ind = NaN;
npoints = length(tg.tier{tierInd}.T);
for I = 1: npoints
    if time <= tg.tier{tierInd}.T(I)
        ind = I;
        break;
    end
end
