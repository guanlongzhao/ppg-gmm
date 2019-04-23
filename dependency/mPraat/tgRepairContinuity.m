function tgNew = tgRepairContinuity(tg, verbose)
% function tgNew = tgInsertNewIntervalTier(tg, verbose)
%
% Repairs problem of continuity of T2 and T1 in interval tiers. This
% problem is very rare and it should not appear. However, e.g., 
% automatic segmentation tool Prague Labeller produces random numeric
% round-up errors featuring, e.g., T2 of preceding interval is slightly
% higher than the T1 of the current interval. Because of that, the boundary
% cannot be manually moved in Praat edit window.
% 
% verbose ... [optional] if true, the function performs everything quietly.
%
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   tgProblem = tgRead('demo/H_problem.TextGrid');
%   tgNew = tgRepairContinuity(tgProblem);
%   tgWrite(tgNew, 'demo/H_problem_OK.TextGrid');



if nargin ~= 1 && nargin ~= 2
    error('Wrong number of arguments.')
end

if nargin == 1
    verbose = false;
end

ntiers = tgGetNumberOfTiers(tg);

tgNew = tg;

for I = 1: ntiers
    if strcmp(tgNew.tier{I}.type, 'interval') == 1
        for J = 1: length(tgNew.tier{I}.Label)-1
            if tgNew.tier{I}.T2(J) ~= tgNew.tier{I}.T1(J+1)
                newVal = mean([tgNew.tier{I}.T2(J), tgNew.tier{I}.T1(J+1)]);
                if ~verbose
                    disp(['Problem found [tier: ', num2str(I), ', int: ', num2str(J), ', ', num2str(J+1), '] t2 = ', sprintf('%.12f', tgNew.tier{I}.T2(J)), ...
                        ', t1 = ', sprintf('%.12f', tgNew.tier{I}.T1(J+1)), '. New value: ', sprintf('%.12f', newVal), '.'])
                end

                tgNew.tier{I}.T2(J) = newVal;
                tgNew.tier{I}.T1(J+1) = newVal;
            end
        end
    end
end
