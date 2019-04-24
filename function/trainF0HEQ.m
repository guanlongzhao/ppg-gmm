% trainF0HEQ: implement the histogram equlization post-filtering proposed
%  by Wu et al. in paper "Text-Independent F0 Transformation with
%  Non-Parallel Data for Voice Conversion." This function learns the F0
%  parameters from one speaker
%
% Syntax: params = trainF0HEQ(f0raw[, vis])
%
% Inputs:
%   f0raw: F0 sequence from one speaker, a N*1 vector
%   vis: 1 | 0 (default), 1 - plot histogram, 0 - not plot
%
% Outputs:
%   params: parameters needed to model a speaker's pitch identity, struct
%       - data: the input data for building the model
%       - xMin: the minimum non-zero pitch, scalar
%       - xMax: the maximum pitch, scalar
%       - numBins: number of bins in the histogram, scalar
%       - bins: the histogram bins, (numBins+1)*1 vector
%       - freq: the frequency of each bin
%       - cdf: the cumulative distribution function (CDF)
%       - eqProbEdges: chop the CDF with equal increments
%
% Other m-files required: None
%
% Subfunctions: None
%
% MAT-file required: None
%
% Author: Guanlong Zhao
% Email: gzhao@tamu.edu
% Created: 03/27/2017; Last revision: 04/23/2019
% Revision log:
%   03/27/2017: function creation, Guanlong Zhao
%   03/28/2017: bug fixes, Guanlong Zhao
%   04/01/2017: handel outliers differently, Guanlong Zhao
%   09/07/2017: fixed a bug, Guanlong Zhao
%   10/15/2018: treat everything outside of 2 stds (95%) as outlier, GZ
%   04/23/2019: fix docs, GZ

% Copyright 2017 Guanlong Zhao
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

function params = trainF0HEQ(f0raw, vis)
    if nargin < 2
        vis = 0;
    end

    % Filter out zeros in pitch and get rid of outliers
    % 2 std -> 95%
    f0_pos = f0raw(f0raw>0);
    f0_mean = mean(f0_pos);
    f0_std = std(f0_pos);
    valid_idx = (f0_pos>(f0_mean-2*f0_std)) & (f0_pos<(f0_mean+2*f0_std));
    f0 = f0_pos(valid_idx);
    
    % Build the histogram
    numBins = 100; % from the reference
    xMin = min(f0);
    xMax = max(f0);
    
    if vis
        figure;
        h = histogram(f0, numBins, 'BinLimits', [xMin, xMax], ...
        'Normalization', 'probability'); % visualization
        bins = h.BinEdges;
        freq = h.Values;
    else
        [freq, bins] = histcounts(f0, numBins, 'BinLimits', [xMin, xMax], ...
        'Normalization', 'probability');
    end
    
    % Get the values we want
    cdf = cumsum(freq);
    perCt = 1/numBins:1/numBins:(1-1/numBins);
    distPerCt = pdist2(perCt', cdf');
    [v, eqProbBins] = min(distPerCt, [], 2);
    eqProbEdges = [bins(1), bins(eqProbBins), bins(end)];
    
    % Construct the output struct
    params.data = f0raw;
    params.xMin = xMin;
    params.xMax = xMax;
    params.numBins = numBins;
    params.bins = bins;
    params.freq = freq;
    params.cdf = cdf;
    params.eqProbEdges = eqProbEdges;
end