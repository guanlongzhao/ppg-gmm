function [targetMFCCs_GV_EM] =spectralMapping_MLTrajGV(test_MFCC,mix,trUttGVs,nonSilenceFrames)

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
disp('done with the approximation')

% done with the approximation 
% --------------------------------------------------------------
%%  Now use EM iterative method to imporve the approximation results, also consider the global variance
% calculate mean and covars of utterance var_s
mu_gv = mean(trUttGVs);
inv_covar_v  = inv(cov(trUttGVs));

% use Y_MLE_wDel_approx with linear transformation given in equation 58 from the paper as y_0 to calculate the V' for approximation method
% that includes global variance.
y_hat_mean = repmat(mean(Y_MLE_wDel_approx(:,nonSilenceFrames),2)  ,1  ,T );
multiplier = repmat(  sqrt(mu_gv'./var(Y_MLE_wDel_approx(:,nonSilenceFrames),0,2))  ,1 ,T ) ;
y_prime_hat = multiplier.*(Y_MLE_wDel_approx-y_hat_mean) + y_hat_mean ;
disp('use Y_MLE_wDel_approx with linear transformation given in equation 58 from the paper as y_0 to calculate the V'' for approximation method')

y_newSerial = y_prime_hat(:);

disp('enter final step')
alpha = 0.01; % step size for steepest descent.
% figure(3), hold on;
for iter = 1:20 % maximum number of iterations
    % calculate del_y_newSerial
    Y_newSerial =W*y_newSerial; % new value of Y , iterate the process, get new pm_xy and continue
    Y = reshape(Y_newSerial,numel(Y_newSerial)/T,T);
    
    o.P= [];o.M=1:size(mix.centres,2); % calculate probability p(X,Y)
    [pxy,~,~,pm_xy] = GMpdf_SA_test([test_MFCC Y'],mix.centres, mix.covars ,mix.priors',o); % pm_XY gives me the p(m|X,Y)
       
    % get p(m,Y |X,model)
    % log likelihood of data
    mean(log(pxy));
    % log likelihood of GV
    % mean(log(mvnpdf(var(Y(1:D,nonSilenceFrames),0,2)', mu_gv,cov(trUttGVs))))
    
    DYt_inv_EYtBar = nan(size(Y));
    for t_sample = 1:size(test_MFCC,1)
        DY_inv_msum = zeros(length(y_ind),length(y_ind));
        DY_inv_EYt_msum = zeros(length(y_ind),1);
        for i_mix = 1:M
            DY_inv_msum = DY_inv_msum+ pm_xy(t_sample,i_mix).* Dy_m_inv(:,:,i_mix);
            DY_inv_EYt_msum = DY_inv_EYt_msum + pm_xy(t_sample,i_mix).* squeeze(Dy_m_inv(:,:,i_mix))*squeeze(Ey_xm(:,t_sample,i_mix));
        end
        
        DYt_inv_EYtBar(:,t_sample)= DY_inv_EYt_msum;
        % DY_invBar = blkdiag(DY_invBar, squeeze(DYt_invBar(:,:,t_sample)));
        % blkdiag is slow process
        diagElemInd = (t_sample-1)*2*D+(1:2*D);
        DY_invBar(diagElemInd, diagElemInd) = DY_inv_msum;
    end
    DY_inv_EYBar = reshape( DYt_inv_EYtBar, numel(DYt_inv_EYtBar),1);
    
    
    % now use the y_prime_hat and calculate v_prime as in eqn 55,54,
    
    % iterate multiple times to get the y_newserial that maximizes Q fxn
    Qold =0;
    %  iterate until Q keeps increasing or at most 20 iterations
    for j = 1:20 % maximum of 20 iteration of gradient descent - escape if improvement on Q is negligible
        y_hat = reshape(y_newSerial,numel(y_newSerial)/T,T);
        y_hat_mean = repmat(mean(y_hat(:,nonSilenceFrames),2)  ,1  ,T );
        var_y_hat_minus_mu_gv = repmat((var(y_hat(:,nonSilenceFrames),0,2)-mu_gv')  ,1 ,D ) ;
        multiplier = (-2/T)*diag( inv_covar_v*var_y_hat_minus_mu_gv);
        v_prime = repmat(multiplier,1,T).*(y_hat-y_hat_mean);
        % replace the v_prime on silent frames to be zero so they don't get inflated
        % to match the variance of the non silence sequence
        v_prime(:,setdiff(1:T,nonSilenceFrames)) = 0;
        v_prime_serial = v_prime(:);
        
        % steepest descent method to maximize the auxiliary function
        
        del_y_newSerial_1 = (1/(2*T))*(-(W'*DY_invBar*W*y_newSerial) + W'*DY_inv_EYBar) + v_prime_serial;
        % if delta value is larger than 5 times the absolute value (due to noise),we replace it with the original delta.
        rep_ind = find(abs(del_y_newSerial_1) > 5* abs(y_newSerial));
        del_y_newSerial_1(rep_ind) = sign(del_y_newSerial_1(rep_ind)).* abs(y_newSerial(rep_ind));
        
        y_newSerial(rep_ind,:) = y_newSerial(rep_ind,:) + alpha*del_y_newSerial_1(rep_ind,:);
        
        
        var_yhat = var(y_hat(:,nonSilenceFrames),0,2);
        Q = (-0.5)*y_newSerial'*(W'*DY_invBar*W)*y_newSerial + y_newSerial'*W'*DY_inv_EYBar ...
            +2*T*((-0.5)*var_yhat'*inv_covar_v*var_yhat + var_yhat'*inv_covar_v*mu_gv');
        if(abs(Q-Qold)<0.00001*Q)
            break;
        end
        Qold = Q;
        % var(y_newSerial(21+ 24*nonSilenceFrames)',0,2)
    end
    
end
disp('done')

targetMFCCs_GV_EM = reshape(Y_newSerial,numel(Y_newSerial)/T,T);



