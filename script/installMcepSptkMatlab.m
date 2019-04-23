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

% Install 'mcep-sptk-matlab'
% You need a valid C/C++ compiler for Matlab.
% See the documentation for 'mex' for more details.
clear;
clc;

currDir = pwd;
rootDir = fileparts(currDir);
packageDir = fullfile(rootDir, 'dependency', 'mcep-sptk-matlab');
cd(packageDir);

% Compile all C codes.
mex freqt.c
mex frqtr.c
mex mexmcep2spec.c
mex theq.c

disp('Done.');