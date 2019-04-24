% static2dynamic: Transform the static MFCCs x to the dynamic version
% X = (x, dx). The result of this function is the same as X = Wx, but it's
% faster and requires less memory.
%
% Syntax: X = static2dynamic(x)
%
% Input:
% 	x: a [D, T] MFCC matrix
%
% Output:
% 	X: a [2D, T] (MFCC + Delta MFCC) matrix
%
% Other m-files required: None
%
% Subfunctions: None
%
% MAT-file required: None
%
% Author: Guanlong Zhao
% Email: gzhao@tamu.edu
% Created: Oct. 2015; Last revision: 04/23/2019
% Revision log:
% 	11/19/2015: updated the function descriptions
%	1/8/2016: updated the function descriptions
%   04/27/2017: compatibility fix, GZ
%   04/23/2019: fix docs, GZ

% Copyright 2015 Guanlong Zhao
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

function X = static2dynamic(x)
x = transpose(x); % D*T -> T*D

[T, D] = size(x);
X = zeros(T, 2 * D);
x1_dx1 = [x(1, :), x(2, :) .* 0.5];
X(1, :) = x1_dx1;
for t = 2:T - 1
    xt_dxt = [x(t, :), (x(t + 1, :) - x(t - 1, :)) .* 0.5];
    X(t, :) = xt_dxt;
end
xT_dxT = [x(T, :), x(T - 1, :) .* (-0.5)];
X(T, :) = xT_dxT; % T * 2D

X = transpose(X); % T*2D -> 2D*T
end