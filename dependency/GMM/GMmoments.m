% [Mean,C,pMean] = GMmoments(mu,S[,pm,o]) Gaussian mixture moments
%
% Compute the mean and covariance matrix of a Gaussian mixture, defined as:
%    p(x) = \sum^M_{m=1}{p(m) p(x|m)}
% where p(x|m) is a Gaussian distribution of mean mu(m) and covariance S.
%
% Actually this function is valid for any mixture, not just Gaussian.
%
% In:
%   mu,S,pm,o: see GMpdf.m.
% Out:
%   Mean: 1xD vector containing the mean.
%   C: DxD symmetric positive definite matrix containing the covariance.
%   pMean: real number containing the value of p(x) at the mean.
%
% Any non-mandatory argument can be given the value [] to force it to take
% its default value.
%
% Copyright (c) 2006 by Miguel A. Carreira-Perpinan and Chao Qin

function [Mean,C,pMean] = GMmoments(mu,S,pm,o)

[M,D] = size(mu);

% ---------- Argument defaults ----------
if ~exist('pm','var') | isempty(pm) pm = ones(M,1)/M; end;
if exist('o','var') & ~isempty(o)
  % Transform parameters, then call the function again without "o"
  [pm,mu,S] = GMcondmarg(mu,S,pm,o);
  [Mean,C,pMean] = GMmoments(mu,S,pm,[]);
  return;
end
% ---------- End of "argument defaults" ----------

Mean = pm'*mu;
C = - Mean'*Mean;

if nargout>=2
  switch GMtype(mu,S)
   case 'F'
    for m=1:M
      C = C + pm(m)*(S(:,:,m)+mu(m,:)'*mu(m,:));
    end
   case 'i'
    C = C + S*eye(D,D);
    for m=1:M
      C = C + pm(m)*mu(m,:)'*mu(m,:);
    end
   case 'I'
    for m=1:M
      C = C + pm(m)*(S(m)*eye(D,D)+mu(m,:)'*mu(m,:));
    end
   case 'd'
    C = C + diag(S);
    for m=1:M
      C = C + pm(m)*mu(m,:)'*mu(m,:);
    end
   case 'D'
    for m=1:M
      C = C + pm(m)*(diag(S(m,:))+mu(m,:)'*mu(m,:));
    end
  end
end
if nargout>=3 pMean = GMpdf(Mean,mu,S,pm,[]); end;

