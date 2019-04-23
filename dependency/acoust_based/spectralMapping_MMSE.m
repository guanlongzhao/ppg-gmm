function [targetMFCCs_MMSE] =spectralMapping_MMSE(test_MFCC,mix)

% using approximation method to estimate minimum mean square error estimate 
% as described in Toda Black Tokuda Voice conversion 2008 paper

% number of mixture comoponents
M = mix.ncentres;
% indeces to X and Y variable in the mixture model
x_ind = 1:size(test_MFCC,2); y_ind = (size(test_MFCC,2)+1):mix.nin;
% get MMSE estimate as initial guess
T = size(test_MFCC,1); % number of frames
D = length(y_ind)/2;  % dimension of y ie 24 in our case.

o.P= [];o.M=1:size(test_MFCC,2); % calculate probability p(X) % marginalize over all Y
[~,~,~,pm_x] = GMpdf_SA_test(test_MFCC,mix.centres, mix.covars ,mix.priors',o); % pm_x gives me the p(m|X)
%  [p,px_m,pxm,pm_x] = GMpdf(test_Ar ...
% get the suboptimum sequence of mixture using argmax(p(m|x,model))
% [~,m_hat] =max(pm_x, [],2);
% 2b mmse --  use MMSE criteria to estimate MFCC
% for each mixture find the Expected value of y for each time frame

Ey_xm = nan(2*D,T,M);
% DY_m = nan(2*D,2*D,M);
% Dy_m_inv = DY_m;
for i = 1:mix.ncentres
    % E(y)
    muY_m = mix.centres(i,y_ind)';
    switch mix.covar_type
        case 'full'
            covYX_m = mix.covars(y_ind,x_ind,i);
            covXX_m = mix.covars(x_ind,x_ind,i);
           % covXY_m = mix.covars(x_ind,y_ind,i);
           % covYY_m = mix.covars(y_ind,y_ind,i);
           % DY_m(:,:,i) = covYY_m-covYX_m/covXX_m*covXY_m;
           % Dy_m_inv(:,:,i) = inv(DY_m(:,:,i));
            
        case 'diag'
            covYX_m = zeros(length(y_ind),length(x_ind));
            covXX_m = diag(mix.covars(i,x_ind));
           % covXY_m = zeros(length(x_ind),length(y_ind));
           % covYY_m = diag(mix.covars(i,y_ind));
           % DY_m(:,:,i) = covYY_m;
           % Dy_m_inv(:,:,i) = inv(DY_m(:,:,i));
    end
    % equation 11 from Toda voice conversion paper
    dist_fromMix_center = test_MFCC' - repmat(mix.centres(i,x_ind)',1,T);
    Ey_xm(:,:,i) = repmat(muY_m,1,T) + (covYX_m/covXX_m)*dist_fromMix_center;
end
% sum up the Ey weighted with priors pm_x to get MMSE estimate which will
% be used as initial point for EM iteration
% equation 13  pm_x = 390*128 calc sum of
Ymmse = sum(permute(reshape(repmat(pm_x,1,2*D),[size(pm_x), 2*D]), [3 1 2]).*Ey_xm,3 );

targetMFCCs_MMSE = reshape(Ymmse,numel(Ymmse)/T,T);


