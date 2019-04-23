% dataPrep: This is the data preparation module for the GSB server.
% This module will convert a list of input audio files into pre-processed
% cache files.
%
% Assumptions:
%   - The Montreal Forced aligner is installed
%   - 'aligner', 'dictionary', and 'acousticModel' have beed configured
%   - The desired sampling frequency is 16KHz
%   - The PPG module is in '../dependency/kaldi-posteriorgram'
%   - Kaldi is installed and configured correctly
%   - Most of the files created by this function will have the file name in
%   a pre-defined format -- 'gsb_%04d.FileExtension' 
%
% Things that this function does:
%   - Convert the input audio to mono-channel by taking the first channel;
%   resample the audio to 16KHz; save the audio to the 'outputDir'
%   - Create individual transcription files from the input text file; all
%   transcriptions will be normalized to contain only digits, alphabets,
%   "'", and "-"
%   - Perform forced alignment and create TextGrid files
%   - Perform vocoder-related feature extraction
%   - Extract PPGs by calling Kaldi
%   - Compile output cache files and save them
%   - A log file will be created too
%
% Syntax: matList = dataPrep(wavList, transFile, outputDir)
%
% Inputs:
%   wavList: A cell array. Each cell contains the full path to a .wav file
%   transFile: A string. Path to the transcription file. Each line of this
%   file is the transcription of the corresponding .wav file
%   outputDir: A string. All output files will be saved under this dir
%
%   [Optional name-value pairs]
%   'NumWorkers': An interger. How many parallel workers to use. Default to
%   0, which tells Matlab not to run parallel computing. Should not be
%   larger than the maximum number defined by your 'local' cluster config,
%   which is usually the number of logical cores on your machine
%   'StartTime': A numeric array. Each element is the actual start time of
%   the audio file.
%   'EndTime': A numeric array. Each element is the actual end time of the
%   audio file.
%
% Outputs:
%   matList: A cell array. Each cell contains the full path to a .mat file,
%   which is the cache file for the corresponding .wav file. Each cache
%   file contains the fields of the utt struct returned by
%   'speechAnalysis', plus a 'post' field containing the posteriorgram,
%   which is a D*T matrix, D is 5816 in this case, and T is the number of
%   frames
%
%   After this function finishes, you will find the following folders/files
%   under 'outputDir',
%   - /recording: list of .wav files
%   - /lab: list of .lab files, each one is a text transcription
%   - /tg: list of .TextGrid files, each one is a forced alignment file
%   - /post: raw PPG files
%   - /mat: list of .mat files, each one contains a processed utt struct
%   - prompts.txt: a local copy of 'transFile'
%   - log_$TIMESTAMP: a log file for this run
%
% Other m-files required: exFeaturesAPI, arkread, fixPpgLengthMismatch,
% tryCreateDir
%
% Subfunctions: None
%
% MAT-file required: None
%
% Author: Guanlong Zhao
% Email: gzhao@tamu.edu
% Created: 10/10/2018; Last revision: 10/24/2018
% Revision log:
%   10/10/2018: function creation, Guanlong Zhao
%   10/15/2018: add documentation; add options to remove initial and
%   trailing silence from the input audios, GZ
%   10/19/2018: add an option to change the default output dir; change the
%   way of handling the start and end time, GZ
%   10/24/2018: removed weird assumptions on output dir, GZ

% Copyright 2018 Guanlong Zhao
% 
% Licensed under the Apache License, Version 2.0 (the "License");
% you may not use this file except in compliance with the License.
% You may obtain a copy of the License at
% 
%     http://www.apache.org/licenses/LICENSE-2.0
% 
% Unless required by applicable law or agreed to in writing, software
% distributed under the License is distributed on an "AS IS" BASIS,
% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing permissions and
% limitations under the License.

function matList = dataPrep(wavList, transFile, outputDir, varargin)
    % Setup
    isfile = @(x) logical(exist(x, 'file'));
    startTimestamp = datestr(clock, 30);
    filePrefix = 'gsb';
    targetFs = 16000; % Hz
    aligner = ''; % 'mfa_align' binary file
    dictionary = ''; % 'dictionary' text file
    acousticModel = ''; % 'english.zip' file
    currDir = pwd;
    parentDir = fileparts(currDir);
    ppgExtractor = fullfile(parentDir,...
        'dependency/kaldi-posteriorgram/run.sh');
    % Parse input
    p = inputParser;
    % A cell array of wav file paths
    addRequired(p, 'wavList', @iscellstr);
    % Path to the transcription file
    addRequired(p, 'transFile', @ischar);
    % Output root path, all files will be saved there
    addRequired(p, 'outputDir', @ischar);
    % Options
    % Number of parallel workers, set to 0 for serial mode
    defaultNumWorkers = 0;
    clusterPar = parcluster('local');
    maxWorkers = clusterPar.NumWorkers;
    addParameter(p, 'NumWorkers', defaultNumWorkers,...
        @(x) x>=0 && x<=maxWorkers);
    % Add options for clipping the audio length
    addParameter(p, 'StartTime', [], @(x) isnumeric(x) || isempty(x));
    addParameter(p, 'EndTime', [], @(x) isnumeric(x) || isempty(x));
    
    parse(p, wavList, transFile, outputDir, varargin{:});
    numWorkers = p.Results.NumWorkers;
    startTime = p.Results.StartTime;
    endTime = p.Results.EndTime;
    
    
    
    % Prepare paths and files for experiment
    % Root dir for this specific batch
    tryCreateDir(outputDir);
    
    % Log file
    diaryName = fullfile(outputDir, sprintf('log_%s', startTimestamp));
    diary(diaryName);
    diary on
    fprintf('Start processing batch [%s]...\n\n', startTimestamp);
    fprintf('Logging to file %s...\n\n', diaryName);
    fprintf('********** Preparing Environment Settings **********\n');
    
    % Audio files, .wav
    audioDir = fullfile(outputDir, 'recording');
    tryCreateDir(audioDir);
    fprintf('Set audio file directory to: %s\n', audioDir);
    
    % Transcription files, .lab
    textDir = fullfile(outputDir, 'lab');
    tryCreateDir(textDir);
    fprintf('Set transcription file directory to: %s\n', textDir);
    
    % Forced alignment files, .TextGrid files
    tgDir = fullfile(outputDir, 'tg');
    tryCreateDir(tgDir);
    fprintf('Set TextGrid file directory to: %s\n', tgDir);
    
    % Posteriorgram files, .scp and .ark
    postDir = fullfile(outputDir, 'post');
    tryCreateDir(postDir);
    fprintf('Set posteriorgram file directory to: %s\n', postDir);
    
    % Cached utterance files, .mat
    matDir = fullfile(outputDir, 'mat');
    tryCreateDir(matDir);
    fprintf('Set mat file directory to: %s\n', matDir);
    
    % Temp files
    tempFileDir = fullfile(outputDir, 'temp');
    tryCreateDir(tempFileDir);
    fprintf('Set temp file directory to: %s\n', tempFileDir);
    
    % Make a local copy of the transcription file
    transFileCopy = fullfile(outputDir, 'prompts.txt');
    if isfile(transFile)
        copyfile(transFile, transFileCopy);
    else
        error('Transcription file %s does not exist.', transFile);
    end
    fprintf('********** Finished Environment Settings **********\n\n')
    
    
    
    % Clip audio (if necessary) and convert audio to mono and resample
    numWav = 0;
    if ~isempty(startTime)
        assert(length(startTime) == length(wavList),...
            'Start time list is wrong.');
    end
    if ~isempty(endTime)
        assert(length(endTime) == length(wavList),...
            'End time list is wrong.');
    end
    for ii = 1:length(wavList)
        currWavFileName = wavList{ii};
        if isfile(currWavFileName)
            [wav, fs] = audioread(currWavFileName);
            wav = wav(:, 1); % Take the first channel
            
            % Clipping, if any
            startIdx = 1;
            endIdx = length(wav);
            if ~isempty(startTime)
                startIdx = max([1, floor(startTime(ii)*fs) + 1]);
            end
            if ~isempty(endTime)
                endIdx = min([length(wav), floor(endTime(ii)*fs)]);
            end
            assert(startIdx < endIdx,...
                'Clipping start point should always be smaller than the end point!');
            wav = wav(startIdx:endIdx);
            
            % Resample
            if fs ~= targetFs
                fprintf('Downsampling %s from %d to %d...\n',...
                    currWavFileName, fs, targetFs);
                wav = resample(wav, targetFs, fs); % Resample to target fs
            end
            wavCopy = fullfile(audioDir,...
                sprintf('%s_%04d.wav', filePrefix, ii));
            fprintf('Saving audio file to %s\n', wavCopy);
            audiowrite(wavCopy, wav, targetFs);
            numWav = numWav + 1;
        else
            warning('File % does not exist.', currWavFileName);
        end
    end
    
    
    
    % Create orthographic transcripts
    fprintf('********** Preparing Orthographic Transcriptions **********\n')
    validChar = @(x) regexp(x, '[0-9a-zA-Z ''-]');
    prptFid = fopen(transFileCopy);
    newLine = fgetl(prptFid);
    lineCt = 1;
    while ischar(newLine)
        newLineValidIdx = validChar(newLine);
        newLine = newLine(newLineValidIdx);
        newFileName = fullfile(textDir, sprintf('%s_%04d.lab',...
            filePrefix, lineCt));
        newFile = fopen(newFileName, 'w');
        fprintf('Generating file: %s\nFile content: ''%s''\n\n',...
            newFileName, newLine)
        fprintf(newFile, '%s', newLine);
        fclose(newFile);
        newLine = fgetl(prptFid);
        lineCt = lineCt+1;
    end
    fclose(prptFid);
    fprintf('********** Finished Generating Orthographic Transcriptions **********\n\n')
    assert(numWav == (lineCt - 1), 'Fewer audio files than transcripts.');

    
    
    % Create textgrids
    fprintf('********** Preparing TextGrid Files **********\n')
    fprintf('Using aligner located at: %s\n', aligner);
    tempAudioText = fullfile(tempFileDir, 'audio_and_text');
    tempText = fullfile(tempFileDir, 'tempText');
    tempAliner = fullfile(tempFileDir, 'temp_aligner');
    tryCreateDir(tempAudioText);
    tryCreateDir(tempText);
    tryCreateDir(tempAliner);
    fprintf('Copying all audio files to %s\n', tempAudioText)
    copyfile(fullfile(audioDir, '*.wav'), tempAudioText);
    fprintf('Done!\n')
    fprintf('Copying all lab files to %s\n', tempAudioText)
    copyfile(fullfile(textDir, '*.lab'), tempAudioText);
    fprintf('Done!\n')
    alignCmd = sprintf('%s -t %s -j 8 -v -c %s %s %s %s', aligner,...
        tempAliner, tempAudioText, dictionary, acousticModel, tempText);
    fprintf('Passing command ''%s'' to system shell\n', alignCmd)
    fprintf('Running aligner:\n')
    system(alignCmd, '-echo');
    fprintf('Finished forced alignment\n')
    fprintf('Copying all TextGrid files to %s\n', tgDir)
    copyfile(fullfile(tempText, 'audio_and_text', '*.TextGrid'), tgDir);
    copyfile(fullfile(tempText, 'oovs_found.txt'), tgDir);
    fprintf('Cleaning temp folders...\n')
    rmdir(tempFileDir, 's');
    fprintf('Done!\n');
    fprintf('********** Finished Generating TextGrid Files **********\n\n')
    
    

    % Feature extraction
    fprintf('********** Extracting Feature **********\n')
    files = dir(fullfile(audioDir, '*.wav'));
    numFiles = length(files);
    outputBuffer = cell(numFiles, 1); % May get too big?
    parfor (ii = 1:numFiles, numWorkers)
        genericPrefix = strrep(files(ii).name, '.wav', '');
        audioFilePath = fullfile(audioDir, files(ii).name);
        fprintf('Processing audio file: %s\n', audioFilePath)
        assert(isfile(audioFilePath), 'Error: audio file does not exist!');
        textFilePath = fullfile(textDir, sprintf('%s.lab', genericPrefix));
        if ~isfile(textFilePath)
            fprintf('Transcription ''%s'' does not exist, skip this file\n', textFilePath)
            continue;
        end
        tgFilePath = fullfile(tgDir, sprintf('%s.TextGrid', genericPrefix));
        if ~isfile(tgFilePath)
            fprintf('TextGrid ''%s'' does not exist, skip this file\n', tgFilePath)
            continue;
        end
        matFilePath = fullfile(matDir, sprintf('%s.mat', genericPrefix));
        if isfile(matFilePath)
            fprintf('Mat file ''%s'' already exists, skip this file\n', matFilePath)
            continue;
        end
        outputBuffer{ii} = exFeaturesAPI(audioFilePath, textFilePath, tgFilePath);
    end
    fprintf('********** Finished Extracting Features **********\n\n')
    
    
    
    % Create posteriorgrams
    fprintf('********** Preparing Posteriorgram Files **********\n')
    ppgCmd = sprintf('%s %s %s', ppgExtractor, audioDir, postDir);
    fprintf('Extracting PPGs:\n');
    system(ppgCmd, '-echo');
    fprintf('Finished PPG extraction.\n');
    postFiles = dir(fullfile(postDir, 'split1utt', '1', 'post',...
        'raw_bnfeat_1.*.ark'));
    % Append the PPGs to utt struct
    numArks = length(postFiles);
    ark = cell(numArks, 1);
    scp = cell(numArks, 1);
    fprintf('Loading ark files...\n');
    for ii = 1:numArks
        [scp{ii}, ark{ii}] = arkread(sprintf(...
            '%s/split1utt/1/post/raw_bnfeat_1.%d.ark', postDir, ii));
    end
    fprintf('done\n');
    numUtts = length(outputBuffer);
    iUtt = 0;
    for ii = 1:numArks
        for jj = 1:size(scp{ii}, 1)
            iUtt = iUtt + 1;
            uttId = textscan(scp{ii}{jj, 1}, 'recording_gsb_%04d');
            uttId = uttId{1};
            assert(int32(iUtt) == uttId,...
                'Utterance ID mismatch: expected %d, got %d', int32(iUtt), uttId);
            temppost = transpose(ark{ii}(scp{ii}{jj, 6}:(scp{ii}{jj, 7}), :));
            outputBuffer{iUtt} = fixPpgLengthMismatch(outputBuffer{iUtt}, temppost);
        end
        if iUtt > numUtts
            break;
        end
    end
    fprintf('********** Finished Generating Posteriorgram Files **********\n\n')

    
    
    % Save mats
    fprintf('********** Saving Cache Files **********\n')
    matList = {};
    numMats = 0;
    for ii = 1:numFiles
        genericPrefix = strrep(files(ii).name, '.wav', '');
        matFilePath = [matDir, '/', genericPrefix, '.mat'];
        fprintf('Saving mat file: %s\n', matFilePath)
        if isfile(matFilePath)
            fprintf('Mat file ''%s'' already exists, skip this file\n', matFilePath)
            continue;
        end
        utt = outputBuffer{ii};
        if ~isempty(utt)
            numMats = numMats + 1;
            allFields = fieldnames(utt);
            save(matFilePath, '-struct', 'utt', allFields{:});
            matList{numMats} = matFilePath;
        else
            fprintf('Mat file ''%s'' will be empty, skip this file\n', matFilePath)
        end  
    end
    fprintf('********** Finished Generating Mat Files **********\n\n')
    fprintf('********** Everything Finished **********\n')
    diary off
end
