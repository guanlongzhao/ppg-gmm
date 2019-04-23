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

% Test voiceConversionInterfaceGSB

function tests = voiceConversionInterfaceGSBTest
    tests = functiontests(localfunctions);
end

function setup(testCase)
    testCase.TestData.gmmPath = 'data/model/acoustic/ppg_gmm_model.mat';
    testCase.TestData.srcPitchPath = 'data/model/pitch/src_model.mat';
    testCase.TestData.tgtPitchPath = 'data/model/pitch/tgt_model.mat';
    testCase.TestData.outputPath = 'data/temp/vc_test';
    
    if exist(testCase.TestData.outputPath, 'dir')
        rmdir(testCase.TestData.outputPath, 's');
    end
end

function teardown(testCase)
    if exist(testCase.TestData.outputPath, 'dir')
        rmdir(testCase.TestData.outputPath, 's');
    end
end

function testVoiceConversionInterfaceGSBoneUtt(testCase)
    testUtts = {'data/src/cache/mat/gsb_0001.mat'};
    outputFileName = fullfile(testCase.TestData.outputPath,...
        'gsb_0001.wav');
    
    [wavFiles, status] = voiceConversionInterfaceGSB(testUtts,...
        testCase.TestData.gmmPath, testCase.TestData.srcPitchPath,...
        testCase.TestData.tgtPitchPath, testCase.TestData.outputPath);
    
    % Wav is saved
    verifyTrue(testCase, logical(exist(wavFiles{1}, 'file')));
    % Wav is saved to the desired path
    verifyTrue(testCase, strcmp(wavFiles{1}, outputFileName));
    % Status is valid
    verifyTrue(testCase, logical(status));
end

function testVoiceConversionInterfaceGSBmultipleUttSerial(testCase)
    testUtts = {'data/src/cache/mat/gsb_0001.mat',...
        'data/src/cache/mat/gsb_0002.mat',...
        'data/src/cache/mat/gsb_0003.mat'};
    
    [wavFiles, status] = voiceConversionInterfaceGSB(testUtts,...
        testCase.TestData.gmmPath, testCase.TestData.srcPitchPath,...
        testCase.TestData.tgtPitchPath, testCase.TestData.outputPath,...
        'NumWorkers', 0);
    
    for ii = 1:length(wavFiles)
        % Wav is saved
        verifyTrue(testCase, logical(exist(wavFiles{ii}, 'file')));
    end
    % Status is valid
    verifyTrue(testCase, logical(status));
end

function testVoiceConversionInterfaceGSBmultipleUttParallel(testCase)
    testUtts = {'data/src/cache/mat/gsb_0001.mat',...
        'data/src/cache/mat/gsb_0002.mat',...
        'data/src/cache/mat/gsb_0003.mat'};
    
    [wavFiles, status] = voiceConversionInterfaceGSB(testUtts,...
        testCase.TestData.gmmPath, testCase.TestData.srcPitchPath,...
        testCase.TestData.tgtPitchPath, testCase.TestData.outputPath,...
        'NumWorkers', 4);
    
    for ii = 1:length(wavFiles)
        % Wav is saved
        verifyTrue(testCase, logical(exist(wavFiles{ii}, 'file')));
    end
    % Status is valid
    verifyTrue(testCase, logical(status));
end