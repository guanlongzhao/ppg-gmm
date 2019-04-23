% [g,H] = GMgradhess(x,mu,S[,pm,o])
% Computes the gradient and the Hessian of a Gaussian mixture at point x
%
% In:
%   x: 1xD vector. Note: this must have D columns even if o.M has fewer than
%      D variables.
%   mu,S,pm,o: see GMpdf.m.
% Out:
%   g: Dx1 vector containing the gradient at x.
%   H: DxD matrix containing the Hessian at x.
%   
% Any non-mandatory argument can be given the value [] to force it to take
% its default value.
%
% Copyright (c) 2006 by Miguel A. Carreira-Perpinan and Chao Qin

function [g,H] = GMgradhess(x,mu,S,pm,o)

[M,D] = size(mu);		% Number of components and dimensionality

% ---------- Argument defaults ----------
if ~exist('pm','var') | isempty(pm) pm = ones(M,1)/M; end;
if exist('o','var') & ~isempty(o)
  % Transform parameters, then call the function again without "o"
  [pm,mu,S] = GMcondmarg(mu,S,pm,o);
  [g,H] = GMgradhess(x(:,o.M),mu,S,pm,[]);
  return;
end
% ---------- End of "argument defaults" ----------

[p,px_m,pxm,pm_x] = GMpdf(x,mu,S,pm,[]);
g = zeros(D,1); H = zeros(D,D);

switch GMtype(mu,S)
 case 'F'
  for m = 1:M
    S_inv(:,:,m) = inv(S(:,:,m));
    tt = S_inv(:,:,m)*(mu(m,:)-x)';
    g = g + pxm(m)*tt;
    H = H + pxm(m)*(tt*tt'-S_inv(:,:,m));
  end
 case 'D'
  for m=1:M
    tt = diag(1./S(m,:))*(mu(m,:)-x)';
    g = g + pxm(m)*tt;
    H = H + pxm(m)*(tt*tt'-diag(sparse(1./S(m,:))));
  end
 case 'd'
  S_inv = diag(1./S);
  for m=1:M
    tt = S_inv*(mu(m,:)-x)';
    g = g + pxm(m)*tt;
    H = H + pxm(m)*(tt*tt'-S_inv);
  end
 case 'I'
  for m=1:M
    tt = (eye(D,D)/S(m))*(mu(m,:)-x)';
    g = g + pxm(m)*tt;
    H = H + pxm(m)*(tt*tt'-speye(D,D)/S(m));
  end
 case 'i'
  mux = bsxfun(@minus,mu,x);
  g = mux'*pxm'/S;
  H = mux'*diag(sparse(pxm))*mux/S^2 - sum(pxm,2)*speye(D,D)/S;
end

