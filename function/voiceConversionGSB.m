% voiceConversionGSB: a generic voice conversion function for GMM, requires
% a joint spectral model and two separate pitch models
%
% Syntax: covUtt = voiceConversionGSB(utt, gmmMdl, srcPitchMdl, tgtPitchMdl)
%
% Inputs:
%   utt: the source utt to be converted
%   gmmMdl: the joint GMM spectral model
%   srcPitchMdl: source pitch model
%   tgtPitchMdl: target pitch model
%
%   Name-value pairs:
%   'SpecCov': 'MLGV' (*) | 'MMSE' | 'MLPG'
%
% Outputs:
%   covUtt: converted utterance
%   status: 1 for success
%
% Other m-files required: pitchConversion, spectralMapping_MLTrajGV,
% spectralMapping_MMSE, mcep2spec, straight2mfcc, speechSynthesis,
% static2dynamic
%
% Subfunctions: None
%
% MAT-file required: None
%
% Author: Guanlong Zhao
% Email: gzhao@tamu.edu
% Created: 04/25/2017; Last revision: 10/24/2018
% Revision log:
%   04/25/2017: function creation, Guanlong Zhao
%   05/10/2017: added doc, GZ
%   05/15/2017: fixed a bug related to MMSE estimation, removed hard-coded
%   mfcc dim, GZ
%   05/17/2017: (temporarily) handle models using dynamic features, GZ
%   05/18/2017: minor optimization, GZ
%   06/02/2017: now able to use GMM models trained on MCEP features, added
%   a little bit more doc, GZ
%   06/05/2017: refined MCEP option, GZ
%   06/12/2017: refined MCEP option again, GZ
%   06/21/2017: be able to use pre-cached mcep, GZ
%   06/27/2017: the output now have the converted mfcc & mcep, GZ
%   06/30/2017: be able to use GMM models that include AP and F0, GZ
%   09/12/2017: added 'MLPG' mode, GZ
%   10/23/2018: change to GSB version, GZ
%   10/24/2018: add missing dependency, GZ

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

function [covUtt, status] = voiceConversionGSB(utt, gmmMdl, srcPitchMdl, tgtPitchMdl, varargin)
    p = inputParser;
    addRequired(p, 'utt');
    addRequired(p, 'gmmMdl');
    addRequired(p, 'srcPitchMdl');
    addRequired(p, 'tgtPitchMdl');
    addParameter(p, 'SpecCov', 'MLGV', @(x) ismember(x,...
        {'MLGV', 'MLPG', 'MMSE'}));
    parse(p, utt, gmmMdl, srcPitchMdl, tgtPitchMdl, varargin{:});
    specCov = p.Results.SpecCov;
    status = 0;
    
    % Deal with the source signal, AP is just copied from utt
    % Pitch scaling and copy AP
    covUtt = pitchConversion(utt, srcPitchMdl, tgtPitchMdl);
    
    % Spectral conversion
    % Prepare input data
    mcepDim = size(utt.mcep, 1);
    testMcep = transpose(static2dynamic(utt.mcep));
    testMcep = testMcep(:, [2:mcepDim, (mcepDim+2):2*mcepDim]);
    lab = utt.lab;
    nonSilentFrames = find(~isnan(lab));
    % Perform conversion
    switch specCov
        case 'MLGV'
            % Perform MLPG & GV, output is D*T
            estMcep = spectralMapping_MLTrajGV(testMcep,...
                gmmMdl.mix, gmmMdl.targetGVs, nonSilentFrames);
        case 'MMSE'
            % Minimize mean-square-error
            estMcep = spectralMapping_MMSE(testMcep, gmmMdl.mix);
        case 'MLPG'
            % Perform MLPG, output is D*T
            estMcep = spectralMapping_MLPG(testMcep, gmmMdl.mix);
        otherwise
            error('Wrong spectral conversion method!');
    end
    % Compile results, ignore conversion performed on silent segments
    estMcepFinal = utt.mcep;
    estMcepFinal(2:mcepDim, nonSilentFrames) = estMcep(1:(mcepDim-1), nonSilentFrames);
    estMcep = estMcepFinal;

    % Cepstrum -> power spectrum
    covSpec = mcep2spec(estMcep(1:mcepDim, :), utt.alpha, size(utt.spec, 1));
    covUtt.mcep = estMcep(1:mcepDim, :);
    covUtt.mfcc = straight2mfcc(covSpec, covUtt.fs, size(covUtt.mfcc, 1));
    covSpec(covSpec == 0) = eps; % safe guard

    % Re-synthesis
    covUtt.spec = covSpec;
    if strcmp(utt.vocoder, 'WORLD')
        covUtt.filter.spectrogram = covSpec;
    end
    covUtt = speechSynthesis(covUtt);
    status = 1;
end