function tgNew = tgRemoveIntervalLeftBoundary(tg, tierInd, index)
% function tgNew = tgRemoveIntervalLeftBoundary(tg, tierInd, index)
%
% Remove left boundary of the interval of the given index in Interval tier.
% In fact, it concatenates two intervals into one (and their labels). It
% cannot be applied to the first interval because it is the start boundary
% of the tier.
% E.g., we have interval 1-2-3, we remove the left boundary of the 2nd
% interval, the result is two intervals 12-3.
% If we do not want to concatenate labels, we have to set the label
% to the empty string '' before this operation.
%
% tierInd ... tier index or 'name'
% 
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgPlot(tg);
%   tg2 = tgRemoveIntervalLeftBoundary(tg, 'word', 3);
%   figure, tgPlot(tg2);

if nargin ~= 3
    error('Wrong number of arguments.')
end

tierInd = tgI(tg, tierInd);

if ~tgIsIntervalTier(tg, tierInd)
    error(['tier ' num2str(tierInd) ' is not IntervalTier']);
end

nint = tgGetNumberOfIntervals(tg, tierInd);
if index < 1 || index>nint
    error(['index of interval out of range, index = ' num2str(index) ', nint = ' num2str(nint)]);
end

if ~isInt(index)
    error(['index must be integer >= 1 [' num2str(index) ']']);
end

if index == 1
    error(['index cannot be 1 because it is the first boundary of the tier. index = ' num2str(index)]);
end

t1 = tg.tier{tierInd}.T1(index-1);
t2 = tg.tier{tierInd}.T2(index);
lab = [tg.tier{tierInd}.Label{index-1} tg.tier{tierInd}.Label{index}];

tgNew = tg;
for I = index: nint - 1
    tgNew.tier{tierInd}.T1(I) = tgNew.tier{tierInd}.T1(I+1);
    tgNew.tier{tierInd}.T2(I) = tgNew.tier{tierInd}.T2(I+1);
    tgNew.tier{tierInd}.Label{I} = tgNew.tier{tierInd}.Label{I+1};
end

tgNew.tier{tierInd}.T1(end) = [];
tgNew.tier{tierInd}.T2(end) = [];
tgNew.tier{tierInd}.Label(end) = [];

tgNew.tier{tierInd}.T1(index-1) = t1;
tgNew.tier{tierInd}.T2(index-1) = t2;
tgNew.tier{tierInd}.Label{index-1} = lab;

