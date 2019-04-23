function ptPlot(pt)
% function ptPlot(pt)
%
% Plots PitchTier.
% 
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   pt = ptRead('demo/H.PitchTier');
%   ptPlot(pt);
%
%   figure
%   tg = tgRead('demo/H.TextGrid');
%   tgPlot(tg, 2);
%   subplot(tgGetNumberOfTiers(tg)+1, 1, 1);
%   ptPlot(pt);


if nargin  ~= 1
    error('Wrong number of arguments.')
end

plot(pt.t, pt.f, 'ok', 'MarkerSize', 2)

if isfield(pt, 'tmin') && isfield(pt, 'tmax')
    xlim([pt.tmin pt.tmax])
end

ylim([min(pt.f)*0.95 max(pt.f)*1.05])
