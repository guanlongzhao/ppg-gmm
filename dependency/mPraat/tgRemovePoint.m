function tgNew = tgRemovePoint(tg, tierInd, index)
% function tgNew = tgRemovePoint(tg, tierInd, index)
%
% Remove point of the given index from the point tier.
%
% tierInd ... tier index or 'name'
%
% v1.0, Tomas Boril, borilt@gmail.com
% 
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tg.tier{tgI(tg, 'phoneme')}.Label .'
%   tg2 = tgRemovePoint(tg, 'phoneme', 1);
%   tg2.tier{tgI(tg2, 'phoneme')}.Label .'


if nargin ~= 3
    error('Wrong number of arguments.')
end

tierInd = tgI(tg, tierInd);

if ~tgIsPointTier(tg, tierInd)
    error(['tier ' num2str(tierInd) ' is not PointTier']);
end

npoints = tgGetNumberOfPoints(tg, tierInd);
if index < 1 || index>npoints
    error(['index of point out of range, index = ' num2str(index) ', npoints = ' num2str(npoints)]);
end

if ~isInt(index)
    error(['index must be integer >= 1 [' num2str(index) ']']);
end

tgNew = tg;
for I = index: npoints - 1
    tgNew.tier{tierInd}.T(I) = tgNew.tier{tierInd}.T(I+1);
    tgNew.tier{tierInd}.Label{I} = tgNew.tier{tierInd}.Label{I+1};
end

tgNew.tier{tierInd}.T(end) = [];
tgNew.tier{tierInd}.Label(end) = [];
