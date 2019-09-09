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

%% Setup inputs
% The root output folder of this run
outputDir = 'OUTPUT_PATH';
% The dir of the native (source) training wave files
srcTrainingRecordingsDir = 'SRC_RECORDINGS_PATH';
% The path to the native training prompts; txt; one utterance per line
srcTrainingTransFile = 'SRC_TRAINING_TRANSCRIPTION_FILE';
% The dir of the native (source) testing wave files
srcTestingRecordingsDir = 'SRC_TESTING_RECORDINGS_PATH';
% The path to the native testing prompts; txt; one utterance per line
srcTestingTransFile = 'SRC_TESTING_TRANSCRIPTION_FILE';
% The dir of the non-native (target) training wave files
tgtTrainingRecordingsDir = 'TGT_RECORDINGS_PATH';
% The path to the non-native training prompts; txt; one utterance per line
tgtTrainingTransFile = 'TGT_TRAINING_TRANSCRIPTION_FILE';
%% End setup


% The output path of the accent conversion audio files
acDir = fullfile(outputDir, 'ac_syntheses');
% Save the spectral conversion model
gmmMdlPath = fullfile(outputDir, 'ppg_gmm_mdl.mat');

% Native (source) speaker specific files
srcTrainingRecordings = dir(fullfile(srcTrainingRecordingsDir, '*.wav'));
numSrcTrainingWavs = length(srcTrainingRecordings);
srcTrainingWavList = cell(numSrcTrainingWavs, 1);
for ii = 1:numSrcTrainingWavs
    srcTrainingWavList{ii} = fullfile(srcTrainingRecordingsDir,...
        srcTrainingRecordings(ii).name);
end
srcTrainingCacheDir = fullfile(outputDir, 'src_train_cache');
% Get the testing files
srcTestingRecordings = dir(fullfile(srcTestingRecordingsDir, '*.wav'));
numSrcTestingWavs = length(srcTestingRecordings);
srcTestingWavList = cell(numSrcTestingWavs, 1);
for ii = 1:numSrcTestingWavs
    srcTestingWavList{ii} = fullfile(srcTestingRecordingsDir,...
        srcTestingRecordings(ii).name);
end
srcTestingCacheDir = fullfile(outputDir, 'src_test_cache');
srcPitchMdlPath = fullfile(outputDir, 'src_pitch_mdl.mat');

% Non-native (target) speaker specific files
tgtTrainingRecordings = dir(fullfile(tgtTrainingRecordingsDir, '*.wav'));
numTgtTrainingWavs = length(tgtTrainingRecordings);
tgtTrainingWavList = cell(numTgtTrainingWavs, 1);
for ii = 1:numTgtTrainingWavs
    tgtTrainingWavList{ii} = fullfile(tgtTrainingRecordingsDir,...
        tgtTrainingRecordings(ii).name);
end
tgtTrainingCacheDir = fullfile(outputDir, 'tgt_train_cache');
tgtPitchMdlPath = fullfile(outputDir,...
    'tgt_pitch_mdl.mat');

% Clean up previous run
if exist(outputDir, 'dir')
    rmdir(outputDir, 's');
end


%% Run the conversion
% 1. Get all utt files for the source and target
srcMatList = dataPrep(srcTrainingWavList, srcTrainingTransFile,...
    srcTrainingCacheDir, 'NumWorkers', 8);
tgtMatList = dataPrep(tgtTrainingWavList, tgtTrainingTransFile,...
    tgtTrainingCacheDir, 'NumWorkers', 8);

% 2. Train PPG-GMM model
[gmmMdlPath, gmmStatus] = buildGMMmodelGSB(srcMatList, tgtMatList,...
    gmmMdlPath);

% 3. Get pitch models
[srcPitchMdlPath, srcPitchStatus] = buildPitchModelGSB(srcMatList,...
    srcPitchMdlPath, 'Mode', 'heq');

[tgtPitchMdlPath, tgtPitchStatus] = buildPitchModelGSB(tgtMatList,...
    tgtPitchMdlPath, 'Mode', 'heq');

% 4. Perform accent conversion
testUtts = dataPrep(srcTestingWavList, srcTestingTransFile,...
    srcTestingCacheDir, 'NumWorkers', 8);
[wavFiles, acStatus] = voiceConversionInterfaceGSB(testUtts,...
    gmmMdlPath, srcPitchMdlPath, tgtPitchMdlPath, acDir, 'NumWorkers', 8);