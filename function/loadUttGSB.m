% loadUttGSB: load utt structs given paths.
%
% Syntax: [uttContainer, invalidIdx] = loadUttGSB(uttsPath)
%
% Inputs:
%   uttsPath: A cell array. Each element contains a path to a mat file.
%
%   [Optional name-value pairs]
%   'RegExp': A regular expression string. Default to ''. If input a
%   non-empty value, then the function will only load the fields that match
%   this regular expression. This option is mutually exclusive with
%   'VarList'. If you want to keep all but the 'post' field, use the regexp
%   '^(?!post)\w'
%   'VarList': A cell list. Default to {}. If input a non-empty value, then
%   the function will only load the fields in this list. This option is
%   mutually exclusive with 'RegExp'
%
% Outputs:
%   uttContainer: A struct array. Each element is a utt struct.
%   invalidIdx: A numeric array. Indices of files that do not exist.
%
% Other m-files required: None
%
% Subfunctions: None
%
% MAT-file required: None
%
% Author: Guanlong Zhao
% Email: gzhao@tamu.edu
% Created: 10/19/2018; Last revision: 10/23/2018
% Revision log:
%   10/19/2018: function creation, Guanlong Zhao
%   10/23/2018: support loading a subset of the fields through either
%   regular expression or a list of variables, GZ

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

function [uttContainer, invalidIdx] = loadUttGSB(uttsPath, varargin)
    % Input parser
    p = inputParser;
    addRequired(p, 'uttsPath', @iscell);
    addParameter(p, 'RegExp', '', @ischar);
    addParameter(p, 'VarList', {}, @iscell);
    parse(p, uttsPath, varargin{:});
    
    mode = 'normal';
    inputRegExp = p.Results.RegExp;
    isRegExp = ~isempty(inputRegExp);
    if isRegExp
        mode = 'regexp';
    end
    varList = p.Results.VarList;
    isVarList = ~isempty(varList);
    if isVarList
        mode = 'varlist';
    end
    assert(~(isRegExp && isVarList),...
        'The regular expression and list of valid variables should not be used together.')
    
    nUtt = length(uttsPath);
    uttContainer = [];
    invalidIdx = [];
    
    for ii = 1:nUtt
        fileName = uttsPath{ii};
        if exist(fileName, 'file')
            switch mode
                case 'normal'
                    tempBuffer = load(fileName);
                case 'regexp'
                    tempBuffer = load(fileName, '-regexp', inputRegExp);
                case 'varlist'
                    tempBuffer = load(fileName, varList{:});
                otherwise
                    error('Unknown error!');
            end
            uttContainer = [uttContainer; tempBuffer];
        else
            fprintf('Mat file ''%s'' does not exist!\n', fileName);
            invalidIdx = [invalidIdx, ii];
        end
    end
end