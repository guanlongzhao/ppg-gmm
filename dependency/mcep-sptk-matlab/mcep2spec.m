% mcep2spec: Mel-Cepstral Analysis, convert mel-cepstrum to spectral 
% envelope. Re-coded from SPTK's mgc2sp function (release v3.10). It calls
% the mex version of the modified C function, so the performance should be
% almost the same as the original binary.
%
% Syntax: sp = mcep2spec(mc, alpha, nfreq)
%
% Inputs:
%   mc: mel-cepstrums, D*T matrix
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
%   nfreq: number of frequency point of the output spectrogram. Default to
%   [513]
%
% Outputs:
%   sp: spectrums, in |H(z)|^2 format, e.g., STRAIGHT spectrums, a nfreq*T
%   matrix
%
% Other files required: mexmcep2spec.mexw64 (mexmcep2spec.c)
%
% Subfunctions: None
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

function sp = mcep2spec(mc, alpha, nfreq)
    if nargin < 3
        nfreq = 513;
    end
    if nargin < 2
        alpha = 0.35;
    end

    [D, T] = size(mc);
    sp = zeros(nfreq, T);

    for tt = 1:T
        sp(:, tt) = mexmcep2spec(mc(:, tt), alpha, nfreq);
    end
end