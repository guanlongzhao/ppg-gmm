% buildGMMmodelGSB: build a GMM model using PPGs for frame-pairing.
%
% Syntax: [modelPath, status] = buildGMMmodelGSB(srcSpkrFiles, tgtSpkrFiles, modelPath)
%
% Inputs:
%   srcSpkrFiles: A cell array. Each element is a path to a mat file from
%   the source speaker.
%   tgtSpkrFiles: A cell array. Each element is a path to a mat file from
%   the target speaker.
%   modelPath: A string. Path to where you want to save the model, will
%   overwrite the existing file.
%
%   [Optional name-value pairs]
%   'NumMixtures': GMM components, default to 32
%   'CovType': type of covariance matrix, default to 'diag', refer to gmm()
%   in netlab for more details
%   'NumIter': number of iterations of the EM, default to 35
%   'CheckCov': 1 (*) | 0, set to '1' if a covariance matrix is reset to 
%   its original value when any of its singular values are too small (less 
%   than MIN_COVAR which has the value eps). With '0' no action is taken.
%   'Epsilon': early stopping criteria, default is 1e-4
%   'Verbose': 1 (*) | 0, set to '1' to get some printouts
%   'SplitSize': number of frames in a batch, default as 3000 frames. if
%   the input is less than 3000 frames then run in a single batch. This is
%   used in the frame-pairing part to avoid out-of-memory issues.
%   'MaxRetry': sometimes the GMM training will diverge, and this may
%   happen for various reasons, e.g., the source and target speakers have
%   drastically different amount of data; the model is too big for the
%   amount of data available; there are too many iterations, etc. This
%   option allows the function to check after the training, if the model
%   diverges, then it will retry with a new initialization. The default
%   maximum retry count is '3'
%
% Outputs:
%   modelPath: path to the trained model
%   status: status flag. '1' for success and '0' for failure.
%
% Other m-files required: tryCreateDir, loadUttGSB, prepareDataGMM,
% framePairingPPG, calculateGlobalVar, trySaveStructFields, netlab files
%
% Subfunctions: None
%
% MAT-file required: None
%
% Author: Guanlong Zhao
% Email: gzhao@tamu.edu
% Created: 10/19/2018; Last revision: 10/24/2018
% Revision log:
%   10/19/2018: function creation, Guanlong Zhao
%   10/23/2018: change to let the user specify the output path, GZ
%   10/24/2018: fixed a bug and add validation for input type, GZ

% Copyright 2018 Guanlong Zhao
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

function [modelPath, status] = buildGMMmodelGSB(srcSpkrFiles, tgtSpkrFiles, modelPath, varargin)
    % Input parser
    p = inputParser;
    addRequired(p, 'srcSpkrFiles', @iscellstr);
    addRequired(p, 'tgtSpkrFiles', @iscellstr);
    addRequired(p, 'modelPath', @ischar);
    addParameter(p, 'NumMixtures', 32, @isnumeric);
    addParameter(p, 'CovType', 'diag', @(x) ismember(x, {'diag', 'full'}));
    addParameter(p, 'NumIter', 35, @isnumeric);
    addParameter(p, 'CheckCov', 1, @isnumeric);
    addParameter(p, 'Epsilon', 1e-4, @isnumeric);
    addParameter(p, 'Verbose', 1, @isnumeric);
    addParameter(p, 'SplitSize', 3e3, @isnumeric);
    addParameter(p, 'MaxRetry', 3, @isnumeric);
    parse(p, srcSpkrFiles, tgtSpkrFiles, modelPath, varargin{:});
    nMix = p.Results.NumMixtures; % # of Gaussian mixtures
    covType = p.Results.CovType; % Cov type for the GMMs
    nIter = p.Results.NumIter; % # iterations for GMM training
    isCheckCov = p.Results.CheckCov; % See docstring
    epsilon = p.Results.Epsilon; % Early stopping criteria
    isVerbose = p.Results.Verbose; % See docstring
    gmmOptions = foptions_netlab;
    gmmOptions(1) = isVerbose;
    gmmOptions(3) = epsilon;
    gmmOptions(5) = isCheckCov;
    gmmOptions(14) = nIter;
    splitSize = p.Results.SplitSize; % See doc string
    maxRetry = p.Results.MaxRetry; % See doc string
    status = 0;
    
    % Load training data
    srcUtts = loadUttGSB(srcSpkrFiles); % struct
    tgtUtts = loadUttGSB(tgtSpkrFiles); % struct
    
    % Convert raw data to training ready format
    [concSrcMcep, srcPost] = prepareDataGMM(srcUtts);
    [concTgtMcep, tgtPost] = prepareDataGMM(tgtUtts);
    
    % Perform PPG-based frame pairing
    [mapToSrc, mapToTgt] = framePairingPPG(srcPost, tgtPost, splitSize,...
        true);
    
    % Get the training acoustics
    srcMcep = [concSrcMcep'; concSrcMcep(:, mapToTgt)'];
    tgtMcep = [concTgtMcep(:, mapToSrc)'; concTgtMcep'];
    
    % Get GV
    fprintf('Calculating global variance...\n')
    tgtGVs = calculateGlobalVar(tgtUtts, 2:25, 'mcep');
    fprintf('Calculating global variance finished.\n')

    % Training GMM, will retry if failes
    fprintf('Training a GMM model for spectral conversion...\n')
    feats = [srcMcep, tgtMcep];
    isTrainModelSucceed = false;
    for ii = 1:maxRetry
        dim = size(srcMcep, 2) + size(tgtMcep, 2);
        mix = gmm(dim, nMix, covType);
        mix = gmminit(mix, feats, gmmOptions);
        [mix, gmmOptions, errlog] = gmmem(mix, feats, gmmOptions);
        if sum(isnan(errlog)) == 0
            isTrainModelSucceed = true;
            status = 1;
            break
        end
        if ii > 1
            fprtinf('Model training diverged, retry #%d\n', ii-1);
        end
    end
    if ~isTrainModelSucceed
        fprintf(['Reached maximum retry counts (%d), model still does not ',...
            'converge, try decreasing the number of GMMs and iterations, ',...
            'also check your data, the two speakers should have comparable ',...
            'amount of data.'], maxRetry);
        modelPath = '';
        status = 0;
        return
    end
    fprintf('Training GMM model finished.\n')

    % Construct model struct
    fprintf('Compiling spectral conversion model...\n')
    model = struct;
    model.mix = mix;
    model.targetGVs = tgtGVs;
    model.options = gmmOptions;
    model.errlog = errlog;
    model.srcUtts = srcSpkrFiles;
    model.tgtUtts = tgtSpkrFiles;
    model.procedure = 'buildGmmModelGSB';
    model.timestamp = datestr(clock, 30);
    model.status = status;
    
    % Save the model
    status = trySaveStructFields(model, modelPath);
    fprintf('Compiling spectral conversion model finished.\n')
end