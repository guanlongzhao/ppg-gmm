% tryCreateDir: Try to create a dir if it does not exist. This function
% defines its own 'isfolder' function since some older Matlab versions do
% not have that function.
%
% Syntax: res = tryCreateDir(path)
%
% Inputs:
%   path: A string. Path of the dir that you want to create
%
% Outputs:
%   res: Binary flag
%       - 0 - did not create dir
%       - 1 - created dir
%
% Other m-files required: None
%
% Subfunctions: isfolder
%
% MAT-file required: None
%
% Author: Guanlong Zhao
% Email: gzhao@tamu.edu
% Created: 10/10/2018; Last revision: 10/15/2018
% Revision log:
%   10/10/2018: function creation, Guanlong Zhao
%   10/15/2018: add documentation, GZ

% Copyright 2018 Guanlong Zhao
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

function res = tryCreateDir(path)
    isfolder = @(x) logical(exist(x, 'dir'));
    res = 0;
    if ~isfolder(path)
        mkdir(path);
        res = 1;
    else
        warning('Dir %s already exists, skipping this operation.', path);
    end
end
