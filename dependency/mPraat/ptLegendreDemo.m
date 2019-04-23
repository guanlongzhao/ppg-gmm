function ptLegendreDemo()
% function ptLegendreDemo()
%
% Plots first four Legendre polynomials
% 
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   ptLegendreDemo()


if nargin ~= 0
    error('Wrong number of arguments.')
end

subplot(2,2,1)
plot(ptLegendreSynth([1 0 0 0], 1024)); axis tight

subplot(2,2,2)
plot(ptLegendreSynth([0 1 0 0], 1024)); axis tight

subplot(2,2,3)
plot(ptLegendreSynth([0 0 1 0], 1024)); axis tight

subplot(2,2,4)
plot(ptLegendreSynth([0 0 0 1], 1024)); axis tight