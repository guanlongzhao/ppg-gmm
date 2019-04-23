function c = ptLegendre(pt, npoints, npolynomials)
% function c = ptLegendre(pt, npoints, npolynomials)
%
% Interpolate the PitchTier in 'npoints' equidistant points and approximate it by Legendre polynomials.
% Returns row vector of Legendre polynomials coefficients.
%
% pt           ... PitchTier object
% npoints      ... [optional] Number of points of PitchTier interpolation (default: 1000)
% npolynomials ... [optional] Number of polynomials to be used for Legendre modelling (default: 4)
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


if nargin < 1 || nargin > 3
    error('Wrong number of arguments.')
end

if nargin == 1
    npoints = 1000; npolynomials = 4;
elseif nargin == 2;
    npolynomials = 4;
end

if ~isInt(npoints) || npoints < 0
    error('npoints must be integer >= 0.')
end

if ~isInt(npolynomials) || npolynomials <= 0
    error('npolynomials must be integer > 0.')
end

pt = ptInterpolate(pt, linspace(pt.tmin, pt.tmax, npoints));

y = pt.f;


lP = npoints;  % poèet vzorkù polynomu
nP = npolynomials;

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

c = zeros(1, nP);
for I = 1: nP
    c(1, I) = y * B(I, :).' / lP * ((I-1)*2+1);
    % koeficient ((I-1)*2+1) odpovídá výkonùm komponent, které lze spoèítat i takto: mean((P.^2).')
end
