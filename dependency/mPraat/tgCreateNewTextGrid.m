function tgNew = tgCreateNewTextGrid(tStart, tEnd)
% function tgNew = tgCreateNewTextGrid(tStart, tEnd)
%
% Creates new and empty TextGrid. tStart and tEnd specify the total start
% and end time for the TextGrid. If a new interval tier is added later
% without specified start and end, they are set to TextGrid start and end.
%
% This empty TextGrid cannot be used for almost anything. At least one tier
% should be inserted using tgInsertNewIntervalTier or tgInsertNewPointTier.
% 
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   tg = tgCreateNewTextGrid(0, 5);
%   tg = tgInsertNewIntervalTier(tg, 1, 'word');
%   tg = tgInsertInterval(tg, 'word', 1, 2, 'hello');
%   tgPlot(tg);

if nargin ~= 2
    error('Wrong number of arguments.')
end

tgNew.tier = {};

if tStart > tEnd
    error(['tStart [' num2str(tStart) '] must be lower than tEnd [' num2str(tEnd) ']']);
end

tgNew.tmin = tStart;
tgNew.tmax = tEnd;
