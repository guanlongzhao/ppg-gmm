% speechAnalysis: a refined speech analyser, it provides a well-defined
% output struct that captures everything that's needed for doing my speech
% processing research. In the future, this function will be expanded to a
% class
%
% Syntax:
% Using default settings
%   utt = speechAnalysis(wav, fs)
% Pass name-value pairs
%   utt = speechAnalysis(wav, fs, 'name1', value1, 'name2', value2, ...)
%
% Inputs:
%   wav: wave form
%   fs: sample frequency
%   [optional name-value pairs]:
%   'Shift': analysis window frame shift, default to 5 (ms)
%   'FFTsize': FFT size, default to 1024, resulting 513-dim spectrum
%   'Text': orthographic transcription, text string, default to []
%   'TextGrid': TextGrid object created by mPraat, default to []
%   'NumMel': order of MFCCs, default to 25
%   'PitchMode': 'default' | 'NDF' (*), 'NDF' only supports using 5ms as
%   updating interval, I think it is better than 'default'
%   'F0Floor': F0 search range lower bound, default to 50Hz
%   'F0Ceil': F0 search range upper bound, default to 400Hz
%   'Vocoder': 'WORLD' (*) | 'TandemSTRAIGHTmonolithicPackage012'
%
% Outputs:
%   utt: a struct that contains useful information about an utterance
%       - wav: the input waveform
%       - fs: the input sample frequency
%       - text: the orthographic transcription
%       - tg: the TextGrid object
%       - spec: STRAIGHT spectrogram, D_dft*T matrix
%       - mfcc: mfccs, D_mel*T matrix
%       - mcep: mel-cepstrums, D_mel*T matrix
%       - phones: phoneme labels and start and end time of phone segments;
%       the labels are canonical pronunciations
%       - words: word labels and start and end time of word segments
%       - lab: per frame phoneme label, array of phoneme index
%       - source: source structure, including F0 and AP
%       - alpha: the alpha value used for mcep extraction
%       - vocoder: vocoder version information
%       - (Optional) filter: filter structure, for WORLD only
%       - (Optional) params: extraction parameters, for Tandem-STRAIGHT
%       only
%
% Other m-files required: tg2lab.m, TandemSTRAIGHT library, straight2mfcc.m
% phones2numeric.m, WORLD library, spec2mcep
%
% Subfunctions: None
%
% MAT-file required: None
%
% Author: Guanlong Zhao
% Email: gzhao@tamu.edu
% Created: 04/19/2017; Last revision: 10/10/2018
% Revision log:
%   04/19/2017: function creation, Guanlong Zhao
%   04/20/2017: function refinement, Guanlong Zhao
%   04/21/2017: fixed a bug that is related to the default value of 'Text',
%   it should be '' instead of []. Guanlong Zhao
%   04/23/2017: fixed a bug that may break the function when the pitch
%   extraction (vuv part) fails, GZ
%   05/10/2017: added option to choose which pitch extractor to use, GZ
%   05/18/2017: added field 'lab' to utt, GZ
%   06/01/2017: fixed a bug related to text-independent analysis, GZ
%   06/21/2017: added field 'mcep' to utt, GZ
%   09/14/2018: clarified the assumption on phoneme labels, GZ
%   10/02/2018: added options to control the F0 search range, GZ
%   10/09/2018: default 'F0Ceil' to 400Hz, GZ
%   10/10/2018: added support to 'WORLD' vocoder, GZ

% Copyright 2017 Guanlong Zhao
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

function utt = speechAnalysis(wav, fs, varargin)
    % Parse inputs
    p = inputParser;
    defaultShift = 5; % in ms
    defaultFFTsize = 1024;
    defaultText = ''; % orthographical transcription
    defaultTg = []; % forced alignment
    defaultNmel = 25; % order of MFCCs
    defaultVocoder = 'WORLD';
    
    addRequired(p, 'wav', @isnumeric);
    addRequired(p, 'fs', @isnumeric);
    addParameter(p, 'Shift', defaultShift, @isnumeric);
    addParameter(p, 'FFTsize', defaultFFTsize, @isnumeric);
    addParameter(p, 'Text', defaultText, @ischar);
    addParameter(p, 'TextGrid', defaultTg);
    addParameter(p, 'NumMel', defaultNmel, @isnumeric);
    addParameter(p, 'PitchMode', 'NDF', @ischar);
    addParameter(p, 'F0Floor', 50, @isnumeric);
    addParameter(p, 'F0Ceil', 400, @isnumeric);
    addParameter(p, 'Vocoder', defaultVocoder,...
        @(x) ismember(x, {'TandemSTRAIGHTmonolithicPackage012', 'WORLD'}));
    parse(p, wav, fs, varargin{:});
    vocoder = p.Results.Vocoder;
    
    % Parameters for mcep extraction
    alphaForMcep = 0.42;
    switch fs
        case 48000
            alphaForMcep = 0.554;
        case 44100
            alphaForMcep = 0.544;
        case 16000
            alphaForMcep = 0.42;
        case 10000
            alphaForMcep = 0.35;
        case 8000
            alphaForMcep = 0.31;
        otherwise
            warning('Does not have suitable MCEP alpha value for Fs [%d], default to %1.2f.', fs, alphaForMcep);
    end
    getMCEP = @(x) spec2mcep(x, alphaForMcep, p.Results.NumMel-1); % just for isolation
    
    % Feature extraction
    utt = struct;
    switch vocoder
        case 'TandemSTRAIGHTmonolithicPackage012'
            % Pitch extraction
            f0Options.f0floor = p.Results.F0Floor;
            f0Options.f0ceil = p.Results.F0Ceil;
            switch p.Results.PitchMode
                % default
                case 'default'
                    f0Options.framePeriod = p.Results.Shift;
                    f0raw = exF0candidatesTSTRAIGHTGB(wav, fs, f0Options); % Extract F0 information
                    f0 = autoF0Tracking(f0raw, wav); % Clean F0 trajectory by tracking
                    if isfield(f0, 'vuv')
                        f0.vuv = refineVoicingDecision(wav, f0);
                    else
                        f0.vuv = zeros(size(f0.f0));
                    end
                % MulticueF0v14, I believe this is better    
                case 'NDF'
                    % f0Options.F0frameUpdateInterval = 1;
                    % if f0Options.F0frameUpdateInterval == 1
                    %     warning('Extracted pitch will be downsampled using a 5ms interval!');
                    % end
                    f0raw = NDFF0interface(wav, fs, f0Options); % Extract F0 information, only support 5ms shift
                    f0 = f0raw;
                otherwise
                    error('Pitch mode not supported yet!');
            end

            % Aperiodicity extraction
            ap = aperiodicityRatioSigmoid(wav, f0, 1, 2, 0);

            % Spectrum analysis
            specOptions.FFTsize = p.Results.FFTsize;
            specOptions.outputTANDEMspectrum = 0;
            spec = exSpectrumTSTRAIGHTGB(wav, fs, ap, specOptions);
            STRAIGHTobject.waveform = wav;
            STRAIGHTobject.samplingFrequency = fs;
            STRAIGHTobject.refinedF0Structure.temporalPositions = f0raw.temporalPositions;
            STRAIGHTobject.SpectrumStructure.spectrogramSTRAIGHT = spec.spectrogramSTRAIGHT;
            STRAIGHTobject.refinedF0Structure.vuv = f0.vuv;
            spec.spectrogramSTRAIGHT = unvoicedProcessing(STRAIGHTobject);

            % Cepstrum analysis
            ceps = straight2mfcc(spec.spectrogramSTRAIGHT, fs, p.Results.NumMel);
            mcep = getMCEP(spec.spectrogramSTRAIGHT); % get MCEP
            
            % Assemble Tandem-STRAIGHT specific info
            utt.spec = spec.spectrogramSTRAIGHT;
            utt.params = struct;
            utt.params.specParameters = spec.analysisConditions;
            utt.params.specParameters.dateOfSpectrumEstimation = spec.dateOfSpectrumEstimation;
            % APIs for different pitch modes are slightly different
            switch p.Results.PitchMode
                case 'default'
                    utt.params.sourceParameters = f0.controlParameters;
                    utt.params.sourceParameters.dateOfSourceExtraction = f0.dateOfSourceExtraction;
                case 'NDF'
                    utt.params.sourceParameters = f0.additionalInformation.controlParameters;
                    utt.params.sourceParameters.dateOfSourceExtraction = f0.additionalInformation.dateOfSourceExtraction;
                otherwise
                    error('Pitch mode not supported yet!');
            end
            utt.params.sourceParameters.procedure = ap.procedure;
            utt.source = struct;
            utt.source.f0 = ap.f0;
            utt.source.temporalPositions = ap.temporalPositions;
            utt.source.vuv = ap.vuv;
            utt.source.cutOffListFix = ap.cutOffListFix;
            utt.source.targetF0 = ap.targetF0;
            utt.source.sigmoidParameter = ap.sigmoidParameter;
            utt.source.exponent = ap.exponent;
        case 'WORLD'
            % Pitch extraction
            f0Options.f0_floor = p.Results.F0Floor;
            f0Options.f0_ceil = p.Results.F0Ceil;
            f0Options.frame_period = p.Results.Shift;
            f0raw = Harvest(wav, fs, f0Options);
            % If you modified the fft_size, you must also modify the
            % option in D4C. The lowest F0 that WORLD can work as expected
            % is determined by the following: 3.0 * fs / fft_size
            % The 1.1 factor is a WORLD safeguard on the f0_floor
            lowestF0 = 3.0 * fs / p.Results.FFTsize;
            isF0FloorTooLow = p.Results.F0Floor * 1.1 < lowestF0;
            if isF0FloorTooLow
                warning('F0 floor %f is too low, expected to be higher than %f, the program may fail.',...
                    p.Results.F0Floor, lowestF0);
            end
            cheaptrickOption.fft_size = p.Results.FFTsize;
            d4cOption.fft_size = cheaptrickOption.fft_size;
            spectrumObject = CheapTrick(wav, fs, f0raw, cheaptrickOption);
            sourceObject = D4C(wav, fs, f0raw, d4cOption);
            ceps = straight2mfcc(spectrumObject.spectrogram, fs, p.Results.NumMel);
            mcep = getMCEP(spectrumObject.spectrogram); % get MCEP
            utt.spec = spectrumObject.spectrogram;
            utt.filter = spectrumObject;
            utt.source = sourceObject;
        otherwise
            error('Vocoder %s is not supported.', vocoder);
    end
    
    % Getting shared fields
    
    % Get phone label struct from tg
    phones = tg2lab(p.Results.TextGrid, 'Shift', p.Results.Shift, 'Tmax',...
        size(ceps, 2), 'Mode', 'phones');
    % Get per frame phonme label
    utt.phones = phones;
    if ~isempty(phones)
        lab = phones2numeric(utt);
    else
        lab = [];
    end

    % Get word label struct from tg
    words = tg2lab(p.Results.TextGrid, 'Shift', p.Results.Shift, 'Tmax',...
        size(ceps, 2), 'Mode', 'words');

    % Assemable output
    utt.wav = wav;
    utt.fs = fs;
    utt.text = p.Results.Text;
    utt.tg = p.Results.TextGrid;
    utt.mfcc = ceps;
    utt.mcep = mcep;
    utt.phones = phones;
    utt.words = words;
    utt.lab = lab; % per frame phoneme label
    utt.alpha = alphaForMcep;
    utt.vocoder = vocoder; 
end
