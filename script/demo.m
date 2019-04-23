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

% Run the PPG-GMM system end-to-end
% From raw speech and text to accent-converted speech

%% Setup files
% Common settings
currDir = pwd;
parentDir = fileparts(currDir);
% Where we store audio files, '../test/data'
rootDir = fullfile(parentDir, 'test/data');
% Output folder of this run, '../test/data/temp/demo'
outputDir = fullfile(rootDir, 'temp/demo');
% Find the synthesis outputs here, '../test/data/temp/demo/ac_syntheses'
acDir = fullfile(outputDir, 'ac_syntheses');
% Cached spectral conversion model
gmmMdlPath = fullfile(outputDir, 'ppg_gmm_mdl.mat');
% Utterances for training
trainSet = 1:30;
% Utterances for testing
testSet = 31:40;

% Native (source) speaker specific files
srcRecordings = dir(fullfile(rootDir, 'src/recordings/*.wav'));
numSrcWavs = length(srcRecordings);
srcWavList = cell(numSrcWavs, 1);
for ii = 1:numSrcWavs
    srcWavList{ii} = fullfile(rootDir, 'src/recordings',...
        srcRecordings(ii).name);
end
srcTransFile = fullfile(rootDir, 'src/prompts.txt'); % Text transcripts
srcCacheDir = fullfile(outputDir, 'src_cache');
srcPitchMdlPath = fullfile(outputDir, 'src_pitch_mdl.mat');

% Non-native (target) speaker specific files
tgtRecordings = dir(fullfile(rootDir, 'tgt/recordings/*.wav'));
numTgtWavs = length(tgtRecordings);
tgtWavList = cell(numTgtWavs, 1);
for ii = 1:numTgtWavs
    tgtWavList{ii} = fullfile(rootDir, 'tgt/recordings',...
        tgtRecordings(ii).name);
end
tgtTransFile = fullfile(rootDir, 'tgt/prompts.txt');
tgtCacheDir = fullfile(outputDir, 'tgt_cache');
tgtPitchMdlPath = fullfile(outputDir,...
    'tgt_pitch_mdl.mat');

% Clean up previous run
if exist(outputDir, 'dir')
    rmdir(outputDir, 's');
end


%% Run the conversion
% 1. Get all utt files for the source and target
srcMatList = dataPrep(srcWavList, srcTransFile, srcCacheDir,...
    'NumWorkers', 8);
tgtMatList = dataPrep(tgtWavList, tgtTransFile, tgtCacheDir,...
    'NumWorkers', 8);

% 2. Train PPG-GMM model
srcTrainSet = srcMatList(trainSet);
tgtTrainSet = tgtMatList(trainSet);
[gmmMdlPath, gmmStatus] = buildGMMmodelGSB(srcTrainSet, tgtTrainSet,...
    gmmMdlPath);

% 3. Get pitch models
[srcPitchMdlPath, srcPitchStatus] = buildPitchModelGSB(srcTrainSet,...
    srcPitchMdlPath, 'Mode', 'heq');

[tgtPitchMdlPath, tgtPitchStatus] = buildPitchModelGSB(tgtTrainSet,...
    tgtPitchMdlPath, 'Mode', 'heq');

% 4. Perform accent conversion
testUtts = srcMatList(testSet);
[wavFiles, acStatus] = voiceConversionInterfaceGSB(testUtts,...
    gmmMdlPath, srcPitchMdlPath, tgtPitchMdlPath, acDir, 'NumWorkers', 8);