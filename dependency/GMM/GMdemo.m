clear
close all
clc

% Parameters for a Gaussian mixture with 4 components in 2D
pm = [2 2 1 5]'; pm = pm/sum(pm); mu = [0 1;-2 5;-3 4;7 5];
S(:,:,1) = [1 0;0 2]; S(:,:,2) = [2 1;1 1];
S(:,:,3) = [0.2 0.1;0.1 1]; S(:,:,4) = [3 -1;-1 2];

% Range of the variables: [-5 10]x[0 7]
x1 = linspace(-5,10,200)'; x2 = linspace(0,7,200)';
[X1,X2] = meshgrid(x1,x2); X = [X1(:) X2(:)];

% Compute 2D pdf p(x) of x = (x1,x2) with GMpdf
[p,px_m,pxm] = GMpdf(X,mu,S,pm);

% Compute 1D conditional pdf p(x1|x2=6.8) with GMpdf
o1_2.P = 2; o1_2.M = 1; o1_2.xP = 6.8; p1_2 = GMpdf([x1 x1],mu,S,pm,o1_2);
% Its parameters, explicitly computed with GMcondmarg
[pm1_2,mu1_2,S1_2] = GMcondmarg(mu,S,pm,o1_2)

% Compute 1D marginal pdf p(x1) with GMpdf
o1.P = []; o1.M = 1; p1 = GMpdf([x1 x1],mu,S,pm,o1);

% Find modes of each pdf with GMmodes
modes = GMmodes(mu,S,pm);
[modes1_2,pmodes1_2] = GMmodes(mu,S,pm,o1_2);
[modes1,pmodes1] = GMmodes(mu,S,pm,o1);

% Compute moments with GMmoments
[M,C] = GMmoments(mu,S,pm)
[M,C] = GMmoments(mu,S,pm,o1_2)

% Compute gradient and Hessian with GMgradhess at some points
[g,H] = GMgradhess(modes(1,:),mu,S,pm)
[g,H] = GMgradhess([8 6],mu,S,pm)
[g,H] = GMgradhess(2.7,mu,S,pm,o1)

% Sample 350 points in 2D with GMsample
Y = GMsample(350,mu,S,pm);

% Plot results in 2D and 1D
figure(1); contour(X1,X2,reshape(p,size(X1)),30);
hold on; plot(mu(:,1),mu(:,2),'k+',modes(:,1),modes(:,2),'ko'); hold off;
set(gca,'DataAspectRatio',[1 1 1]);
figure(2);
plot(x1,p1_2,'b-',x1,p1,'r-',modes1_2,pmodes1_2,'ko',modes1,pmodes1,'ko');
figure(3); plot(Y(:,1),Y(:,2),'k*'); set(gca,'DataAspectRatio',[1 1 1]);

