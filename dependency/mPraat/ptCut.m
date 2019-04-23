function ptNew = ptCut(pt, tStart, tEnd)
% function ptNew = ptCut(pt, tStart, tEnd)
%
% Cut the specified interval from the PitchTier and preserve time
%
% pt      ... PitchTier object
% tStart  ... [optional] beginning time of interval to be cut (default -Inf = cut from the tMin of the PitchTier)
% tEnd    ... final time of interval to be cut (default Inf = cut to the tMax of the PitchTier)
% 
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   pt = ptRead('demo/H.PitchTier');
%   pt2 =   ptCut(pt,  3);
%   pt2_0 = ptCut0(pt, 3);
%   pt3 =   ptCut(pt,  2, 3);
%   pt3_0 = ptCut0(pt, 2, 3);
%   pt4 =   ptCut(pt,  -Inf, 1);
%   pt4_0 = ptCut0(pt, -Inf, 1);
%   pt5 =   ptCut(pt,  -1, 1);
%   pt5_0 = ptCut0(pt, -1, 1);
%   subplot(3,1,1)
%   ptPlot(pt)
%   subplot(3,1,2)
%   ptPlot(pt2)
%   subplot(3,1,3)
%   ptPlot(pt2_0)
%   figure
%   subplot(2,3,1)
%   ptPlot(pt3)
%   subplot(2,3,4)
%   ptPlot(pt3_0)
%   subplot(2,3,2)
%   ptPlot(pt4)
%   subplot(2,3,5)
%   ptPlot(pt4_0)
%   subplot(2,3,3)
%   ptPlot(pt5)
%   subplot(2,3,6)
%   ptPlot(pt5_0)

if nargin < 1 || nargin > 3
    error('Wrong number of arguments.')
end

if nargin == 1
    tStart = -Inf;
    tEnd = Inf;
elseif nargin == 2
    tEnd = Inf;
end


if isinf(tStart) && tStart>0
    error('infinite tStart can be negative only')
end
if isinf(tEnd) && tEnd<0
    error('infinite tEnd can be positive only')
end

ptNew = pt;
ptNew.t = pt.t(pt.t >= tStart  &  pt.t <= tEnd);
ptNew.f = pt.f(pt.t >= tStart  &  pt.t <= tEnd);

if isinf(tStart)
    ptNew.tmin = pt.tmin;
else
    ptNew.tmin = tStart;
end

if isinf(tEnd)
    ptNew.tmax = pt.tmax;
else
    ptNew.tmax = tEnd;
end
