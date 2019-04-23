% [pm1,mu1,S1] = GMcondmarg(mu,S[,pm,o])
% Compute the parameters for conditional or marginal Gaussian mixtures from
% the joint Gaussian mixture
%
% In:
%   mu,S,pm,o: see GMpdf.m.
% Out:
%   pm1,mu1,S1: GM parameters for the conditional or marginal.
%
% Any non-mandatory argument can be given the value [] to force it to take
% its default value.
%
% Copyright (c) 2006 by Miguel A. Carreira-Perpinan and Chao Qin

function [pm1,mu1,S1] = GMcondmarg(mu,S,pm,o)

[M,D] = size(mu);
I = o.P; J = o.M;
covar_type = GMtype(mu,S);

% ---------- Argument defaults ----------
if ~exist('o','var') | isempty(o)
  [pm1,mu1,S1] = deal(pm,mu,S); return;
end
% ---------- End of "argument defaults" ----------

if length(I)==0				% Marginal
  if length(J)==0 | length(J)==D
    [pm1,mu1,S1] = deal(pm,mu,S);
  else
    pm1 = pm;
    mu1 = mu(:,J);
    switch covar_type
     case 'F', S1 = S(J,J,:);
     case {'i','I'}, S1 = S;
     case 'd', S1 = S(J);
     case 'D', S1 = S(:,J);
    end
  end
else					% Conditional
  tI = o.xP;
  if length(I)+length(J)==D		% Direct
    % NOTE: we don't check for underflow in the exponentials
    switch covar_type
     case 'F'
      [p,ptI_m,ptIm,pm_tI] = GMpdf(tI,mu(:,I),S(I,I,:),pm,[]);
      for m=1:M
        mu1(m,:) = mu(m,J) + (S(I,J,m)'*(S(I,I,m)\(tI-mu(m,I))'))';
        S1(:,:,m) = S(J,J,m) - S(I,J,m)'*(S(I,I,m)\S(I,J,m));
      end
     case {'i','I'}
      [p,ptI_m,ptIm,pm_tI] = GMpdf(tI,mu(:,I),S,pm,[]);
      mu1 = mu(:,J); S1 = S;
     case 'd'
      [p,ptI_m,ptIm,pm_tI] = GMpdf(tI,mu(:,I),S(I),pm,[]);
      mu1 = mu(:,J); S1 = S(J);
     case 'D'
      [p,ptI_m,ptIm,pm_tI] = GMpdf(tI,mu(:,I),S(:,I),pm,[]);
      mu1 = mu(:,J); S1 = S(:,J);
    end
    pm1 = pm_tI';
  else                                     % Indirect
    % Do marginal
    o2.P = []; o2.M = [J I]; o2.xP = o.xP;
    [pm2,mu2,S2] = GMcondmarg(mu,S,pm,o2);
    % Reorder
    [temp1,o1.P] = intersect(o2.M,I); [temp1,o1.M] = intersect(o2.M,J);
    o1.xP = o.xP;
    % Do condition
    [pm1,mu1,S1] = GMcondmarg(mu2,S2,pm2,o1);
  end
end
