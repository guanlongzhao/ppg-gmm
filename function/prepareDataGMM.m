% prepareDataGMM: prepare data that are ready for the GMM training to use.
%
% Syntax: [mcep, post] = prepareDataGMM(utts)
%
% Inputs:
%   utts: A struct array. Containing utt structs.
%
% Outputs:
%   mcep: A D1*T matrix. All mceps from the utts concatenated, with mcep_0
%   and silence removed and delta features appended
%   post: A D2*T matrix. All mceps from the utts concatenated, with silence
%   removed
%
% Other m-files required: getDerivatives
%
% Subfunctions: None
%
% MAT-file required: None
%
% Author: Guanlong Zhao
% Email: gzhao@tamu.edu
% Created: 10/19/2018; Last revision: 10/19/2018
% Revision log:
%   10/19/2018: function creation, Guanlong Zhao

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

function [mcep, post] = prepareDataGMM(utts)
    numUtts = length(utts);
    % Compile training data, validate, filter silence
    mcep = [];
    post = [];
    for ii = 1:numUtts
        lab = utts(ii).lab;
        keepIdx = ~isnan(lab);
        % Get delta features for mcep
        tempmcep = getDerivatives(utts(ii).mcep(2:end, :), 1);
        % Remove silence segment
        tempmcep = tempmcep(:, keepIdx);
        mcep = [mcep, tempmcep];
        % Get posteriorgram and remove silence frames accordingly
        temppost = utts(ii).post(:, keepIdx);
        post = [post, temppost];
    end
end