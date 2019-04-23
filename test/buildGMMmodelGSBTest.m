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

% Test buildGMMmodelGSB

function tests = buildGMMmodelGSBTest
    tests = functiontests(localfunctions);
end

function setup(testCase)
    srcMats = dir('data/src/cache/mat/*.mat');
    numMats = length(srcMats);
    srcMatList = cell(numMats, 1);
    for ii = 1:numMats
        srcMatList{ii} = fullfile('data/src/cache/mat', srcMats(ii).name);
    end
    
    tgtMats = dir('data/tgt/cache/mat/*.mat');
    numMats = length(tgtMats);
    tgtMatList = cell(numMats, 1);
    for ii = 1:numMats
        tgtMatList{ii} = fullfile('data/tgt/cache/mat', tgtMats(ii).name);
    end
    
    testCase.TestData.srcMats = srcMatList;
    testCase.TestData.tgtMats = tgtMatList;
    testCase.TestData.outputPath = 'data/temp/build_gmm_test/model.mat';
    
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

function testBuildGMMmodelGSBnormal(testCase)
    [modelPath, status] = buildGMMmodelGSB(testCase.TestData.srcMats,...
        testCase.TestData.tgtMats, testCase.TestData.outputPath);
    verifyTrue(testCase, logical(status));
    verifyTrue(testCase, logical(exist(modelPath, 'file')));
end