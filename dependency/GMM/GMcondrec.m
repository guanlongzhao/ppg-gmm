% [R,Rp,modes] = GMcondrec(T,mu,S,pm,P[,NS,w,params])
% Sequential data reconstruction from conditional probability distribution 
% for a Gaussian mixture
%
% Given a GM density model and a data set T, GMcondrec reconstructs T
% when some of the values of it are missing. Which are the missing values
% is indicated by the binary matrix P, which can be given in either of the
% two following ways:
% - For general missing-data patterns, a binary NxD matrix (same size as T),
%   where P(n,d) = 1 means that variable d at point T(n,:) is present (known
%   value) while P(n,d) = 0 means missing (unknown value).
%   We can characterise several useful problems as follows:
%   . P(n,I) = 1 and P(n,J) = 0 for all n: regression of t_J given t_I.
%   . P(n,d) = Bernoulli(p) for p\in\[0,1]: missing at random problem.
% - For regression problems, a cell array {I,J[,fwd]} where I and J list the
%   input and output variables, respectively, and optionally fwd is a function
%   handle for a forward mapping J->I (to use a forward mapping constraint).
%
% I and J are sets of indices in 1..D, corresponding to the indices of
% the desired variables of the regression. t_I represents the value of
% the variables from I (as a row vector) and t_J the value of the
% variables from J (as a row vector too).
%
% For example, if I = [1 3 4] and J = [2], then we are looking into
% the regression of t2 as a function of t1, t3 and t4. t = [t1 t2 t3 t4]
% would be the full vector in a data space of D=4 dimensions. I and
% J can be any sets of indices, not necessarily in order and its
% union does not have to be the full 1..D. However, the values of the
% variables in t_I and t_J must follow the same order, i.e. in the example
% before, t_I = [t1 t3 t4] and t_J = [t2]. And obviously I and J
% should not contain repeated or common elements.
%
% In:
%   T: NxD matrix with N observed space vectors stored rowwise.
%   mu,S,pm: see GMpdf.m
%   P: see above
%   NS: integer number > 0 containing the number of samples to take
%      from the conditional distribution (default 10).
%   w: 1xD vector containing the weights for the weighted Euclidean
%      distance (default: ones, i.e., unweighted Euclidean distance).
%   params: parameters for mode-finding
%
% Out:
%   R: struct array with one field per reconstruction method (NxD matrix):
%      .cmean: conditional mean
%      .gmode: global mode
%      .dpmode: all modes; continuity constraints, dynamic programming
%      .cmode: closest mode
%      .rmode: random mode
%      .sampdp: S samples from the conditional distribution; continuity 
%        constraints, dynamic programming
%      .meandp: conditional mean for unimodal distributions and modes 
%        otherwise; continuity constraints, dynamic programming
%   Rp: Like R but with mode weights. 
%   modes: Nx1 cell array containing all the modes of the conditional
%          distribution p(tJ|tI) for every point in T, rowwise.

% Copyright (c) 2010 by Miguel A. Carreira-Perpinan and Chao Qin

function [R,Rp,modes] = GMcondrec(T,mu,S,pm,P,NS,w,params)

[N,D] = size(T);
fwd = [];

% ---------------- Argument defaults ---------------
if iscell(P)
  if length(P)>2 fwd = P{3}; end;                 % Forward mapping
  tmp = ones(size(T)); tmp(:,P{2}) = 0; P = tmp; % Obtain missing data mask
end  
if ~exist('NS','var') | isempty(NS) NS = 10; end;
if ~exist('w','var') | isempty(w) w = ones(1,D); end;
if ~exist('params','var') | isempty(params) 
  params.tol = 1e-3; 
  params.maxit = 1e+3; 
  params.min_diff = 1e-1;
  params.max_eig = 0; 
  params.threshold = 1/25;
end
% ---------- End of "argument defaults" ------------

% For the "random mode" and "samples from conditional distribution" methods
rand('state',sum(100*clock));

% Initialization
modes = cell(N,1); pmodes = cell(N,1);
meanmodes = cell(N,1); pmeanmodes = cell(N,1);
% nsamples will be either 1 (no variable missing) or S (some values missing).
samples = cell(N,1); psamples = cell(N,1);
cmean = T; gmode = cmean; cmode = cmean; rmode = cmean;

% If at some n, all components are missing, then the mode calculation 
% is extended to the whole observed space and becomes very slow. 
% Thus, we compute it once if necessary and store it for reuse in Ym. 
Ym = [];
for n=1:N
  I = find(P(n,:)); J = setdiff(1:D,I);
  if isempty(J)			    % No missing values
    tI = T(n,I);
    modes{n} = tI; pmodes{n} = 0;
    meanmodes{n} = tI; pmeanmodes{n} = 0;
    samples{n} = tI; psamples{n} = 0;
    cmean(n,:) = tI; gmode(n,:) = tI; cmode(n,:) = tI; rmode(n,:) = tI;
  else
    tI = T(n,I); tJ = T(n,J);
    o.P = I; o.M = J;
    o.xP = tI;
    if isempty(I)        % indicate no observed variable
      if isempty(Ym)     % trick: save time as all arguments are same
        [Ym,ptemp] = GMmodes(mu,S,pm,[]);        % All modes of p(J|I)
      end
      temp = Ym;					% Precomputed
      tempp = ptemp;
    else                 % indicate general case
      [temp,tempp] = GMmodes(mu,S,pm,o,params.tol,params.maxit,...
         params.min_diff,params.max_eig,params.threshold);	% All modes of p(J|I)
    end

    nmodes = length(temp(:,1));		% Number of modes
    temp2 = zeros(nmodes,D);
    % Clone the original raw vector of observed variables
    if ~isempty(I)
      temp2(:,I) = tI(ones(nmodes,1),:);
    end
    temp2(:,J) = temp;
    modes{n} = temp2;				% Add modes to list
    pmodes{n} = tempp;
    
    [cmean(n,J),Ccmean,temppmean] = GMmoments(mu,S,pm,o);   % Mean of p(J|I)
    if nmodes==1					    % Unimodal cond.dist.
      meanmodes{n} = cmean(n,:);		            % Just add the mean
      pmeanmodes{n} = temppmean;
    else						    % Multimodal cond.dist.
      meanmodes{n} = temp2;			% Like with modes
      pmeanmodes{n} = tempp;
    end

    gmode(n,J) = temp(1,:);				% Global mode of p(J|I)

    [temp1,temp2] = min(sum((temp-tJ(ones(nmodes,1),:)).^2,2));
    cmode(n,J) = temp(temp2,:);		% Closest mode (Euclidean distance)

    rmode(n,J) = temp(floor(rand*nmodes)+1,:);	% Random mode
   
    temp3 = zeros(NS,D);
    if ~isempty(I)
      temp3(:,I) = tI(ones(NS,1),:);
    end;
    [temp3(:,J),temppsamp] = GMsample(NS,mu,S,pm,o);
    samples{n} = temp3;
    psamples{n} = temppsamp;
  end
end

% Greedy and dynamic programming searches (with optional weights)
dpmode = shp_dp(modes,{fwd,I},w);       % Dynamic programming search
meandp = shp_dp(meanmodes,{fwd,I},w);
sampdp = shp_dp(samples,{fwd,I},w);

[R.cmean,R.gmode,R.dpmode,R.cmode,R.rmode,R.sampdp,R.meandp] = ...
  deal(cmean,gmode,dpmode,cmode,rmode,sampdp,meandp);

% Same but integrating the mode weights into dynamic programming
dpmode = shp_dp(modes,{fwd,I},w,pmodes);
meandp = shp_dp(meanmodes,{fwd,I},w,pmeanmodes);
sampdp = shp_dp(samples,{fwd,I},w,psamples);
[Rp.cmean,Rp.gmode,Rp.dpmode,Rp.cmode,Rp.rmode,Rp.sampdp,Rp.meandp] = ...
  deal(cmean,gmode,dpmode,cmode,rmode,sampdp,meandp);


