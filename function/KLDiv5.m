% Compute pairwise symmetrix KL divergence
% This is a really fast implementation
% x: d*m matrix, each column is a sample
% y: d*n matrix, each column is a sample
% dist: m*n matrix, dist(i, j) = KL(x(:, i), y(:, j))

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

function D = KLDiv5(x, y)
    logx = log(x+eps);
    logy = log(y+eps);
    
    D = bsxfun(@plus,dot(y,logy,1),dot(x,logx,1)')-x'*logy-logx'*y;
end