function textgrid = tgRead(fileName)
% function textgrid = tgRead(fileName)
%
% Loads TextGrid from Praat in Text or Short text format (UTF-8),
% it handles both Interval and Point tiers.
% Labels can may contain quotation marks and new lines.
% v1.5, Tomas Boril, borilt@gmail.com
% 
% Example
%   tg = tgRead('demo/H.TextGrid');
%   tgPlot(tg);

textgrid = [];

[fid, message] = fopen(fileName, 'r', 'n', 'UTF-8');
if fid == -1
    error(['cannot open file [' fileName ']: ' message]);
end

for I = 1: 3
    r = fgetl(fid); % ignore
end

xminStr = fgetl(fid); % xmin
xmaxStr = fgetl(fid); % xmax

r = fgetl(fid); % either '<exists>' -> shorttext or 'tiers? <exists> ' -> full text format
if strcmp(r, '<exists>')
    shortFormat = true;
elseif strcmp(r(1:6), 'tiers?')
    shortFormat = false;
else
    fclose(fid);
    error('Unknown textgrid format.');
end

if shortFormat
    xmin = str2double(xminStr); % xmin
    xmax = str2double(xmaxStr); % xmax
else
    xmin = str2double(xminStr(8:end)); % xmin
    xmax = str2double(xmaxStr(8:end)); % xmax
end

if shortFormat
    numberOfTiers = str2double(fgetl(fid));
else
    r = fgetl(fid);
    if r(end) ~= ' '
        sppasFormat = true;
    else
        sppasFormat = false;
    end
    r = textscan(r, 'size = %d');
    numberOfTiers = r{1};
end

for tier = 1: numberOfTiers
    if shortFormat
        typ = fgetl(fid);
    else
        r = strtrim(fgetl(fid));
        while strcmp(r(1:4), 'item') == 1
            r = strtrim(fgetl(fid));
        end
        if strcmp(r(1:9), 'class = "') ~= 1
            fclose(fid); error('unknown textgrid format');
        end
        typ = r(9:end);
    end
    if strcmp(typ, '"IntervalTier"') == 1  % IntervalTier
        r = fgetl(fid); % name
        if shortFormat
            textgrid.tier{tier}.name = r(2: end-1);
        else
            r = strtrim(r);
            textgrid.tier{tier}.name = r(9: end-1);
        end
        textgrid.tier{tier}.type = 'interval';

        r = fgetl(fid); % ignore xmin and xmax
        r = fgetl(fid);

        if shortFormat
            numberOfIntervals = str2double(fgetl(fid));
        else
            r = strtrim(fgetl(fid));
            numberOfIntervals = str2double(r(19:end));
        end
        
        textgrid.tier{tier}.T1 = [];
        textgrid.tier{tier}.T2 = [];
        textgrid.tier{tier}.Label = {};

        for I = 1: numberOfIntervals
            if ~shortFormat
                r = fgetl(fid); % ignore line intervals [..]:
            end
            
            if shortFormat
                t = str2double(fgetl(fid));
                t2 = str2double(fgetl(fid));
            else
                r1 = strtrim(fgetl(fid));
                r2 = strtrim(fgetl(fid));
                if strcmp(r1(1:7), 'xmin = ') ~= 1  ||  strcmp(r2(1:7), 'xmax = ') ~= 1
                    fclose(fid); error('unknown textgrid format');
                end
                t = str2double(r1(8:end));
                t2 = str2double(r2(8:end));
            end

            r = fgetl(fid);
            if ~shortFormat
                if isempty(strfind(r, 'text = "'))
                    fclose(fid); error('unknown textgrid format');
                end
                rind = strfind(r, '"');
                numberOfQuotationMarks = sum(r == '"');
                if mod(numberOfQuotationMarks, 2) ~= 1 % remove whitespace at the end of line, it is only in the case of even number of quotation marks
                    if sppasFormat ~= true
                        r = r(rind(1): end-1);
                    else
                        r = r(rind(1): end);
                    end
                else
                    r = r(rind(1): end);
                end
            end
            numberOfQuotationMarks = sum(r == '"');
            label = r(2:end);
            if mod(numberOfQuotationMarks, 2) == 1
                label = [label sprintf('\n')];
                while 1
                    r = fgetl(fid);
                    numberOfQuotationMarks = sum(r == '"');
                    if ~shortFormat && mod(numberOfQuotationMarks, 2) == 1 && ~sppasFormat % remove whitespace at the end of line, it is only in the case of odd number of quotation marks
                        r = r(1: end-1);
                    end

                    if mod(numberOfQuotationMarks, 2) == 1 && r(end) == '"'
                        label = [label r(1:end-1) '"'];
                        break
                    else
                        label = [label sprintf([r '\n'])];
                    end

                end
            end
            label = label(1: end-1);

            textgrid.tier{tier}.T1 = [textgrid.tier{tier}.T1 t];
            textgrid.tier{tier}.T2 = [textgrid.tier{tier}.T2 t2];
            textgrid.tier{tier}.Label{I, 1} = label; % trim quotation marks
            
            xmin = min(t, xmin); xmin = min(t2, xmin);
            xmax = max(t, xmax); xmax = max(t2, xmax);
        end
        
        
    elseif strcmp(typ, '"TextTier"') == 1  % PointTier
        r = fgetl(fid); % name
        if shortFormat
            textgrid.tier{tier}.name = r(2: end-1);
        else
            r = strtrim(r);
            textgrid.tier{tier}.name = r(9: end-1);
        end
        textgrid.tier{tier}.type = 'point';

        r = fgetl(fid); % ignore xmin and xmax
        r = fgetl(fid);

        if shortFormat
            numberOfIntervals = str2double(fgetl(fid));
        else
            r = strtrim(fgetl(fid));
            numberOfIntervals = str2double(r(16:end));
        end

        textgrid.tier{tier}.T = [];
        textgrid.tier{tier}.Label = {};

        for I = 1: numberOfIntervals
            if ~shortFormat
                r = fgetl(fid); % ignore line points [..]:
            end
            
            if shortFormat
                t = str2double(fgetl(fid));
            else
                r = strtrim(fgetl(fid));
                if strcmp(r(1:9), 'number = ') ~= 1
                    fclose(fid); error('unknown textgrid format');
                end
                t = str2double(r(10:end));
            end

            r = fgetl(fid);
            if ~shortFormat
                if isempty(strfind(r, 'mark = "'))
                    fclose(fid); error('unknown textgrid format');
                end
                rind = strfind(r, '"');
                numberOfQuotationMarks = sum(r == '"');
                if mod(numberOfQuotationMarks, 2) ~= 1 % remove whitespace at the end of line, it is only in the case of even number of quotation marks
                    if sppasFormat ~= true
                        r = r(rind(1): end-1);
                    else
                        r = r(rind(1): end);
                    end
                else
                    r = r(rind(1): end);
                end
            end
            numberOfQuotationMarks = sum(r == '"');
            label = r(2:end);
            if mod(numberOfQuotationMarks, 2) == 1
                label = [label sprintf('\n')];
                while 1
                    r = fgetl(fid);
                    numberOfQuotationMarks = sum(r == '"');
                    if ~shortFormat && mod(numberOfQuotationMarks, 2) == 1 && ~sppasFormat % remove whitespace at the end of line, it is only in the case of odd number of quotation marks
                        r = r(1: end-1);
                    end

                    if mod(numberOfQuotationMarks, 2) == 1 && r(end) == '"'
                        label = [label r(1:end-1) '"'];
                        break
                    else
                        label = [label sprintf([r '\n'])];
                    end

                end
            end
            label = label(1: end-1);

            textgrid.tier{tier}.T = [textgrid.tier{tier}.T t];
            textgrid.tier{tier}.Label{I, 1} = label; % trim quotation marks
            
            xmin = min(t, xmin);
            xmax = max(t, xmax);
        end
    else  % unknown tier
        fclose(fid);
        error('Unknown tier type - IntervalTier and PointTier are supported only.');
    end
    
end


fclose(fid);

textgrid.tmin = xmin;
textgrid.tmax = xmax;
