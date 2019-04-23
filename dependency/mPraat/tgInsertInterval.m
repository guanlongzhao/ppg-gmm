function tgNew = tgInsertInterval(tg, tierInd, tStart, tEnd, label)
% function tgNew = tgInsertInterval(tg, tierInd, tStart, tEnd, label)
%
% Inserts new interval into an empty space in interval tier:
% a) Into an already existing interval with empty label (most common
% situation because, e.g., a new interval tier has one empty interval from
% beginning to the end.
% b) Outside og existing intervals (left or right), this may create another
% empty interval between.
% 
% tierInd ... tier index or 'name'
% tStart ... start time of the new interval
% tEnd ... end time of the new interval
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
% In most cases, this function is the same as 1.) tgInsertBoundary(tEnd)
% and 2.) tgInsertBoundary(tStart, 'new label'). But, additional checks are
% performed: a) tStart and tEnd belongs to the same empty interval, or
% b) both times are outside of existings intervals (both left or both right).
%
% Intersection of the new interval with more already existing (even empty)
% does not make a sense and is forbidden.
%
% In many situations, in fact, this function creates more than one interval.
% E.g., let's assume an empty interval tier with one empty interval from 0 to 5 sec.
% 1.) We insert a new interval from 1 to 2 with label 'he'.
%     Result: three intervals, 0-1 '', 1-2 'he', 2-5 ''.
% 2.) Then, we insert an interval from 7 to 8 with label 'lot'.
%     Result: five intervals, 0-1 '', 1-2 'he', 2-5 '', 5-7 '', 7-8 'lot'
%     Note: the empty 5-7 '' interval is inserted because we are going
%     outside of the existing tier.
% 3.) Now, we insert a new interval exactly between 2 and 3 with label 'said'.
%     Result: really only one interval is created (and only the right
%     boundary is added because the left one already exists):
%     0-1 '', 1-2 'he', 2-3 'said', 3-5 '', 5-7 '', 7-8 'lot'.
% 4.) After this, we want to insert another interval, 3 to 5: label 'a'.
%     In fact, this does not create any new interval at all. Instead of
%     that, it only sets the label to the already existing interval 3-5.
%     Result: 0-1 '', 1-2 'he', 2-3 'said', 3-5 'a', 5-7 '', 7-8 'lot'.
%
% This function is not implemented in Praat (6.0.14). And it is very useful
% for adding separate intervals to an empty area in interval tier, e.g.,
% result of voice activity detection algorithm.
% On the other hand, if we want continuously add new consequential
% intervals, tgInsertBoundary() may be more useful. Because, in the
% tgInsertInterval() function, if we calculate both boundaries separately
% for each interval, strange situations may happen due to numeric round-up
% errors, like 3.14*5 ~= 15.7. In such cases, it may be hard to obtain
% precisely consequential time instances. As 3.14*5 is slightly larger than
% 15.7 (let's try to calculate 15.7 - 3.14*5), if you calculate tEnd of the
% first interval as 3.14*5 and tStart of the second interval as 15.7, this
% function refuse to create the second interval because it would be an
% intersection. In the opposite case (tEnd of the 1st: 15.7, tStart of the
% 2nd: 3.14*5), it would create another "micro" interval between these two
% slightly different time instances. Instead of that, if you insert only
% one boundary using the tgInsertBoundary() function, you are safe that
% only one new interval is created. But, if you calculate the "15.7" (no
% matter how) and store in the variable and then, use this variable in
% the tgInsertInterval() function both for the tEnd of the 1st interval and
% tStart of the 2nd interval, you are safe, it works fine.

if nargin < 4 || nargin > 5
    error('Wrong number of arguments.')
end
if nargin == 4
    label = '';
end

tierInd = tgI(tg, tierInd);

if ~tgIsIntervalTier(tg, tierInd)
    error(['tier ' num2str(tierInd) ' is not IntervalTier']);
end

if tStart >= tEnd
    error(['tStart [' num2str(tStart) '] must be lower than tEnd [' num2str(tEnd) ']']);
end
% Note: thanks to this condition, some situations (which were solved below) cannot happen
% (tStart == tEnd), thus it is easier. By the way, Praat does not allow to have 2 boundaries
% in the same time instance, do it is fully compatible.

% tgNew = tg;

nint = length(tg.tier{tierInd}.T1);
if nint == 0
    % Strange situation, tier does not have any single interval.
    tgNew = tg;
    tgNew.tier{tierInd}.T1 = tStart;
    tgNew.tier{tierInd}.T2 = tEnd;
    tgNew.tier{tierInd}.Label{1} = label;
    tgNew.tmin = min(tgNew.tmin, tStart);
    tgNew.tmax = max(tgNew.tmax, tEnd);
    return
end

tgLeft = tg.tier{tierInd}.T1(1);
tgRight = tg.tier{tierInd}.T2(end);
if tStart < tgLeft && tEnd < tgLeft
%     disp('insert totally left + empty filling interval')
    tgNew = tgInsertBoundary(tg, tierInd, tEnd);
    tgNew = tgInsertBoundary(tgNew, tierInd, tStart, label);
    return
elseif tStart <= tgLeft && tEnd == tgLeft
%     disp('insert totally left, fluently connecting')
    tgNew = tgInsertBoundary(tg, tierInd, tStart, label);
    return
elseif tStart < tgLeft && tEnd > tgLeft
    error(['intersection of new interval (' num2str(tStart) ' to ' num2str(tEnd) ' sec, ''' label ''') and several others already existing (region outside ''left'' and the first interval) is forbidden'])
elseif tStart > tgRight && tEnd > tgRight %%
%     disp('insert totally right + empty filling interval')
    tgNew = tgInsertBoundary(tg, tierInd, tEnd);
    tgNew = tgInsertBoundary(tgNew, tierInd, tStart, label);
    return
elseif tStart == tgRight && tEnd >= tgRight
%     disp('insert totally right, fluently connecting')
    tgNew = tgInsertBoundary(tg, tierInd, tEnd, label);
    return
elseif tStart < tgRight && tEnd > tgRight
    error(['intersection of new interval (' num2str(tStart) ' to ' num2str(tEnd) ' sec, ''' label ''') and several others already existing (the last interval and region outside ''right'') is forbidden'])
elseif tStart >= tgLeft && tEnd <= tgRight
    % disp('insert into an already existing area, we need a check: a) the same and b) empty interval')
    % Find all intervals, in which our times belongs - if we hit a boundary,
    % the time can belong to two intervals
    iStart = [];
    iEnd = [];
    for I = 1: nint
        if tStart >= tg.tier{tierInd}.T1(I) && tStart <= tg.tier{tierInd}.T2(I)
            iStart = [iStart I];
        end
        if tEnd >= tg.tier{tierInd}.T1(I) && tEnd <= tg.tier{tierInd}.T2(I)
            iEnd = [iEnd I];
        end
    end
    if ~(length(iStart) == 1 && length(iEnd) == 1)
        inters = intersect(iStart, iEnd); % nalezeni spolecneho intervalu z vice moznych variant
        if isempty(inters)
            % this is error but it is solved by the condition 'if iStart == iEnd' above
            iStart = iStart(end);
            iEnd = iEnd(1);
        else
            iStart = inters(1);
            iEnd = inters(1);
            if length(inters) > 1 % attempt to find the first suitable candidate
                for I = 1: length(inters)
                    if isempty(tg.tier{tierInd}.Label{inters(I)})
                        iStart = inters(I);
                        iEnd = inters(I);
                        break;
                    end
                end
            end
        end
    end
    if iStart == iEnd
        if isempty(tg.tier{tierInd}.Label{iStart})
%             disp('insert into an existing interval, the question is, concatenate or not?')
            t1 = tg.tier{tierInd}.T1(iStart);
            t2 = tg.tier{tierInd}.T2(iStart);
            if tStart == t1 && tEnd == t2
%                 disp('only this: set label to existing empty interval');
                tgNew = tg;
                tgNew.tier{tierInd}.Label{iStart} = label;
                return
%             elseif tStart == t1 && tEnd == t1   % this cannot happen because of the condition 'if iStart == iEnd' above
%                 disp('set label to original interval and insert one boundary to t1, this creates a new zero-length interval at the start with a new label and the whole original interval will stay empty')
%             elseif tStart == t2 && tEnd == t2   % this cannot happen because of the condition 'if iStart == iEnd' above
%                 disp('insert one boundary to t2 with new label, this ensures that the original empty interval stays as it is and it creates a new zero-length interval at the end with a new label')
            elseif tStart == t1 && tEnd < t2
%                 disp('set a new label to the original interval and insert one new boundary to tEnd, it splits the original interval into two parts, the first will have new label, the second stays empty')
                tgNew = tg;
                tgNew.tier{tierInd}.Label{iStart} = label;
                tgNew = tgInsertBoundary(tgNew, tierInd, tEnd);
                return
            elseif tStart > t1 && tEnd == t2
%                 disp('insert one new boundary to tStart with a new label, it splits the original interval into two parts, the first stays empty and the second will have new label')
                tgNew = tgInsertBoundary(tg, tierInd, tStart, label);
                return
            elseif tStart > t1 && tEnd < t2
%                 disp('insert one boundary to tEnd with empty label and then insert another boundary to tStart with new label, it splits the original interval into three parts, the first and the third will be empty, the second will have new label')
                tgNew = tgInsertBoundary(tg, tierInd, tEnd);
                tgNew = tgInsertBoundary(tgNew, tierInd, tStart, label);
            else
                error('Error in author''s logic. This cannot happen. Please, contact the author but be kind. He is really unhappy about this confusion.')
            end
        else
            error(['Cannot insert new interval (' num2str(tStart) ' to ' num2str(tEnd) ' sec, ''' label ''') into the interval with a non-empty label (' num2str(tg.tier{tierInd}.T1(iStart)) ' to ' num2str(tg.tier{tierInd}.T2(iStart)) ' sec, ''' tg.tier{tierInd}.Label{iStart} '''), it is forbidden.'])
        end
    else
        error(['intersection of new interval (' num2str(tStart) ' to ' num2str(tEnd) ' sec, ''' label ''') and several others already existing (indices ' num2str(iStart) ' to ' num2str(iEnd) ') is forbidden'])
    end
else
    error('Error in author''s logic. This cannot happen. Please, contact the author but be kind. He is really unhappy about this confusion.')
end

return
