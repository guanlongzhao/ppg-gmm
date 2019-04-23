Gaussian mixture Matlab tools

(C) 2009 by Miguel A. Carreira-Perpinan and Chao Qin
    Electrical Engineering and Computer Science
    University of California, Merced
    http://eecs.ucmerced.edu


The functions listed below perform common operations with Gaussian
mixtures (GMs). See each function for usage instructions, in particular
GMpdf has a description of most of the arguments. File demo.m demonstrates
all the functions.

Most functions admit an argument "o" with fields o.P, o.M and o.xP so that
the density p(o.M|o.P=o.xP) is used, thus allowing to use conditional and
marginal densities. For example:
- o.P = [2 4], o.xP = [-1.2 2.3], o.M = [3]: p(x3|x2,x4 = [-1.2 2.3]).
- o.P = [], o.M = [1 4]: p(x1,x4).

List of functions:
- GMpdf: computes the GM density at a list of given points.
- GMcondmarg: computes the parameters of a conditional or marginal GM.
- GMsample: samples N points from a GM.
- GMgradhess: computes the gradient & Hessian of the GM pdf at a given point.
- GMmodes: finds all the modes of a GM with a fixed-point algorithm
  (mean-shift).
- GMmoments: computes the moments (mean, covariance matrix) of a GM.

The following are used internally by other functions:
- GMtype: determines the covariance type of a GM.
- sqdist: computes the matrix of Euclidean squared distances between two point sets.
- shp_dp: computes the shortest path in a layered graph by dynamic programming
