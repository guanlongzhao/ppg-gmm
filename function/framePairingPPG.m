% framePairingPPG: compute frame pairing given posteriorgram features. The
% function will split the computation into smaller batches. This is the
% memory efficient version of "acFramePairing", and slightly faster. The
% outputs of the two functions are almost identical, except that the costs
% are "double" in this function while being "single" in "acFramePairing"
%
% Syntax: [mapToSrc, mapToTgt, mapToSrcCost, mapToTgtCost] = framePairingPPG(srcPost, tgtPost, splitSize)
%
% Inputs:
%   srcPost: D*T1 matrix
%   tgtPost: D*T2 matrix
%   splitSize: number of frames in a batch, default as 3000 frames, if the
%   input is less than 3000 frames then run in a single batch
%   verbose: true | false, display some information, defaule to false
%
% Outputs:
%   mapToSrc: T2*1 vector, map source to the length of target
%   mapToTgt: T1*1 vector, map target to the length of source
%   mapToSrcCost: T2*1 vector, the cost of mapping source to target
%   mapToTgtCost: T1*1 vector, the cost of mapping target to source
%
% Other m-files required: KLDiv5
%
% Subfunctions: None
%
% MAT-file required: None
%
% Author: Guanlong Zhao
% Email: gzhao@tamu.edu
% Created: 05/10/2018; Last revision: 10/18/2018
% Revision log:
%   05/10/2018: function creation, Guanlong Zhao
%   10/18/2018: ported to use in GSB, GZ

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

function [mapToSrc, mapToTgt, mapToSrcCost, mapToTgtCost] = framePairingPPG(srcPost, tgtPost, splitSize, verbose)
    if nargin < 3
        splitSize = 3e3;
        verbose = false;
    end
    
    if nargin < 4
        verbose = false;
    end
    
    nSrcFrame = size(srcPost, 2);
    nTgtFrame = size(tgtPost, 2);
    numSplits = ceil(nSrcFrame/splitSize);
    
    mapToTgtCostTemp = zeros(nTgtFrame, numSplits);
    mapToTgtTemp = zeros(nTgtFrame, numSplits);
    
    mapToSrcCost = zeros(nSrcFrame, 1);
    mapToSrc = zeros(nSrcFrame, 1);
    
    for ii = 1:numSplits
        if verbose
            tic;
        end
        startIdx = 1+splitSize*(ii-1);
        endIdx = min([splitSize*ii, nSrcFrame]);
        kld = KLDiv5(srcPost(:, startIdx:endIdx), tgtPost);
        [mapToSrcCost(startIdx:endIdx), mapToSrc(startIdx:endIdx)] = min(kld, [], 2);
        [currCost, currMap] = min(kld);
        mapToTgtCostTemp(:, ii) = currCost';
        mapToTgtTemp(:, ii) = currMap'+startIdx-1;
        if verbose
            toc;
        end
    end

    % Find the pairing
    [mapToTgtCost, bridgeMap] = min(mapToTgtCostTemp, [], 2);
    
    % Linear indexing. Much more about this technique can be found in Steve
    % Eddins' blog at http://blogs.mathworks.com/steve/2008/02/08/linear-indexing/
    I = (1 : size(mapToTgtTemp, 1)) .';
    J = reshape(bridgeMap, [], 1);
    k = sub2ind(size(mapToTgtTemp), I, J);
    mapToTgt = mapToTgtTemp(k);
end