function [PCCOEFF, PCVEC,EigVal] = snapShotPCA(data,num)
% function [PCCOEFF, PCVEC] = snapShotPCA(Data,n) 
% Data is MXN matrix where M is # of samples and N is number of features
% n is the number of principal components you want
% Calculates snap shot PCA when there are few examples and the numbers of
% features are very high
% 

% Caution: if there is variance in mean value of the data, snapshot PCA
% will ignore that because of the mean removal of each sample. 

mean_data = mean(data);
x_mean_removal = bsxfun(@minus,data, mean_data);
% outer product gives us the covariance matrix whose eigenvector components  are the
% weights for the weighted sum of images which gives us the eigen images. 
[vec,val]= eig(x_mean_removal*x_mean_removal');
% eigen images are weighted sum of images, where weights are components of
% eigVec "vec"
[EigVal, ind] = sort(diag(val),'descend');

PCVEC = vec(:,ind(1:num))'*x_mean_removal;
PCCOEFF = x_mean_removal*PCVEC';