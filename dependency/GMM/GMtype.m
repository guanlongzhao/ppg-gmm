% cov_type = GMtype(mu,S) Determine the covariance type of a Gaussian mixture
%
% In:
%   mu,S: see GMpdf.m
% Out: 
%   cov_type: one of
%      'F': full covariance, heteroscedastic;
%      'D': diagonal covariance, heteroscedastic;
%      'd': diagonal covariance, homoscedastic;
%      'I': isotropic covariance, heteroscedastic;
%      'i': isotropic covariance, homoscedastic.
%
% Copyright (c) 2006 by Miguel A. Carreira-Perpinan and Chao Qin

function cov_type = GMtype(mu,S)

[M,D] = size(mu);

if length(size(S))==3
  cov_type = 'F';
elseif (size(S,1)==1) & (size(S,2)==1)
  cov_type = 'i';
elseif (size(S,1)==M) & (size(S,2)==1)
  cov_type = 'I';
elseif (size(S,1)==1) & (size(S,2)==D)
  cov_type = 'd';
elseif (size(S,1)==M) & (size(S,2)==D)
  cov_type = 'D';
elseif (size(S,1)==D) & (size(S,2)==D)
  cov_type = 'F';
else
  disp('GMtype error!');
end

