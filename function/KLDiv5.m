% KLDiv5: compute pairwise symmetrix KL divergence. This is a really fast
% implementation.
%
% Syntax: D = KLDiv5(x, y)
%
% Inputs:
%   x: d*m matrix, each column is a sample
%   y: d*n matrix, each column is a sample
%
% Output:
%   D: m*n matrix, D(i, j) = KL(x(:, i), y(:, j))
%
% Other m-files required: None
%
% Subfunctions: None
%
% MAT-file required: None
%
% Author: Guanlong Zhao
% Email: gzhao@tamu.edu
% Created: 2017; Last revision: 04/23/2019
% Revision log:
%   2017: function creation, Guanlong Zhao
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

function D = KLDiv5(x, y)
    logx = log(x+eps);
    logy = log(y+eps);
    
    D = bsxfun(@plus,dot(y,logy,1),dot(x,logx,1)')-x'*logy-logx'*y;
end