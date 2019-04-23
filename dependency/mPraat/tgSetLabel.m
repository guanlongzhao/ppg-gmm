function tgNew = tgSetLabel(tg, tierInd, index, label)
% function tgNew = tgSetLabel(tg, tierInd, index, label)
%
% Sets (changes) label of interval or point of the given index in the
% interval or point tier.
% 
% tierInd ... tier index or 'name'
% index ... index of interval or point
% label ... new 'label'
%
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tg2 = tgSetLabel(tg, 'word', 3, 'New Label');
%   tgGetLabel(tg2, 'word', 3)

if nargin ~= 4
    error('Wrong number of arguments.')
end

tierInd = tgI(tg, tierInd);


if tgIsIntervalTier(tg, tierInd)
    nint = tgGetNumberOfIntervals(tg, tierInd);
    if index < 1 || index > nint
        error(['index of interval out of range, index = ' num2str(index) ', nint = ' num2str(nint)]);
    end
elseif tgIsPointTier(tg, tierInd)
    npoints = tgGetNumberOfPoints(tg, tierInd);
    if index < 1 || index > npoints
        error(['index of point out of range, index = ' num2str(index) ', npoints = ' num2str(npoints)]);
    end
else
    error('unknown tier type')
end

if ~isInt(index)
    error(['index must be integer >= 1 [' num2str(index) ']']);
end

tgNew = tg;
tgNew.tier{tierInd}.Label{index} = label;
