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

% Test the PPG-GMM system end-to-end
% From raw speech and text to accent-converted speech

function tests = ppgGmmEndToEndTest
    tests = functiontests(localfunctions);
end

function setup(testCase)
    currDir = pwd;
    rootDir = fullfile(currDir, 'data');
    outputDir = fullfile(rootDir, 'temp/end_to_end_test');
    
    srcRecordings = dir(fullfile(rootDir, 'src/recordings/*.wav'));
    numSrcWavs = length(srcRecordings);
    srcWavList = cell(numSrcWavs, 1);
    srcEndTime = zeros(numSrcWavs, 1);
    for ii = 1:numSrcWavs
        srcWavList{ii} = fullfile(rootDir, 'src/recordings',...
            srcRecordings(ii).name);
        [wav, fs] = audioread(srcWavList{ii});
        audioLength = length(wav)/fs;
        srcEndTime(ii) = audioLength - 0.01;
    end
    
    tgtRecordings = dir(fullfile(rootDir, 'tgt/recordings/*.wav'));
    numTgtWavs = length(tgtRecordings);
    tgtWavList = cell(numTgtWavs, 1);
    tgtEndTime = zeros(numTgtWavs, 1);
    for ii = 1:numTgtWavs
        tgtWavList{ii} = fullfile(rootDir, 'tgt/recordings',...
            tgtRecordings(ii).name);
        [wav, fs] = audioread(tgtWavList{ii});
        audioLength = length(wav)/fs;
        tgtEndTime(ii) = audioLength - 0.01;
    end
    
    % Source speaker specific fixtures
    testCase.TestData.srcWavList = srcWavList;
    testCase.TestData.numSrcWavs = numSrcWavs;
    testCase.TestData.srcTransFile = fullfile(rootDir, 'src/prompts.txt');
    testCase.TestData.srcCacheDir = fullfile(outputDir, 'src_cache');
    testCase.TestData.srcStartTime = 0.01 * ones(numSrcWavs, 1);
    testCase.TestData.srcEndTime = srcEndTime;
    testCase.TestData.srcPitchMdlPath = fullfile(outputDir,...
        'src_pitch_mdl.mat');
    
    % Target speaker specific fixtures
    testCase.TestData.tgtWavList = tgtWavList;
    testCase.TestData.numTgtWavs = numTgtWavs;
    testCase.TestData.tgtTransFile = fullfile(rootDir, 'tgt/prompts.txt');
    testCase.TestData.tgtCacheDir = fullfile(outputDir, 'tgt_cache');
    testCase.TestData.tgtStartTime = 0.01 * ones(numTgtWavs, 1);
    testCase.TestData.tgtEndTime = tgtEndTime;
    testCase.TestData.tgtPitchMdlPath = fullfile(outputDir,...
        'tgt_pitch_mdl.mat');
    
    % Common fixtures
    testCase.TestData.acDir = fullfile(outputDir, 'ac_syntheses');
    testCase.TestData.gmmMdlPath = fullfile(outputDir, 'ppg_gmm_mdl.mat');
    testCase.TestData.trainSet = 1:30;
    testCase.TestData.testSet = 31:40;
    testCase.TestData.outputDir = outputDir;
    
    % Prepare temp output dir
    if exist(testCase.TestData.outputDir, 'dir')
        rmdir(testCase.TestData.outputDir, 's');
    end
end

function teardown(testCase)
    testCase.TestData = [];
end

function testEndToEnd(testCase)
    % 1. Get all utt files for the source and target
    srcMatList = dataPrep(testCase.TestData.srcWavList,...
        testCase.TestData.srcTransFile, testCase.TestData.srcCacheDir,...
        'NumWorkers', 8, 'StartTime', testCase.TestData.srcStartTime,...
        'EndTime', testCase.TestData.srcEndTime);
    verifyEqual(testCase, length(srcMatList), testCase.TestData.numSrcWavs);
    for ii = 1:testCase.TestData.numSrcWavs
        verifyTrue(testCase, logical(exist(srcMatList{ii}, 'file')));
    end
    
    tgtMatList = dataPrep(testCase.TestData.tgtWavList,...
        testCase.TestData.tgtTransFile, testCase.TestData.tgtCacheDir,...
        'NumWorkers', 8, 'StartTime', testCase.TestData.tgtStartTime,...
        'EndTime', testCase.TestData.tgtEndTime);
    verifyEqual(testCase, length(tgtMatList), testCase.TestData.numTgtWavs);
    for ii = 1:testCase.TestData.numTgtWavs
        verifyTrue(testCase, logical(exist(tgtMatList{ii}, 'file')));
    end
    
    % 2. Train PPG-GMM model
    srcTrainSet = srcMatList(testCase.TestData.trainSet);
    tgtTrainSet = tgtMatList(testCase.TestData.trainSet);
    [gmmMdlPath, gmmStatus] = buildGMMmodelGSB(srcTrainSet,...
        tgtTrainSet, testCase.TestData.gmmMdlPath);
    verifyTrue(testCase, logical(gmmStatus));
    verifyTrue(testCase, logical(exist(gmmMdlPath, 'file')));
    
    % 3. Get pitch models
    [srcPitchMdlPath, srcPitchStatus] = buildPitchModelGSB(srcTrainSet,...
        testCase.TestData.srcPitchMdlPath, 'Mode', 'heq');
    verifyTrue(testCase, logical(srcPitchStatus));
    verifyTrue(testCase, logical(exist(srcPitchMdlPath, 'file')));
    
    [tgtPitchMdlPath, tgtPitchStatus] = buildPitchModelGSB(tgtTrainSet,...
        testCase.TestData.tgtPitchMdlPath, 'Mode', 'heq');
    verifyTrue(testCase, logical(tgtPitchStatus));
    verifyTrue(testCase, logical(exist(tgtPitchMdlPath, 'file')));
    
    % 4. Perform accent conversion
    testUtts = srcMatList(testCase.TestData.testSet);
    [wavFiles, acStatus] = voiceConversionInterfaceGSB(testUtts,...
        gmmMdlPath, srcPitchMdlPath, tgtPitchMdlPath,...
        testCase.TestData.acDir, 'NumWorkers', 8);
    for ii = 1:length(wavFiles)
        % Wav is saved
        verifyTrue(testCase, logical(exist(wavFiles{ii}, 'file')));
    end
    verifyTrue(testCase, logical(acStatus));
end
