function tgNew = tgInsertPoint(tg, tierInd, time, label)
% function tgNew = tgInsertPoint(tg, tierInd, time, label)
%
% Inserts new point to point tier of the given index.
%
% tierInd ... tier index or 'name'
% time ... time of the new point
% label ... time of the new point
% 
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tg2 = tgInsertPoint(tg, 'phoneme', 1.4, 'NEW POINT');
%   tgPlot(tg2);

if nargin ~= 4
    error('Wrong number of arguments.')
end

tierInd = tgI(tg, tierInd);

if ~tgIsPointTier(tg, tierInd)
    error(['tier ' num2str(tierInd) ' is not PointTier']);
end

tgNew = tg;

indShift = tgGetPointIndexHigherThanTime(tg, tierInd, time);
npoints = tgGetNumberOfPoints(tg, tierInd);

if ~isnan(indShift)
    for I = npoints: -1: indShift
        tgNew.tier{tierInd}.T(I+1) = tgNew.tier{tierInd}.T(I);
        tgNew.tier{tierInd}.Label{I+1} = tgNew.tier{tierInd}.Label{I};
    end
end

if isnan(indShift)
    indShift = length(tgNew.tier{tierInd}.T) + 1;
end
tgNew.tier{tierInd}.T(indShift) = time;
tgNew.tier{tierInd}.Label{indShift} = label;

tgNew.tmin = min(tgNew.tmin, time);
tgNew.tmax = max(tgNew.tmax, time);
