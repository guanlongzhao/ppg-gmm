% voiceConversionInterfaceGSB: interface for converting a list of test
% utterances.
%
% Syntax: [wavFiles, status] = voiceConversionInterfaceGSB(uttFiles, gmmPath, srcPitchPath, tgtPitchPath, outputPath)
%
% Inputs:
%   uttFiles: A cell array. Each element is the path to a mat file that
%   contains the utt struct you would like to convert.
%   gmmPath: A string. Path to the PPG-GMM model.
%   srcPitchPath: A string. Path to the source pitch model.
%   tgtPitchPath: A string. Path to the target pitch model.
%   outputPath: A string. The function assumes that 'outputPath' is the
%   output dir, and all output wav files will be saved to that dir, and
%   their name will be the same as their corresponding mat file.
%
%   [Optional name-value pairs]
%   'SpecCov': 'MLGV' (*) | 'MMSE' | 'MLPG'
%   'NumWorkers': An interger. How many parallel workers to use. Default to
%   0, which tells Matlab not to run parallel computing. Should not be
%   larger than the maximum number defined by your 'local' cluster config,
%   which is usually the number of logical cores on your machine. If your
%   input contains only one utterance, then no matter how many workers you
%   specified, the function will use only one worker. If your input
%   utterance number is smaller than the workers requested, the function
%   will only load the needed number of workers
%
% Outputs:
%   wavFiles: A cell array. Each element is a path to a wav file, which is
%   the accent-converted version of the corresponding mat file
%   status: 1 for success
%
% Other m-files required: tryCreateDir, voiceConversionGSB, loadUttGSB
%
% Subfunctions: None
%
% MAT-file required: None
%
% Author: Guanlong Zhao
% Email: gzhao@tamu.edu
% Created: 10/23/2018; Last revision: 12/07/2018
% Revision log:
%   10/23/2018: function creation, Guanlong Zhao
%   10/24/2018: add parallel computing support, GZ
%   11/14/2018: fix a bug that will prevent the function from loading a
%   parpool, GZ
%   12/07/2018: fix a weird assumption, GZ

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

function [wavFiles, status] = voiceConversionInterfaceGSB(uttFiles, gmmPath, srcPitchPath, tgtPitchPath, outputPath, varargin)
    % Parameters
    p = inputParser;
    addRequired(p, 'uttFiles', @iscellstr);
    addRequired(p, 'gmmPath', @ischar);
    addRequired(p, 'srcPitchPath', @ischar);
    addRequired(p, 'tgtPitchPath', @ischar);
    addRequired(p, 'outputPath', @ischar);
    addParameter(p, 'SpecCov', 'MLGV', @(x) ismember(x,...
        {'MLGV', 'MLPG', 'MMSE'}));
    % Number of parallel workers, set to 0 for serial mode
    defaultNumWorkers = 0;
    clusterPar = parcluster('local');
    maxWorkers = clusterPar.NumWorkers;
    addParameter(p, 'NumWorkers', defaultNumWorkers,...
        @(x) x>=0 && x<=maxWorkers);
    parse(p, uttFiles, gmmPath, srcPitchPath, tgtPitchPath, outputPath,...
        varargin{:});
    specCov = p.Results.SpecCov;
    numWorkers = p.Results.NumWorkers;
    status = 0;
    numUtts = length(uttFiles);
    wavFiles = cell(numUtts, 1);
    
    % Prepare and validate output path
    if ~exist(outputPath, 'dir')
        tryCreateDir(outputPath);
    end
    
    % Load model files
    gmmMdl = load(gmmPath);
    srcPitchMdl = load(srcPitchPath);
    tgtPitchMdl = load(tgtPitchPath);
    
    % Setup parallel computing
    % Disable parallel computing if only one utterances
    % Use less workers if we do not need that many
    if numUtts == 1
        numWorkers = 0;
    elseif numUtts < numWorkers
        warning('Do not need %d workers, load %d workers instead.',...
            numWorkers, numUtts);
        numWorkers = numUtts;
    end
    
    % Perform conversion
    parfor (ii = 1:numUtts, numWorkers)
        utt = loadUttGSB(uttFiles(ii), 'RegExp', '^(?!post)\w');
        covUtt = voiceConversionGSB(utt, gmmMdl, srcPitchMdl,...
            tgtPitchMdl, 'SpecCov', specCov);
        
        % Each output file's name is the same as the corresponding mat file
        [uttDir, uttName, uttExt] = fileparts(uttFiles{ii});
        outputFile = fullfile(outputPath, sprintf('%s.wav', uttName));
        audiowrite(outputFile, covUtt.wav, covUtt.fs);
        wavFiles{ii} = outputFile;
    end
    status = 1;
end
