% [path,l] = shp_dp(V,P[,w,pmodes,lambda,Q])
% Shortest path in a layered graph by dynamic programming
%
% Consider a layered graph, where nodes in layer n are connected to
% all nodes in layer n-1 and all nodes in layer n+1, but are not
% connected to anything else. Then, shp_dp finds the shortest path
% traversing all layers; that is, a path starting from one node in the
% leftmost layer (layer 1) and ending in one node of the rightmost
% layer (layer N). A distance function \delta(a,b) between nodes a, b
% is assumed; currently, this distance is the Euclidean distance in
% R^D with optional weights w.
%
% The algorithm is dynamic programming by forward recursion, which
% performs a global search.
%
% The graph is represented in a compact way as a matrix V containing all
% the nodes, rowwise and consecutively, and starting from layer 1. The
% number of nodes in layer n is contained in c(n). The list p contains
% the starting indices of each layer in matrix V, and is constructed
% from c, so that p(1)=1 and p(n)=1+\sum^{n-1}_{m=1}{c(m)}. Clearly,
% the number of rows in V must be sum(c).
%
% NOTE: currently, only one path per node at stage n is kept. This
% rules out cases where the minimisation at stage n gives several
% paths (this step is marked [*] in the code below). In practice with
% real numbers this should be rare, though.
%
% In:
%   V: Nx1 cell array containing all nodes.
%   P: (to use the forward mapping constraint) cell array {fwd,I} where fwd is
%      a function handle for a forward mapping with inputs indexed by I.
%      Default: don't use a forward mapping constraint.
%   w: 1xD vector containing the weights for the weighted Euclidean
%      distance (default: ones, i.e., unweighted Euclidean distance).
%   pmodes: Nx1 cell array containing nodes' height.
%   lambda: 1x2 vector containing weights for fwd constraint and nodes'
%      height respectively. Default: [0 0].
%   Q: cell array to indicate distance measure. 'M': theta-x; 'C': theta
%      0: square root; 1: square. Defaut: {'M',0}.
%
% Out:
%   path: NxD matrix of N row D-dimensional vectors, the nodes of the
%      (shortest) path, in order.
%   l: real number containing the length of the path, equal to the sum
%      of the distances between consecutive nodes in the path.
%
% See also shp_greedy.

% Copyright (c) 2006 by Miguel A. Carreira-Perpinan and Chao Qin

function [path,l] = shp_dp(V,P,w,pmodes,lambda,Q)

N = size(V,1);					% Number of layers
D = size(V{1},2);				% Dimensionality of nodes

% ----------- Argument defaults ----------------------
if ~exist('P','var') | isempty(P)
  fwd = [];
else
  fwd = P{1};                     % Function handler to forward mapping
  I = P{2};
  J = setdiff(1:D,I);
end
if ~exist('w','var') | isempty(w) w = ones(1,D); end
if ~exist('pmodes','var') | isempty(pmodes) pmodes = []; end
if ~exist('lambda','var') | isempty(lambda) lambda = [0 0]; end
if ~exist('Q','var') | isempty(Q) Q = {'M',0}; end

% cp(i,:) is the path from layer 1 (start) to node i of layer n
%    (current). Thus, at stage n cp is a c(n) x n matrix.
% cl(i) is the length of path cp(i,:). Thus, at stage n cl is a
%    c(n)x1 vector.

% Initialisation
cp = (1:size(V{1},1))';					% Single-node paths
cl = zeros(size(V{1},1),1);				% with length 0

for n=2:N
  % d(i,j) is the distance from node i of layer n-1 to node j of layer n.

  if strcmp(Q{1},'M')    % Miguel's implementation
    if Q{2}==0
      d = sqrt(sqdist(V{n-1},V{n},w));
    else
      d = sqdist(V{n-1},V{n},w);
    end
  else                   % Chao's implementation
    if Q{2}==0
      d = sqrt(sqdist(V{n-1}(:,J),V{n}(:,J),w(J)));
    else
      d = sqdist(V{n-1}(:,J),V{n}(:,J),w(J));
    end
  end

  % Forward constraints
  if ~isempty(fwd)
    if Q{2}==0
      d0 = sqrt(sqdist(fwd(V{n-1}(:,J)),V{n-1}(1,I),w(I)));
    else
      d0 = sqdist(fwd(V{n-1}(:,J)),V{n-1}(1,I),w(I));
    end
    cl = cl + lambda(1)*d0;
  end
  % Mode heights
  if ~isempty(pmodes)
    d1 = pmodes{n-1};
    cl = cl - lambda(2)*d1;
  end

  % cl*ones(1,size(V{n},1)): accumulative path score matrix up to frame n-1.
  %     The ith row has elements of the same value which is the
  %     accumulative path score of the ith node at frame n-1.
  % d: local path score matrix between frame n-1 and n. d(i,j) is
  %    absolute distance between the ith node at frame n-1 and the jth node
  %    at frame n.
  % cl*ones(1,size(V{n},1))+d: accumulative path score matrix up to frame n.
  %    min(cl*ones(1,size(V{n},1))+d,[],1): for each node at frame n, select
  %    one node at frame n-1 which has the minimum accumulative distance to
  %    that node at frame n.
  % cl: record the value for each selection.
  % temp: record the index for each selection.
  % cp(temp',:): select relevant rows (see piture)

  [cl,temp] = min(cl*ones(1,size(V{n},1))+d,[],1);	% [*] see above
  cl = cl';
  cp = [cp(temp',:) (1:size(V{n},1))'];
end

% Backtracing
[l,temp] = min(cl);
index = cp(temp,:);      % Local index of selected modes for each frame
path = zeros(N,D);
for n=1:N
  path(n,:) = V{n}(index(n),:);
end


