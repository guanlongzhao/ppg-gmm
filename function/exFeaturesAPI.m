% exFeaturesAPI: an API for speech analysis
%
% Syntax: utt = exFeaturesAPI(audioPath, textPath, tgPath)
%
% Inputs:
%   audioPath: path to a wave file
%   textPath: path to orthographic file
%   tgPath: path to TextGrid file
%
% Outputs:
%   utt: utterance object
%
% Other m-files required: mPraat library, speechAnalysis.m
%
% Subfunctions: None
%
% MAT-file required: None
%
% Author: Guanlong Zhao
% Email: gzhao@tamu.edu
% Created: 04/20/2017; Last revision: 10/10/2018
% Revision log:
%   04/20/2017: function creation, Guanlong Zhao
%   04/21/2017: allowed not passing the text and tg file, GZ
%   04/23/2017: fixed a bug that may cause too many opened files, GZ
%   10/10/2018: default to use 'WORLD' vocoder, GZ

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

function utt = exFeaturesAPI(audioPath, textPath, tgPath)
    switch nargin
        case 1
            textPath = '';
            tgPath = '';
        case 2
            tgPath = '';
        case 3
        otherwise
            error('Wrong number of inputs!');
    end
    assert(logical(exist(audioPath, 'file')), 'IO Error: audio file does not exist!');
    [audio, fs] = audioread(audioPath);
    if exist(textPath, 'file')
        textFile = fopen(textPath);
        text = fgetl(textFile);
        fclose(textFile);
    else
        text = '';
    end
    if exist(tgPath, 'file')
        tg = tgRead(tgPath);
    else
        tg = [];
    end
    utt = speechAnalysis(audio, fs, 'Text', text, 'TextGrid', tg,...
        'Vocoder', 'WORLD');
end
