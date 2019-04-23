% Copyright 2019 Guanlong Zhao
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

% only MLPG
function [targetMFCCs_GV_EM] =spectralMapping_MLPG(test_MFCC,mix)

% The trajectory optimization methd considering the dynamics and GVs 
% as described in Toda et al. voice conversion paper, 2008

% number of mixture comoponents
M = mix.ncentres;
% indeces to X and Y variable in the mixture model
x_ind = 1:size(test_MFCC,2); y_ind = (size(test_MFCC,2)+1):mix.nin;
% get MMSE estimate as initial guess
T = size(test_MFCC,1); % number of frames
D = length(y_ind)/2;  % dimension of y ie 24 in our case.

o.P= [];o.M=1:size(test_MFCC,2); % calculate probability p(X) % marginalize over all Y
[~,~,~,pm_x] = GMpdf_SA_test(test_MFCC,mix.centres, mix.covars ,mix.priors',o); % pm_x gives me the p(m|X)
disp('calculate probability p(m|X)')
%  [p,px_m,pxm,pm_x] = GMpdf(test_Ar ...
% get the suboptimum sequence of mixture using argmax(p(m|x,model))
[~,m_hat] =max(pm_x, [],2);
% 2b mmse --  use MMSE criteria to estimate MFCC
% for each mixture find the Expected value of y for each time frame

Ey_xm = nan(2*D,T,M);
DY_m = nan(2*D,2*D,M);
Dy_m_inv = DY_m;
for i = 1:mix.ncentres
    % E(y)
    muY_m = mix.centres(i,y_ind)';
    switch mix.covar_type
        case 'full'
            covYX_m = mix.covars(y_ind,x_ind,i);
            covXX_m = mix.covars(x_ind,x_ind,i);
            covXY_m = mix.covars(x_ind,y_ind,i);
            covYY_m = mix.covars(y_ind,y_ind,i);
            DY_m(:,:,i) = covYY_m-covYX_m/covXX_m*covXY_m;
            Dy_m_inv(:,:,i) = inv(DY_m(:,:,i));
            
        case 'diag'
            covYX_m = zeros(length(y_ind),length(x_ind));
            covXX_m = diag(mix.covars(i,x_ind));
            covXY_m = zeros(length(x_ind),length(y_ind));
            covYY_m = diag(mix.covars(i,y_ind));
            DY_m(:,:,i) = covYY_m;
            Dy_m_inv(:,:,i) = inv(DY_m(:,:,i));
    end
    % equation 11 from Toda voice conversion paper
    dist_fromMix_center = test_MFCC' - repmat(mix.centres(i,x_ind)',1,T);
    Ey_xm(:,:,i) = repmat(muY_m,1,T) + (covYX_m/covXX_m)*dist_fromMix_center;
end
% sum up the Ey weighted with priors pm_x to get MMSE estimate which will
% be used as initial point for EM iteration
% equation 13  pm_x = 390*128 calc sum of
Ymmse = sum(permute(reshape(repmat(pm_x,1,2*D),[size(pm_x), 2*D]), [3 1 2]).*Ey_xm,3 );
disp('done with the MMSE portion')

% done with the MMSE portion
% -------------------------------------------------------
%% MLE with dynamic - First get the approximation then use EM to improve the result
% get the W matrix such that Y=Wy where Y is the combination of acoustic
% features y and del_y
% d1ker = [ 1 -8   0  8 -1]/12;
% eye_W= eye(T);
% delta_multiplierMat = conv2(eye(T), d1ker, 'same');
% W_elem = reshape([eye_W(:) ,delta_multiplierMat(:) ]', 2*T, T);
% sparse matrix implementation to make it faster (?)
W = generateW(T, D);
% W = sparse(2*D*T,D*T);
% for i_row = 1:2*T
    % for i_col = 1:T
        % diagElemInd_row = (i_row-1)*D+(1:D);
        % diagElemInd_col = (i_col-1)*D+(1:D);
        % W(diagElemInd_row, diagElemInd_col) = W_elem(i_row,i_col).*sparse(1:D,1:D,1);
    % end
% end
disp('done with W')

DY_invBar = sparse( 2*D*T,2*D*T); % block diagonal matrix of DYt_invBar from each frame
DYt_inv_EYtBar = nan(size(Ymmse));
for t_sample = 1:size(test_MFCC,1)
    % calculate mean and Variance of Y using suboptimum most likely
    % mixture sequence for a given sequence of articulatory sequence
    DYt_inv_EYtBar(:,t_sample)= squeeze(Dy_m_inv(:,:,m_hat(t_sample)))*squeeze(Ey_xm(:,t_sample,m_hat(t_sample)));
    diagElemInd = (t_sample-1)*2*D+(1:2*D);
    DY_invBar(diagElemInd, diagElemInd) = Dy_m_inv(:,:,m_hat(t_sample));
end

DY_inv_EYBar = reshape( DYt_inv_EYtBar, numel(DYt_inv_EYtBar),1);

y_newSerial = (W'*DY_invBar*W)\(W'*DY_inv_EYBar);
Y_MLE_wDel_approx = reshape(y_newSerial,numel(y_newSerial)/T,T);
targetMFCCs_GV_EM = Y_MLE_wDel_approx;
disp('done with the approximation')
end