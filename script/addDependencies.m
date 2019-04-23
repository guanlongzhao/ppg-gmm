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

% Add dependencies for PPG-GMM
currDir = pwd;
rootDir = fileparts(currDir);

depPackages = {'acoust_based', 'GMM', 'kaldi2matlab', 'netlab',...
    'mcep-sptk-matlab', 'mPraat', 'rastamat', 'world-0.2.3_matlab'};

for ii = 1:length(depPackages)
    addpath(fullfile(rootDir, 'dependency', depPackages{ii}));
end

addpath(fullfile(rootDir, 'function'));
addpath(fullfile(rootDir, 'script'));
addpath(fullfile(rootDir, 'test'));

% Activate this line if Kaldi uses a C++ library that is different than the
% Matlab default. You may also need to change the path to the C++ library
% setenv('LD_PRELOAD', '/usr/lib64/libstdc++.so.6')