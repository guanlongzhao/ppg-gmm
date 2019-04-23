function pt = ptRead(fileName)
% function pt = ptRead(fileName)
%
% Reads PitchTier from Praat. Supported formats: text file, short text file,
% spread sheet, headerless spread sheet (headerless not recommended,
% it does not contain tmin and tmax info).
% 
% fileName ... file name of PitchTier
%
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   pt = ptRead('demo/H.PitchTier');
%   ptPlot(pt);


pt = [];

[fid, message] = fopen(fileName, 'r', 'n', 'UTF-8');
if fid == -1
    error(['cannot open file [' fileName ']: ' message]);
end

r = fgetl(fid);  % 1.
if strcmp(r, '"ooTextFile"')    % spreadSheet
    r = fgetl(fid);  % 2.
    if ~strcmp(r, '"PitchTier"')
        fclose(fid);
        error('Unknown PitchTier format.')
    end
    
    r = fgetl(fid);  % 3.
    fromToN = strsplit(r);
    if length(fromToN) ~= 3
        fclose(fid);
        error('Unknown PitchTier format.')
    end
    xmin = str2double(fromToN{1});
    xmax = str2double(fromToN{2});
    N = str2double(fromToN{3});
    t = NaN*ones(1, N);
    f = NaN*ones(1, N);
    
    for I = 1: N
        r = fgetl(fid);
        tf = strsplit(r);
        if length(tf) ~= 2
            fclose(fid);
            error('Unknown PitchTier format.')
        end
        t(I) = str2double(tf{1});
        f(I) = str2double(tf{2});
    end
    fclose(fid);
    
elseif strcmp(r, 'File type = "ooTextFile"')  % TextFile or shortTextFile
    r = fgetl(fid);  % 2.
    if ~strcmp(r, 'Object class = "PitchTier"')
        fclose(fid);
        error('Unknown PitchTier format.')
    end
    
    r = fgetl(fid);  % 3.
    if ~strcmp(r, '')
        fclose(fid);
        error('Unknown PitchTier format.')
    end
    
    r = fgetl(fid);  % 4.
    if length(r) < 1
        fclose(fid);
        error('Unknown PitchTier format.')
    end
    
    if strcmp(r(1), 'x')   % TextFile
        xmin = str2double(r(8:end));
        r = fgetl(fid);  % 5.
        xmax = str2double(r(8:end));
        r = fgetl(fid);  % 6.
        N = str2double(r(16:end));
        
        t = NaN*ones(1, N);
        f = NaN*ones(1, N);
        
        for I = 1: N
            r = fgetl(fid);  % 7 + (I-1)*3
            r = fgetl(fid);  % 8 + (I-1)*3
            t(I) = str2double(r(14:end));
            r = fgetl(fid);  % 9 + (I-1)*3
            f(I) = str2double(r(13:end));
        end
        fclose(fid);
    else     % shortTextFile
        xmin = str2double(r);
        r = fgetl(fid);  % 5.
        xmax = str2double(r);
        r = fgetl(fid);  % 6.
        N = str2double(r);
        
        t = NaN*ones(1, N);
        f = NaN*ones(1, N);
        
        for I = 1: N
            r = fgetl(fid);  % 7 + (I-1)*2
            t(I) = str2double(r);
            r = fgetl(fid);  % 8 + (I-1)*2
            f(I) = str2double(r);
        end
        fclose(fid);
    end
    
else   % headerless SpreadSheet
    fclose(fid);
    tab = load(fileName, '-ascii');
    t = tab(:,1).';
    f = tab(:,2).';
    N = length(t);
    
    xmin = min(t);
    xmax = max(t);
end

pt.t = t;
pt.f = f;
pt.tmin = xmin;
pt.tmax = xmax;
