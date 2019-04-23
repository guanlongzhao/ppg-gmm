% trySaveStructFields: save all fields in a struct to a given file.
%
% Syntax: status = trySaveStructFields(x, savePath)
%
% Inputs:
%   x: A struct variable.
%   savePath: A string. Path to a file.
%
% Outputs:
%   status: 1 if this operation finished successfully.
%
% Other m-files required: tryCreateDir
%
% Subfunctions: None
%
% MAT-file required: None
%
% Author: Guanlong Zhao
% Email: gzhao@tamu.edu
% Created: 10/23/2018; Last revision: 10/23/2018
% Revision log:
%   10/23/2018: function creation, Guanlong Zhao

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

function status = trySaveStructFields(x, savePath)
    % Check if the output dir is valid, if not, create it
    [outputDir, filename, ext] = fileparts(savePath);
    if ~isempty(outputDir) && ~exist(outputDir, 'dir')
        tryCreateDir(outputDir);
    end
    
    % Make sure that the extension is valid
    if ~strcmp(ext, '.mat')
        error('Output file extension should be .mat instead of %s.', ext);
    end
    
    % Save all fields
    allFields = fieldnames(x);
    if exist(savePath, 'file')
        warning('File %s already exists, will be overwritten.', savePath);
    end
    save(savePath, '-struct', 'x', allFields{:});
    status = 1;
end