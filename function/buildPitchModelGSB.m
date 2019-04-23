% buildPitchModelGSB: build a pitch model using the given utterances.
%
% Syntax: [modelPath, status] = buildPitchModelGSB(spkrFiles, modelPath)
%
% Inputs:
%   spkrFiles: A cell array. Each element is a path to a mat file from a
%   speaker.
%   modelPath: A string. Path to where you want to save the model, will
%   overwrite the existing file.
%
%   [Optional name-value pairs]
%   'Mode': 'heq' (*) | 'log'; 'log' mode builds the model using the
%   log-scale mean and variance normalization. 'heq' mode builds the model
%   using f0 histogram equalization.
%
% Outputs:
%   modelPath: path to the trained model
%   status: status flag. '1' for success and '0' for failure.
%
% Other m-files required: trainF0HEQ, loadUttGSB, trySaveStructFields
%
% Subfunctions: None
%
% MAT-file required: None
%
% Author: Guanlong Zhao
% Email: gzhao@tamu.edu
% Created: 04/24/2017; Last revision: 10/24/2018
% Revision log:
%   04/24/2017: function creation, Guanlong Zhao
%   07/03/2017: added mode 'hertz', GZ
%   09/12/2018: added support for customized input file prefix, GZ
%   10/01/2018: make the input parsing better, GZ
%   10/02/2018: filter abnormal F0 values, GZ
%   10/23/2018: change for GSB server, GZ
%   10/24/2018: refine input validation, GZ

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

function [modelPath, status] = buildPitchModelGSB(spkrFiles, modelPath, varargin)
    % Input parser
    p = inputParser;
    addRequired(p, 'spkrFiles', @iscellstr);
    addRequired(p, 'modelPath', @ischar);
    addParameter(p, 'Mode', 'heq', @(x) ismember(x, {'heq', 'log'}));
    parse(p, spkrFiles, modelPath, varargin{:});
    mode = p.Results.Mode;
    status = 0;
    
    % Get training data
    [utts, invalidIdx] = loadUttGSB(spkrFiles, 'VarList', {'source'});
    if isempty(utts)
        disp('No valid training data!');
        modelPath = '';
        return
    end
    rawdata = [];
    for ii = 1:length(utts)
        % Ignore unvoiced
        validF0s = utts(ii).source.f0(logical(utts(ii).source.vuv));
        validF0s = reshape(validF0s, length(validF0s), 1);
        rawdata = [rawdata; validF0s];
    end
    
    % Simple thresholding; Titze, I.R. (1994). Principles of Voice
    % Production, Prentice Hall (currently published by NCVS.org) (pp. 188)
    rawdata = rawdata(rawdata>40 & rawdata<400);
    
    % Construct the pitch model
    model = struct;
    switch mode
        case 'log'
            model.data = rawdata;
            logdata = log(rawdata(rawdata>0)); % ignore 0
            model.logmean = mean(logdata);
            model.logstd = std(logdata);
        case 'heq'    
            model = trainF0HEQ(rawdata);
        otherwise
            error('Mode %s not supported!', mode);
    end
    model.utts = spkrFiles;
    model.utts(invalidIdx) = []; % delete utt indices that do not exist
    model.mode = mode;
    model.procedure = 'buildPitchModelGSB';
    model.timestamp = datestr(clock, 30);
    
    % Save the pitch model
    status = trySaveStructFields(model, modelPath);
end