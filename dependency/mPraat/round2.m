function res = round2(x, order)
% function res = round2(x, order)
%
% Rounds to the specified order.
%
% x ... number to be rounded
% order ... 1 = units, 10 = tens, -1 = tenths, etc.
% 
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   round2(pi*100, -2)
%   round2(pi*100, 2)


res = round(x / 10^order) * 10^order;
