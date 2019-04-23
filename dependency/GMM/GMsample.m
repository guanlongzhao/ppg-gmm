% [Y,pY] = GMsample(N,mu,S[,pm,o]) Samples from a Gaussian mixture
%
% In:
%   N: number of samples to generate.
%   mu,S,pm,o: see GMpdf.m
% Out:
%   Y: NxD matrix containing the samples rowwise.
%   pY: Nx1 vector containing the values of p(x) at the samples.
%
% Any non-mandatory argument can be given the value [] to force it to take
% its default value.
%
% Copyright (c) 2006 by Miguel A. Carreira-Perpinan and Chao Qin

function [Y,pY] = GMsample(N,mu,S,pm,o)

[M,D] = size(mu);              % Number of components and dimensionality
cov_type = GMtype(mu,S);

% ---------- Argument defaults ----------
if ~exist('pm','var') | isempty(pm) pm = ones(M,1)/M; end;
if exist('o','var') & ~isempty(o)
  % Transform the parameters, then call the function again without "o"
  [pm,mu,S] = GMcondmarg(mu,S,pm,o);
  [Y,pY] = GMsample(N,mu,S,pm,[]);
  return;
end
% ---------- End of "argument defaults" ----------

% Generate N samples from a discrete distribution corresponding to pm and
% create its histogram of counts, Np.
u = rand(N,1); Np = zeros(size(pm));
accp = cumsum(pm); accp(M) = 1.1;	% To ensure that u(s)<accp(K)
for n=1:N
  c = M + 1 - sum(u(n)<accp); Np(c) = Np(c) + 1;
end

% Now Np(k) contains the number of samples to be generated from component m.
Y = [];
for m=1:M
  if Np(m)>0
    switch cov_type
     case 'F', [U,L] = eig(S(:,:,m));
     case 'i', [U,L] = eig(eye(D,D)*S);
     case 'I', [U,L] = eig(eye(D,D)*S(m));
     case 'd', [U,L] = eig(diag(S)); 
     case 'D', [U,L] = eig(diag(S(m,:)));
    end
    y = randn(Np(m),length(mu(m,:)))*sqrt(L)*U' + ones(Np(m),1)*mu(m,:);
    Y = [Y; y];
  end
end

if nargout>=2 pY = GMpdf(Y,mu,S,pm,[]); end;

