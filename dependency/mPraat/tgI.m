function I = tgI(tg, tierIndexOrName)
% function n = tgGetTierName(tg, tierIndexOrName)
%
% Returns index of tier. If the input is index, it controls it exists in
% the TextGrid and returns the same number. It the input is character name,
% it search the TextGrid and return the index of the first tier with that
% name.
% 
% tierIndexOrName ... tier index or 'name'
%
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgI(tg, 'word')
%   tgI(tg, 2)

if nargin ~= 2
    error('Wrong number of arguments.')
end


ntiers = length(tg.tier);

if isnumeric(tierIndexOrName) && isequal(size(tierIndexOrName), [1,1])   % it is numeric index
    if tierIndexOrName >= 1 && tierIndexOrName <= ntiers
        if ~isInt(tierIndexOrName)
            error('tier index have to be an integer value')
        end
        
        I = tierIndexOrName;
        return
    else
        error(['tier index out of range, tierInd = ' num2str(tierIndexOrName) ', ntiers = ' num2str(ntiers)])
    end
end


if ischar(tierIndexOrName) && size(tierIndexOrName, 1) == 1   % it is character name
    for J = 1: ntiers
        if strcmp(tg.tier{J}.name, tierIndexOrName) == 1
            I = J;
            return
        end
    end
    
    error(['Tier name not found: [' tierIndexOrName  ']'])
else
    error('Incorrect tierIndexOrName format, it has to be either tier index or tier name.')
end

