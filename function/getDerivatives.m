% getDerivatives: append delta or delta-delta features
%
% Syntax: Y = getDerivatives(x, numDerivatives)
%
% Inputs:
%   inFeatures: the input features, arranged in columns
%   numDerivatives: maximum order of derivatives, 0 (default) | 1 | 2
%
% Outputs:
%   outfeatures: output features, arranged as [input; d(input); dd(input)]
%
% Other m-files required: None
%
% Subfunctions: None
%
% MAT-file required: None
%
% Author: Guanlong Zhao
% Email: gzhao@tamu.edu
% Created: 10/13/2016; Last revision: 05/15/2017
% Revision log:
%   10/13/2016: function creation, Guanlong Zhao
%   05/15/2017: changed variable names, GZ

% Copyright 2016 Guanlong Zhao
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

function Y = getDerivatives(x, numDerivatives)
if nargin < 2
    numDerivatives = 0;
end

% Set smoothing kernels, flipped to do convolution
% First order, dx(t) = 0.5(x(t + 1) - x(t - 1))
sKerD1 = fliplr([-0.5, 0, 0.5]);

% Second order, ddx(t) = 0.5(dx(t + 1) - dx(t - 1)) = 0.25(x(t + 2) - 2x(t)
% + x(t - 2)), but this will cause the first column to be a little off 
sKerD2 = fliplr([0.25, 0, -0.5, 0, 0.25]); 

% Compute derivatives
switch numDerivatives
    case 0
        Y = x;
    case 1
        dx = conv2(x, sKerD1, 'same');
        Y = [x; dx];
    case 2
        dx = conv2(x, sKerD1, 'same');
        ddx = conv2(x, sKerD2, 'same');
        Y = [x; dx; ddx];
    otherwise
        error('Wrong number of derivatives!');
end