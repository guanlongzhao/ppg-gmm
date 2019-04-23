% similar to nchoosek() but give the same results as choose() in R for
% inputs like choose(-1/2, 0) etc.
% https://rosettacode.org/wiki/Evaluate_binomial_coefficients#MATLAB_.2F_Octave
function r = binomcoeff2(n,k)
   r = prod((n-k+1:n)./(1:k));
end