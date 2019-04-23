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

% Prepare test data for model building
clear
clc
currDir = pwd;
parentDir = fileparts(currDir);
rootDir = fullfile(parentDir, 'test/data');

% Source speaker data
recordings = dir(fullfile(rootDir, 'src/recordings/*.wav'));
numWavs = length(recordings);
wavList = cell(numWavs, 1);
for ii = 1:numWavs
    wavList{ii} = fullfile(rootDir, 'src/recordings', recordings(ii).name);
end
transFile = fullfile(rootDir, 'src/prompts.txt');
matList = dataPrep(wavList, transFile, fullfile(rootDir, 'src/cache'),...
    'NumWorkers', 8);

% target speaker data
recordings = dir(fullfile(rootDir, 'tgt/recordings/*.wav'));
numWavs = length(recordings);
wavList = cell(numWavs, 1);
for ii = 1:numWavs
    wavList{ii} = fullfile(rootDir, 'tgt/recordings', recordings(ii).name);
end
transFile = fullfile(rootDir, 'tgt/prompts.txt');
matList = dataPrep(wavList, transFile, fullfile(rootDir, 'tgt/cache'),...
    'NumWorkers', 8);