function ptNew = ptInterpolate(pt, t)
% function ptNew = ptInterpolate(pt, t)
%
% Interpolates PitchTier contour in given time instances.
%
%
%  a) If t < min(pt.t) (or t > max(pt.t)), returns the first (or the last) value of pt.f
%  b) If t is existing point in pt.t, returns the respective pt.f.
%  c) If t is Between two existing points, returns linear interpolation of these two points.
%
% pt ... PitchTier object
% t  ... vector of time instances of interest
% 
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   pt = ptRead('demo/H.PitchTier');
%   pt = ptHz2ST(pt, 100);
%   pt2 = ptInterpolate(pt, pt.t(1): 0.001: pt.t(end));
%   subplot(2,1,1)
%   ptPlot(pt);
%   subplot(2,1,2)
%   ptPlot(pt2)

if nargin ~= 2
    error('Wrong number of arguments.')
end

if length(pt.t) ~= length(pt.f)
    error('PitchTier does not have equal length vectors .t and .f')
end

if length(pt.t) < 1
    ptNew = NaN;
    return
end
    

if ~isequal(sort(pt.t), pt.t)
    error('time instances .t in PitchTier are not increasingly sorted')
end

if ~isequal(unique(pt.t), pt.t)
    error('duplicated time instances in .t vector of the PitchTier')
end

ptNew = pt;
ptNew.t = t;

f = zeros(1, length(t));
for I = 1: length(t)
    if length(pt.t) == 1
        f(I) = pt.f(1);
    elseif t(I) < pt.t(1)   % a)
        f(I) = pt.f(1);
    elseif t(I) > pt.t(end)   % a)
        f(I) = pt.f(end);
    else
        % b)
        ind = find(pt.t == t(I));
        if length(ind) == 1
            f(I) = pt.f(ind);
        else
            % c)
            ind2 = find(pt.t > t(I)); ind2 = ind2(1);
            ind1 = ind2 - 1;
            % y = ax + b;  a = (y2-y1)/(x2-x1);  b = y1 - ax1
            a = (pt.f(ind2) - pt.f(ind1)) / (pt.t(ind2) - pt.t(ind1));
            b = pt.f(ind1) - a*pt.t(ind1);
            f(I) = a*t(I) + b;
        end
    end
end

ptNew.f = f;
