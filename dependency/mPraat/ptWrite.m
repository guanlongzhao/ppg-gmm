function ptWrite(pt, fileNamePitchtier)
% function ptWrite(pt, fileNamePitchtier)
%
% Saves PitchTier to file (spread sheet file format).
% pt is struct with at least 't' and 'f' fields (one dimensional matrices
% of the same length). If there are no 'tmin' and 'tmax' fields, there are
% set as min and max of 't' field.
% 
% fileNamePitchtier ... file name to be created
%
% v1.0, Tomas Boril, borilt@gmail.com
%
% Example
%   pt = ptRead('demo/H.PitchTier');
%   pt.f = 12*log(pt.f/100) / log(2);  % conversion of Hz to Semitones, reference 0 ST = 100 Hz.
%   ptPlot(pt); xlabel('Time (sec)'); ylabel('Frequency (ST)');
%   ptWrite(pt, 'demo/H_st.PitchTier')


if ~isfield(pt, 't') || ~isfield(pt, 'f')
    error('pt must be a structure with fields ''t'' and ''f'' and optionally ''tmin'' and ''tmax''')
end

if length(pt.t) ~= length(pt.f)
    error('t and f lengths mismatched.')
end
    
N = length(pt.t);

if ~isfield(pt, 'tmin')
    xmin = min(pt.t);
else
    xmin = pt.tmin;
end

if ~isfield(pt, 'tmax')
    xmax = max(pt.t);
else
    xmax = pt.tmax;
end


[fid, message] = fopen(fileNamePitchtier, 'w', 'ieee-be', 'UTF-8');
if fid == -1
    error(['cannot open file [' fileNamePitchTier ']: ' message]);
end


fprintf(fid, '"ooTextFile"\n');
fprintf(fid, '"PitchTier"\n');
fprintf(fid, [num2str(round2(xmin, -20)), ' ', num2str(round2(xmax, -20)), ' ', num2str(N), '\n']);

for n = 1: N
    fprintf(fid, [num2str(round2(pt.t(n), -20)), '\t', num2str(round2(pt.f(n), -20)), '\n']);
end

fclose(fid);
