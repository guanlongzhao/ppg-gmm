% spec2mcep: Mel-Cepstral Analysis, convert spectral envelope to
% mel-cepstrum. Re-coded from SPTK's mcep function (release v3.10), the
% only difference between the C version and the Matlab version is that the
% Matlab version uses its built-in fft and ifft functions.
%
% Syntax: mc = spec2mcep(sp, alpha, ncep, itr1, itr2, dd, f)
%
% Inputs:
%   sp: spectrums, in |H(z)|^2 format, e.g., STRAIGHT spectrums, D*T matrix
%
%   alpha: all-pass constant. Default to [0.35].
%   Suggested values for different sampling rates: 48kHz-0.554, 
%   44.1kHz-0.544, 16kHz-0.42, 10kHz-0.35, 8kHz-0.31. By making these 
%   choices for alpha, the mel-scale becomes a good approximation to the 
%   human sensitivity to the loudness of speech. There are ways to compute 
%   alpha value for a sampling rate, refer to 
%   https://bitbucket.org/happyalu/mcep_alpha_calc
%   or
%   https://github.com/r9y9/MCepAlpha.jl/blob/master/src/MCepAlpha.jl
%   for more information.
%
%   ncep: number of cepstral components. Default to [24].
%   Be aware that this number does not include the energy component, 
%   therefore the output MCEP will have (ncep+1) dims, the first dim is the
%   energy. This is the convention followed by SPTK. 
%
%   itr1: minimum number of iteration in Newton Raphson method. Default to
%   [2]
%
%   itr2: maximum number of iteration in Newton Raphson method. Default to
%   [30]
%
%   dd: early stopping criterion for Newton Raphson method. Default to
%   [0.001]
%
%   f: minimum value of the determinant of the normal matrix, used in
%   theq(). Default to [0.000001]
%
% Outputs:
%   mc: mel-cepstrums, a (ncep+1)*T matrix
%
% Other files required: freqt.mexw64 (freqt.c), frqtr.mexw64 (frqtr.c),
% theq.mexw64 (theq.c)
%
% Subfunctions: spec2mcepSingleFrame()
%
% MAT-file required: None
%
% Author: Guanlong Zhao
% Email: gzhao@tamu.edu
% Created: 06/09/2017; Last revision: 06/09/2017
% Revision log:
%   06/09/2017: function creation, Guanlong Zhao

% Copyright 2019 Guanlong Zhao
% 
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
%     http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

function mc = spec2mcep(sp, alpha, ncep, itr1, itr2, dd, f)
    if nargin < 7
        f = 0.000001;
    end
    if nargin < 6
        dd = 0.001;
    end
    if nargin < 5
        itr2 = 30;
    end
    if nargin < 4
        itr1 = 2;
    end
    if nargin < 3
        ncep = 24;
    end
    if nargin < 2
        alpha = 0.35;
    end

    [d_spec, frames] = size(sp);
    flng = (d_spec-1)*2; % the FFT length used for extracting the spectrums
    mc = zeros(ncep+1, frames);

    for ii = 1:frames
        mc(:, ii) = spec2mcepSingleFrame(sp(:, ii), flng, ncep, alpha, itr1, itr2, dd, f);
    end

    % do the computation frame-by frame, because Newton Raphson method is
    % operated in a frame-wise fashion.
    function mc = spec2mcepSingleFrame(xw, flng, m, a, itr1, itr2, dd, f)
        D = size(xw, 1);
        x = zeros(flng, 1);
        d = zeros(m+1, 1);
        al = d;
        flag = 0;

        f2 = flng / 2;
        m2 = 2*m;

        x(1:D) = xw+eps;

        % do a mirroring
        for i = 2:flng/2
            x(flng - i + 2) = x(i);
        end

        assert(sum(x<=0)==0, 'Error: spectrum should be positive!');
        
        % spectrum -> log spectrum
        c = log(x);

        % 1, (-a), (-a)^2, ..., (-a)^M
        al(1) = 1;
        for i = 2:(m+1)
          al(i) = -a * al(i - 1);
        end

        % initial value of cepstrum
        temp = ifft(c, flng);
        c = real(temp); % c: IFFT(x)
        c(1) = c(1)/2.0;
        c(f2+1) = c(f2+1)/2.0;
        mc = freqt(c(1:D), m, a); % mc: mel cep
        s = c(1);

        % Newton Raphson method
        for j = 1:itr2
            c = freqt(mc, f2, -a); % mc: mel cep
            temp = fft(c, flng); % c, y: FFT[mc]
            c = real(temp);
            c = x ./ exp(2*c);
            temp = ifft(c, flng);
            c = real(temp); % c: IFFT(x)
            y = imag(temp);
            c = frqtr(c, m2, a); % c: r(k)

            t = c(1);
            if j >= itr1
                if abs((t - s) / t) < dd
                    flag = 1;
                end
                s = t;
            end

            b = c(1:(m+1))-al;
            y(1:(m2+1)) = c(1:(m2+1));
            for i = 1:2:(m2+1)
                y(i) = y(i) - c(1);
            end

            for i = 3:2:(m+1)
                c(i) = c(i) + c(1);
            end
            c(1) = 2*c(1);

            nn = m+1;
            d = theq(c(1:nn), y(1:(2*nn-1)), b(1:nn), nn, f);

            mc = mc+d;
            if (flag)
                return;
            end
        end
    end
end