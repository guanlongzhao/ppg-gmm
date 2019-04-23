% tg2lab: convert interval information in one tier of TextGrid to frame
% indeces, and also normalize the labels
%
% Syntax: lab = tg2lab(tg, varargin)
%
% Inputs:
%   tg: TextGrid object from mPraat
%   [optional name-value pairs]:
%   'Shift': window frame shift, default to 1 (ms)
%   'Tmax': the maximum number of frames allowed, default to
%   ceil(tg.tmax*1000/defaultShift). This option can be used to make sure
%   that the maximum output frame index is consistent with some other
%   feature vectors.
%   'Mode': the tier to be converted, 'phones' (default) | 'words'
%   'ArpaStyle': true | false (*); capitalizaed, keep pressure tags
%
% Outputs:
%   lab: a struct that contains the duration information of phone segments
%       - phones/words: phones or words sequence, a cell array
%       - startTime: start time of each segment, a double array
%       - endTime: end time of each segment, a double array
%
% Other m-files required: None
%
% Subfunctions: None
%
% MAT-file required: None
%
% TODOs:
%   1. Change to dynamic struct index, [opened 04/23/2017]
%
% Author: Guanlong Zhao
% Email: gzhao@tamu.edu
% Created: 04/18/2017; Last revision: 10/15/2018
% Revision log:
%   04/18/2017: function creation, Guanlong Zhao
%   04/20/2017: function refinement, Guanlong Zhao
%   04/21/2017: fixed a bug that will cause function to break if the input
%   tg is empty, Guanlong Zhao
%   04/23/2017: added TODOs, GZ
%   09/12/2018: added support for parsing L2-ARCTIC annotation symbols, GZ
%   10/03/2018: added support to output ARPABET style labels, GZ
%   10/04/2018: fixed bug related to start and end time, GZ
%   10/15/2018: update the silence detection part, GZ

% Copyright 2017 Guanlong Zhao
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

function lab = tg2lab(tg, varargin)
    % Handle empty TextGrid
    if isempty(tg)
        lab = [];
        return;
    end
    
    % Parse inputs
    p = inputParser;
    defaultShift = 1;
    defaultMode = 'phones';
    expectedModes = {'phones', 'words'};
    addRequired(p, 'tg');
    addParameter(p, 'Shift', defaultShift, @isnumeric);
    addParameter(p, 'Tmax', -1, @isnumeric);
    addParameter(p, 'Mode', defaultMode, @(x) any(validatestring(x, expectedModes)));
    addParameter(p, 'ArpaStyle', false);
    parse(p, tg, varargin{:}); 
    shift = p.Results.Shift;
    T = p.Results.Tmax;
    
    % If we have any input value, use it, otherwise, use the default
    if T < 0
        T =  round(tg.tmax*1000/shift);
    end
    
    mode = p.Results.Mode;
    
    % Different kinds of labels are stored in different tiers in the TG,
    % and they require different text normalization methods
    switch mode
        case 'words'
            nTier = 1;
            normalizeMethod = @normalizeWord;
        case 'phones'
            nTier = 2;
            if p.Results.ArpaStyle
                normalizeMethod = @normalizePhoneArpaStyle;
            else
                normalizeMethod = @normalizePhone;
            end
        otherwise
            error('Tier not exist!');
    end
    
    % A safeguard
    assert(strcmp(tg.tier{nTier}.name, mode), 'Something wrong with the TG');
    
    items = tg.tier{nTier}.Label;
    startTime = tg.tier{nTier}.T1;
    endTime = tg.tier{nTier}.T2;
    
    lab = struct;
    normalizedItems = cell(size(items));
    lab.startTime = nan(size(startTime));
    lab.endTime = nan(size(endTime));
    
    for ii = 1:length(items)
        currItem = normalizeMethod(items{ii});
        normalizedItems(ii) = {currItem};
        % Convert second to frame index
        lab.endTime(ii) = max([round((endTime(ii)+eps)*1000/shift), 1]);
    end
    if lab.endTime(end - 1) <= T
        lab.endTime(end) = T;
    else
        error('Max time not compatible!');
    end
    lab.startTime = [0, lab.endTime(1:(end-1))];
    shouldIncrease = lab.startTime < lab.endTime;
    lab.startTime(shouldIncrease) = lab.startTime(shouldIncrease) + 1;
    
    % Check the time
    assert(issorted(lab.startTime), 'Start time not monotonic');
    assert(issorted(lab.endTime), 'End time not monotonic');
    assert(sum(lab.startTime > lab.endTime) == 0, 'Start time larger than end time');
    
    % TODO: change this to dynamic field indexing
    switch mode
    case 'words'
        lab.words = normalizedItems;
    case 'phones'
        lab.phones = normalizedItems;
    otherwise
        error('Mode invalid');
    end
    
    % Helper function, get rid of the pressure tags in the phoneme labels
    function outString = normalizePhone(inString)
        inString = lower(inString);
        if isempty(inString) || ismember(inString, {'sil', 'sp', 'spn'})
            outString = [];
            return;
        end
        parsedTag = lower(regexprep(inString, '[^a-zA-Z,]', ''));
        if isempty(parsedTag)
            error('Invalid label %', inString);
        end
        % This handles the L2-ARCTIC annotations, here we extract the
        % canonical pronunciation
        outString = strsplit(parsedTag, ',');
        outString = outString{1};
    end

    % Helper function, parse for the correct phoneme label, use the ARPABET
    % style -- captalizaed, keep pressure tags
    function outString = normalizePhoneArpaStyle(inString)
        inString = upper(inString);
        if isempty(inString) || ismember(inString, {'SIL', 'SP', 'SPN'})
            outString = [];
            return;
        end
        parsedTag = regexprep(string(inString), '[^0-9a-zA-Z,]', '');
        if isempty(parsedTag)
            error('Invalid label %s', inString);
        end
        % This handles the L2-ARCTIC annotations, here we extract the
        % canonical pronunciation
        outString = split(parsedTag, ',');
        outString = char(outString(1));
    end
    
    % Process word string
    function outString = normalizeWord(inString)
        outString = lower(inString);
    end
end
