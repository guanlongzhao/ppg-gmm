function y = ptLegendreSynth(c, npoints)
% function y = ptLegendreSynth(c, npoints)
%
% Synthetize the contour from vector of Legendre polynomials 'c' in 'npoints' equidistant points.
% Returns row vector of values of synthetized contour.
%
% c            ... Row vector of Legendre polynomials coefficients
% npoints      ... [optional] Number of points of PitchTier interpolation (default: 1000)
% 
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   pt = ptRead('demo/H.PitchTier');
%   pt = ptHz2ST(pt);
%   pt = ptCut(pt, 3, Inf)  % cut PitchTier from t = 3 sec and preserve time
%   c = ptLegendre(pt)
%   leg = ptLegendreSynth(c);
%   ptLeg = pt;
%   ptLeg.t = linspace(ptLeg.tmin, ptLeg.tmax, length(leg));
%   ptLeg.f = leg;
%   plot(pt.t, pt.f, 'ko')
%   xlabel('Time (sec)'); ylabel('F0 (ST re 100 Hz)')
%   hold on; plot(ptLeg.t, ptLeg.f, 'b')                                         


if nargin < 1 || nargin > 2
    error('Wrong number of arguments.')
end

if nargin == 1
    npoints = 1000;
end

if ~isInt(npoints) || npoints < 0
    error('npoints must be integer >= 0.')
end

if size(c, 1) ~= 1
    error('c must be a row vector.');
end


lP = npoints; % poèet vzorkù polynomu
nP = length(c);

B = zeros(nP, lP);  % báze
x = linspace(-1, 1, lP);

for I = 1: nP
    n = I - 1;
    p = zeros(1, lP);
    for k = 0: n
        p = p + x.^k*binomcoeff2(n, k)*binomcoeff2((n+k-1)/2, n);
    end
    p = p*2.^n;

    B(I, :) = p;
end


if nP > 0
    y = c * B;
else
    y = NaN*ones(1, npoints);
end

