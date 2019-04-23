% fixPpgLengthMismatch: Match the length of the PPGs of an utterance to the
% length of its spectral features. Why we have to do this? Because Kaldi
% and the vocoders have slightly different ways to compute the number of
% frames in an utterance. If the number of frames in the PPGs is smaller
% than what the vocoders expect, we pad the PPGs with "fake" silence
% frames. If the number of frames in the PPGs is larger than what the
% vocoders expect, we cut the last few frames from PPGs, which are
% generally just silence.
%
% Syntax: utt = fixPpgLengthMismatch(utt, post)
%
% Inputs:
%   utt: An utt struct
%   post: A D*T matrix, where D is dimension and T is number of frames
%
% Outputs:
%   utt: A utt struct with the fixed post appended
%
% Other m-files required: None
%
% Subfunctions: None
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

function utt = fixPpgLengthMismatch(utt, post)
    numFeatFrames = size(utt.mfcc, 2);
    % Deal with PPG length inconsistency -- sometimes the PPG will have
    % different number of frames as the vocoder analysis.
    numPostFrames = size(post, 2);
    silDim = 1; % This is the typical silence dim in the 5816-dim PPG representation
    fakeSilPpg = zeros(size(post, 1), 1, 'single'); % Padding vector
    fakeSilPpg(silDim) = single(1); % Set the vector to represent sil
    if numFeatFrames < numPostFrames
        % Cut the PPG
        warning('The PPGs are too long, cutting %d frames at the end.',...
            numPostFrames - numFeatFrames);
        post = post(:, 1:numFeatFrames);
    elseif numFeatFrames > numPostFrames
        % Padding the fake silence PPG to the end of post
        warning('The PPGs are too short, padding it with %d frames of silence.',...
            numFeatFrames - numPostFrames);
        post = [post, repmat(fakeSilPpg, 1, numFeatFrames - numPostFrames)];
    end
    utt.post = post;
end