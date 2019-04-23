% [p,px_m,pxm,pm_x] = GMpdf_SA_test_gpu(X,mu,S[,pm,o]) Gaussian mixture pdf
%
% Computes the value of p(x) for each point in X, where p(x) is a Gaussian
% mixture with parameters {mu,S,pm}; these parameters are explained below.
% The struct array o allows marginalisation and conditioning, e.g.
% - o.P = [2 4], o.xP = [-1.2 2.3], o.M = [3]: p(x3|x2,x4 = [-1.2 2.3]).
% - o.P = [], o.M = [1 4]: p(x1,x4).
%
% In:
%   X: NxD matrix containing N D-dimensional points rowwise. Note: this must 
%      have D columns even if o.M has fewer than D variables.
%   mu: MxD matrix containing M D-dimensional centroids rowwise.
%      This sets the master values for M and D.
%   S: mixture covariances, coded as follows:
%      - S is DxDxM: full covariance, heteroscedastic;
%      - S is MxD: diagonal covariance, heteroscedastic;
%      - S is 1xD: diagonal covariance, homoscedastic;
%      - S is Mx1: isotropic covariance, heteroscedastic;
%      - S is 1x1: isotropic covariance, homoscedastic.
%   pm: Mx1 list containing the mixing proportions of the mixture.
%      Default: ones(M,1)/M.
%   o: struct array containing: 
%      - P: subset of 1..D indicating what variables are present, i.e.,
%        we condition on. 
%      - xP: 1x? vector containing the values of the present variables.
%      - M: subset of 1..D indicating what variables are missing, i.e.,
%        neither present nor marginalised over.
%      Default: o.P = [], o.M = 1..D.
% Out:
%   p: Nx1 list of values of the probability density p(x) at X.
%   px_m: NxM list of values of the forward probability p(x|m) at X.
%   pxm: NxM list of values of the joint probability p(x,m) at X.
%   pm_x: NxM list of values of the posterior probability p(m|x) at X.
%
% Any non-mandatory argument can be given the value [] to force it to take
% its default value.
%
% Copyright (c) 2006 by Miguel A. Carreira-Perpinan and Chao Qin

function [p,px_m,pxm,pm_x] = GMpdf_SA_test_gpu(X,mu,S,pm,o)

[M,D] = size(mu);		% Number of components and dimensionality
N = size(X,1);

% ---------- Argument defaults ----------
if ~exist('pm','var') | isempty(pm) pm = ones(M,1)/M; end;
if exist('o','var') & ~isempty(o)
  % Transform parameters, then call the function again without "o"
  [pm,mu,S] = GMcondmarg(mu,S,pm,o);
  [p,px_m,pxm,pm_x] = GMpdf_SA_test_gpu(X(:,o.M),mu,S,pm,[]);
  return;
end
% ---------- End of "argument defaults" ----------

switch GMtype(mu,S)
 case 'F'
  normal = (2*pi)^(D/2);
  for m = 1:M
    diffs = bsxfun(@minus,X,mu(m,:));
    % Use spectral decomposition of the covariance matrix to speed computation
    [U,L] = eig(S(:,:,m)); L = diag(L);
    temp = diffs*U*diag(L.^(-1/2));
    ptemp(:,m) = exp(-0.5*sum(temp.^2,2))/(normal*prod(sqrt(L)));
  end
 case 'i'
  ptemp = (2*pi*S)^(-D/2)*exp(-sqdist(X,mu)/S/2);
 case 'I'
  ptemp = exp(-sqdist(X,mu)*diag(sparse(S.^(-1)))./2)*...
          diag(sparse((2*pi*S).^(-D/2)));
 case 'd'
  for m = 1:M
    diffs = bsxfun(@minus,X,mu(m,:));
    ptemp(:,m) = exp(-0.5*sum(diffs.^2/diag(sparse(S)),2))...
                    ./((2*pi)^(D/2)*prod(sqrt(S),2));
  end
 case 'D'
  normal = (2*pi)^(D/2);
  s = prod(sqrt(S),2);
  for m = 1:M
    diffs = bsxfun(@minus,X,mu(m,:));
    ptemp(:,m) = exp(-0.5*sum(diffs.^2/diag(S(m,:)),2))./(normal*s(m));
  end
end

p = ptemp*pm;  
if nargout>=2 px_m = ptemp; end;  % add eps in pxm to avoid division by zero down the line
if nargout>=3 pxm = px_m*diag(pm); end; 
if nargout>=4 
  if any(p<eps)
    pm_x = full(diag(sparse((p+eps).^(-1)))*pxm);  % pm_x is not normalized here 
  else
    pm_x = full(diag(p.^(-1))*pxm);    
  end;
   pm_x(sum(pm_x,2)==0,:) =0;
   pm_x (find(sum(pm_x,2)),:) = bsxfun(@rdivide,pm_x(find(sum(pm_x,2)),:),sum(pm_x(find(sum(pm_x,2)),:),2)); % normalize pm_x ; none of the sum(pm_x,2) == 0
end
