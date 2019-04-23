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

% Test voiceConversionGSB

function tests = voiceConversionGSBTest
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    testUttPath = 'data/src/cache/mat/gsb_0001.mat';
    testCase.TestData.utt = loadUttGSB({testUttPath},...
        'RegExp', '^(?!post)\w');
    
    gmmMdlPath = 'data/model/acoustic/ppg_gmm_model.mat';
    testCase.TestData.gmmMdl = load(gmmMdlPath);
    
    srcPitchMdlPath = 'data/model/pitch/src_model.mat';
    testCase.TestData.srcPitchMdl = load(srcPitchMdlPath);
    
    tgtPitchMdlPath = 'data/model/pitch/tgt_model.mat';
    testCase.TestData.tgtPitchMdl = load(tgtPitchMdlPath);
end

function teardownOnce(testCase)
    testCase.TestData = [];
end

function testVoiceConversionGSBmlgv(testCase)
    [covUtt, status] = voiceConversionGSB(testCase.TestData.utt,...
        testCase.TestData.gmmMdl, testCase.TestData.srcPitchMdl,...
        testCase.TestData.tgtPitchMdl, 'SpecCov', 'MLGV');
    isValidWav = sum(isnan(covUtt.wav)) == 0;
    verifyTrue(testCase, isValidWav);
    verifyTrue(testCase, logical(status));
end

function testVoiceConversionGSBmlpg(testCase)
    [covUtt, status] = voiceConversionGSB(testCase.TestData.utt,...
        testCase.TestData.gmmMdl, testCase.TestData.srcPitchMdl,...
        testCase.TestData.tgtPitchMdl, 'SpecCov', 'MLPG');
    isValidWav = sum(isnan(covUtt.wav)) == 0;
    verifyTrue(testCase, isValidWav);
    verifyTrue(testCase, logical(status));
end

function testVoiceConversionGSBmmse(testCase)
    [covUtt, status] = voiceConversionGSB(testCase.TestData.utt,...
        testCase.TestData.gmmMdl, testCase.TestData.srcPitchMdl,...
        testCase.TestData.tgtPitchMdl, 'SpecCov', 'MMSE');
    isValidWav = sum(isnan(covUtt.wav)) == 0;
    verifyTrue(testCase, isValidWav);
    verifyTrue(testCase, logical(status));
end