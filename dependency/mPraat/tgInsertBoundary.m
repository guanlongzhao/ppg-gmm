function tgNew = tgInsertBoundary(tg, tierInd, time, label)
% function tgNew = tgInsertBoundary(tg, tierInd, time, label)
%
% Inserts new boundary into interval tier. This creates a new interval, to
% which we can set the label (optional argument).
% 
% tierInd ... tier index or 'name'
% time ... time of the new boundary
% label ... [optional] label of the new interval
%
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tg2 = tgInsertNewIntervalTier(tg, 1, 'INTERVALS');
%   tg2 = tgInsertBoundary(tg2, 'INTERVALS', 0.8);
%   tg2 = tgInsertBoundary(tg2, 'INTERVALS', 0.1, 'Interval A');
%   tg2 = tgInsertInterval(tg2, 'INTERVALS', 1.2, 2.5, 'Interval B');
%   tgPlot(tg2);
%
% Notes
% =====
% There are more possible situations which influence where the new label
% will be set.
%
% a) New boundary into the existing interval (the most common situation):
%    The interval is splitted into two parts. The left preserves the label
%    of the original interval, the right is set to the new (optional) label.
%
% b) On the left of existing interval (i.e., enlarging the tier size):
%    The new interval starts with the new boundary and ends at the start
%    of originally first existing interval. The label is set to the new
%    interval.
%
% c) On the right of existing interval (i.e., enlarging the tier size):
%    The new interval starts at the end of originally last existing
%    interval and ends with the new boundary. The label is set to the new
%    interval.
%    This is somewhat different behaviour than in a) and b) where the new
%    label is set to the interval which is on the right of the new
%    boundary. In c), the new label is set on the left of the new boundary.
%    But this is the only logical possibility.
%
% It is a nonsense to insert a boundary between existing intervals to a
% position where there is no interval. This is against the basic logic of
% Praat interval tiers where, at the beginning, there is one large empty
% interval from beginning to the end. And then, it is divided to smaller
% intervals by adding new boundaries. Nevertheless, if the TextGrid is
% created by external programmes, you may rarely find such discontinuities.
% In such a case, at first, use the tgRepairContinuity() function.


if nargin < 3 || nargin > 4
    error('Wrong number of arguments.')
end
if nargin == 3
    label = '';
end

tierInd = tgI(tg, tierInd);

if ~tgIsIntervalTier(tg, tierInd)
    error(['tier ' num2str(tierInd) ' is not IntervalTier']);
end

tgNew = tg;

index = tgGetIntervalIndexAtTime(tg, tierInd, time);
nint = tgGetNumberOfIntervals(tg, tierInd);

if nint == 0
    error('strange situation, tier does not have any interval.')
end

if isnan(index)
    if time > tg.tier{tierInd}.T2(end)   % situation c) On the right of existing interval
        tgNew.tier{tierInd}.T1(nint+1) = tg.tier{tierInd}.T2(nint);
        tgNew.tier{tierInd}.T2(nint+1) = time;
        tgNew.tier{tierInd}.Label{nint+1} = label;
        tgNew.tmax = max(tg.tmax, time);
    elseif time < tg.tier{tierInd}.T1(1) % situation b) On the left of existing interval
        for I = nint: -1: 1
            tgNew.tier{tierInd}.T1(I+1) = tgNew.tier{tierInd}.T1(I);
            tgNew.tier{tierInd}.T2(I+1) = tgNew.tier{tierInd}.T2(I);
            tgNew.tier{tierInd}.Label{I+1} = tgNew.tier{tierInd}.Label{I};
        end
        tgNew.tier{tierInd}.T1(1) = time;
        tgNew.tier{tierInd}.T2(1) = tgNew.tier{tierInd}.T1(2);
        tgNew.tier{tierInd}.Label{1} = label;
        tgNew.tmin = min(tg.tmin, time);
    elseif time == tg.tier{tierInd}.T2(end) % attempt to insert boundary exactly to the end of tier (nonsense)
        error(['cannot insert boundary because it already exists at the same position (tierInd ' num2str(tierInd) ', time ' num2str(time) ')'])
    else
        error('strange situation, cannot find any interval and ''time'' is between intervals.')
    end
else % situation a) New boundary into the existing interval
    for I = 1: nint
        if ~isempty(find(tgNew.tier{tierInd}.T1 == time, 1)) || ~isempty(find(tgNew.tier{tierInd}.T2 == time, 1))
            error(['cannot insert boundary because it already exists at the same position (tierInd ' num2str(tierInd) ', time ' num2str(time) ')'])
        end
    end
    
    for I = nint: -1: index+1
        tgNew.tier{tierInd}.T1(I+1) = tgNew.tier{tierInd}.T1(I);
        tgNew.tier{tierInd}.T2(I+1) = tgNew.tier{tierInd}.T2(I);
        tgNew.tier{tierInd}.Label{I+1} = tgNew.tier{tierInd}.Label{I};
    end
    tgNew.tier{tierInd}.T1(index) = tg.tier{tierInd}.T1(index);
    tgNew.tier{tierInd}.T2(index) = time;
    tgNew.tier{tierInd}.Label{index} = tg.tier{tierInd}.Label{index};
    tgNew.tier{tierInd}.T1(index+1) = time;
    tgNew.tier{tierInd}.T2(index+1) = tg.tier{tierInd}.T2(index);
    tgNew.tier{tierInd}.Label{index+1} = label;
end
