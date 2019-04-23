function lab = tgGetLabel(tg, tierInd, index)
% function lab = tgGetLabel(tg, tierInd, index)
%
% Return label of point or interval at the specified index.
%
% tierInd ... tier index or 'name'
% index ... index of point or interval
% 
% v1.0, Tomas Boril, borilt@gmail.com
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgGetLabel(tg, 'phoneme', 4)
%   tgGetLabel(tg, 'phone', 4)


if nargin ~= 3
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
    error(['index must by integer >= 1 [' num2str(index) ']']);
end

lab = tg.tier{tierInd}.Label{index};
