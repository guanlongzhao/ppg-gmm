function tgWrite(tgrid, fileNameTextGrid)
% function tgWrite(tgrid, fileNameTextGrid)
%
% Saves TextGrid to the file. TextGrid may contain both interval and point
% tiers (.tier{1}, .tier{2}, etc.). If tier type is not specified in .type,
% is is assumed to be interval. If specified, .type have to be 'interval' or 'point'.
% If there is no .tmin and .tmax, they are calculated as min and max of
% all tiers. The file is saved in Short text file, UTF-8 format.
% v1.5 Tomas Boril, borilt@gmail.com
% 
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgPlot(tg);
%   tgWrite(tg, 'demo/ex_output.TextGrid');

nTiers = length(tgrid.tier);  % number of Tiers

minTimeTotal = NaN;
maxTimeTotal = NaN;
if isfield(tgrid, 'tmin') && isfield(tgrid, 'tmax')
    minTimeTotal = tgrid.tmin;
    maxTimeTotal = tgrid.tmax;
end

for I = 1: nTiers
    if isfield(tgrid.tier{I}, 'type')
        if strcmp(tgrid.tier{I}.type, 'interval') == 1
            typInt = true;
        elseif strcmp(tgrid.tier{I}.type, 'point') == 1
            typInt = false;
        else
            error(['unknown tier type [' tgrid.tier{I}.type ']']);
        end
    else
        typInt = true;
    end
    tgrid.tier{I}.typInt = typInt;
    
    if typInt == true
        nInt = length(tgrid.tier{I}.T1); % number of intervals
        if nInt > 0
            minTimeTotal = min(tgrid.tier{I}.T1(1), minTimeTotal);
            maxTimeTotal = max(tgrid.tier{I}.T2(end), maxTimeTotal);
        end
    else
        nInt = length(tgrid.tier{I}.T); % number of points
        if nInt > 0
            minTimeTotal = min(tgrid.tier{I}.T(1), minTimeTotal);
            maxTimeTotal = max(tgrid.tier{I}.T(end), maxTimeTotal);
        end
    end
end

[fid, message] = fopen(fileNameTextGrid, 'w', 'ieee-be', 'UTF-8');
if fid == -1
    error(['cannot open file [' fileNameTextGrid ']: ' message]);
end

fprintf(fid, 'File type = "ooTextFile"\n');
fprintf(fid, 'Object class = "TextGrid"\n');
fprintf(fid, '\n');
fprintf(fid, '%.17f\n', minTimeTotal); 
fprintf(fid, '%.17f\n', maxTimeTotal); 
fprintf(fid, '<exists>\n');
fprintf(fid, '%d\n', nTiers); 

for N = 1: nTiers
    if tgrid.tier{N}.typInt == true
        fprintf(fid, '"IntervalTier"\n');
        fprintf(fid, ['"' tgrid.tier{N}.name '"\n']);

        nInt = length(tgrid.tier{N}.T1); % number of intervals
        if nInt > 0
            fprintf(fid, '%.17f\n', tgrid.tier{N}.T1(1)); % start time of tier
            fprintf(fid, '%.17f\n', tgrid.tier{N}.T2(end)); % end time of tier
            fprintf(fid, '%d\n', nInt);  % number of intervals

            for I = 1: nInt
                fprintf(fid, '%.17f\n', tgrid.tier{N}.T1(I));
                fprintf(fid, '%.17f\n', tgrid.tier{N}.T2(I));
                fprintf(fid, '"%s"\n', tgrid.tier{N}.Label{I});
            end
        else % one empty interval only
            fprintf(fid, '%.17f\n', minTimeTotal); % start time of tier
            fprintf(fid, '%.17f\n', maxTimeTotal); % end time of tier
            fprintf(fid, '%d\n', 1);  % number of intervals
            fprintf(fid, '%.17f\n', minTimeTotal);
            fprintf(fid, '%.17f\n', maxTimeTotal);
            fprintf(fid, '""\n');
        end
    else % pointTier
        fprintf(fid, '"TextTier"\n');
        fprintf(fid, ['"' tgrid.tier{N}.name '"\n']);

        nInt = length(tgrid.tier{N}.T); % number of points
        if nInt > 0
            fprintf(fid, '%.17f\n', tgrid.tier{N}.T(1)); % start time of tier
            fprintf(fid, '%.17f\n', tgrid.tier{N}.T(end)); % end time of tier
            fprintf(fid, '%d\n', nInt);  % number of points

            for I = 1: nInt
                fprintf(fid, '%.17f\n', tgrid.tier{N}.T(I));
                fprintf(fid, '"%s"\n', tgrid.tier{N}.Label{I});
            end
        else % empty pointtier
            fprintf(fid, '%.17f\n', minTimeTotal); % start time of tier
            fprintf(fid, '%.17f\n', maxTimeTotal); % end time of tier
            fprintf(fid, '0\n');  % number of points
        end
    end

end
fclose(fid);

