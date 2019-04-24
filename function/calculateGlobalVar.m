% calculateGlobalVar: calculate GVs of all the utterances in utts, used for
% building GMM model
%
% Syntax: calculateGlobalVar(utts, range)
%
% Inputs:
%   utts: list of utts
%   range: feature dimensions used, default to 2:25
%   feat: name of the speech feature to use, e.g., 'mfcc', 'mcep', etc.
%
% Outputs:
%   uttGVs: GV list for all utts, n*d matrix, n is number of utts, d is
%   length of range
%
% Other m-files required: None
%
% Subfunctions: None
%
% MAT-file required: None
%
% Author: Guanlong Zhao
% Email: gzhao@tamu.edu
% Created: 04/28/2017; Last revision: 04/23/2019
% Revision log:
%   04/28/2017: function creation, Guanlong Zhao
%   05/10/2017: added doc, GZ
%   05/15/2017: removed hard-coded mfcc dim, GZ
%   06/26/2017: fixed input parsing bug, GZ
%   09/10/2017: added support for choosing features, GZ
%   10/19/2018: update for GSB version, GZ
%   04/23/2019: fix docs, GZ

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

function uttGVs = calculateGlobalVar(utts, range, feat)
    if nargin < 2
        range = 2:size(utts(1).mfcc, 1);
    end
    if nargin < 3
        feat = 'mfcc';
    end
    uttGVs = zeros(length(utts), length(range));
    for ii = 1:length(utts)
        uttGVs(ii, :) = var(utts(ii).(feat)(range, :)');
    end
end