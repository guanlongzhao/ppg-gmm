function tgNew = tgRemoveIntervalBothBoundaries(tg, tierInd, index)
% function tgNew = tgRemoveIntervalBothBoundaries(tg, tierInd, index)
%
% Remove both left and right boundary of interval of the given index in
% Interval tier. In fact, this operation concatenate three intervals into
% one (and their labels). It cannot be applied to the first and the last
% interval because they contain beginning or end boundary of the tier.
% E.g., let's assume interval 1-2-3. We remove both boundaries of the
% 2nd interval. The result is one interval 123.
% If we do not want to concatenate labels (we wanted to remove the label
% including its interval), we can set the label of the second interval
% to the empty string '' before this operation.
% If we only want to remove the label of interval "without concatenation",
% i.e., the desired result is 1-empty-3, it is not this operation of
% removing boundaries. Just set the label of the second interval to the
% empty string ''.
% 
% tierInd ... tier index or 'name'
%
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgPlot(tg);
%   tg2 = tgRemoveIntervalBothBoundaries(tg, 'word', 3);
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
    error(['index cannot be 1 because left boundary is the first boundary of the tier. index = ' num2str(index)]);
end

if index == nint
    error(['index cannot be the last interval because right boundary is the last boundary of the tier. index = ' num2str(index)]);
end

t1 = tg.tier{tierInd}.T1(index-1);
t2 = tg.tier{tierInd}.T2(index+1);
lab = [tg.tier{tierInd}.Label{index-1} tg.tier{tierInd}.Label{index} tg.tier{tierInd}.Label{index+1}];

tgNew = tg;
for I = index: nint-2
    tgNew.tier{tierInd}.T1(I) = tgNew.tier{tierInd}.T1(I+2);
    tgNew.tier{tierInd}.T2(I) = tgNew.tier{tierInd}.T2(I+2);
    tgNew.tier{tierInd}.Label{I} = tgNew.tier{tierInd}.Label{I+2};
end

tgNew.tier{tierInd}.T1(end) = [];
tgNew.tier{tierInd}.T2(end) = [];
tgNew.tier{tierInd}.Label(end) = [];
tgNew.tier{tierInd}.T1(end) = [];
tgNew.tier{tierInd}.T2(end) = [];
tgNew.tier{tierInd}.Label(end) = [];

tgNew.tier{tierInd}.T1(index-1) = t1;
tgNew.tier{tierInd}.T2(index-1) = t2;
tgNew.tier{tierInd}.Label{index-1} = lab;

