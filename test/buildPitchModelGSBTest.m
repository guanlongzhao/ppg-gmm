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

% Test buildPitchModelGSB

function tests = buildPitchModelGSBTest
    tests = functiontests(localfunctions);
end

function setup(testCase)
    mats = dir('data/src/cache/mat/*.mat');
    numMats = length(mats);
    matList = cell(numMats, 1);
    for ii = 1:numMats
        matList{ii} = fullfile('data/src/cache/mat', mats(ii).name);
    end
    
    testCase.TestData.mats = matList;
    testCase.TestData.outputPath = 'data/temp/build_pitch_test/model.mat';
    
    testCase.TestData.outputDir = fileparts(testCase.TestData.outputPath);
    if exist(testCase.TestData.outputDir, 'dir')
        rmdir(testCase.TestData.outputDir, 's');
    end
end

function teardown(testCase)
    if exist(testCase.TestData.outputDir, 'dir')
        rmdir(testCase.TestData.outputDir, 's');
    end
end

function testBuildPitchModelGSBheq(testCase)
    [modelPath, status] = buildPitchModelGSB(testCase.TestData.mats,...
        testCase.TestData.outputPath, 'Mode', 'heq');
    verifyTrue(testCase, logical(status));
    verifyTrue(testCase, logical(exist(modelPath, 'file')));
end

function testBuildPitchModelGSBlog(testCase)
    [modelPath, status] = buildPitchModelGSB(testCase.TestData.mats,...
        testCase.TestData.outputPath, 'Mode', 'log');
    verifyTrue(testCase, logical(status));
    verifyTrue(testCase, logical(exist(modelPath, 'file')));
end