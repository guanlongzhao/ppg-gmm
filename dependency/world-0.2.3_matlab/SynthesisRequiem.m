function y = SynthesisRequiem(source_object, filter_object, seeds_signals)
% Waveform generation from the estimated parameters
% y = SynthesisRequiem(source_object, filter_object, seeds_signals)
%
% Input
%   source_object : F0 and aperiodicity
%   filter_object : spectral envelope
%   seeds_signals : parameters for excitation signal generation
%
% Output
%   y : synthesized waveform
%
% 2018/04/04: First version

% Generation of the excitation signal
excitation_signal = GetExcitationSignal(source_object.temporal_positions,...
  filter_object.fs, source_object.f0, source_object.vuv,...
  seeds_signals.pulse, seeds_signals.noise, source_object.band_aperiodicity);

% Waveform generation based on the overlap-add method
y = GetWaveform(excitation_signal, filter_object.spectrogram,...
  source_object.temporal_positions, source_object.f0, filter_object.fs);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function excitation_signal = GetExcitationSignal(temporal_positions, fs, f0,...
  vuv, pulse_seed, noise_seed, band_aperiodicity)
fft_size = size(pulse_seed, 1);
base_index = -fft_size / 2 + 1 : fft_size / 2;
number_of_aperiodicities = size(pulse_seed, 2);

time_axis = temporal_positions(1) : 1 / fs : temporal_positions(end);
periodic_component = zeros(length(time_axis), 1);
aperiodic_component = zeros(length(time_axis), 1);

[pulse_locations_index, interpolated_vuv] = ...
  TimeBaseGeneration(temporal_positions, f0, fs, vuv, time_axis);

% Band-aperiodicity is resampled at sampling frequency of fs Hz
interpolated_aperiodicity = AperiodicityGenration(temporal_positions,...
  band_aperiodicity, time_axis);

% Generation of the aperiodic component
for i = 1 : number_of_aperiodicities
  noise = GenerateNoise(length(aperiodic_component), noise_seed, i);
  aperiodic_component = aperiodic_component +...
    (noise .* interpolated_aperiodicity(i, 1 : length(aperiodic_component))');
end;

% Generation of the periodic component
for i = 1 : length(pulse_locations_index)
  if interpolated_vuv(pulse_locations_index(i)) <= 0.5 ||...
      interpolated_aperiodicity(1, pulse_locations_index(i)) > 0.999
    continue;
  end;
  noise_size = sqrt(max(1, -pulse_locations_index(i) +...
    pulse_locations_index(min(length(pulse_locations_index), i + 1))));
  output_buffer_index =...
    max(1, min(length(time_axis), pulse_locations_index(i) + base_index));
  response = GetOnePeriodicExcitation(number_of_aperiodicities, pulse_seed,...
    interpolated_aperiodicity(:, pulse_locations_index(i)), noise_size);
  periodic_component(output_buffer_index) =...
    periodic_component(output_buffer_index) + response;
end;
excitation_signal = periodic_component + aperiodic_component;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function response = GetOnePeriodicExcitation(number_of_aperiodicities,...
  pulse_seed, aperiodicity, noise_size)
response = zeros(length(pulse_seed(:, 1)), 1);
for i = 1 : number_of_aperiodicities
  response = response + pulse_seed(:, i) * (1 - aperiodicity(i));
end;
response = response * noise_size;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function y = GetWaveform(excitation_signal, spectrogram, temporal_positions,...
  f0, fs)
y = zeros(length(excitation_signal), 1);
fft_size = (size(spectrogram, 1) - 1) * 2;
latter_index = fft_size / 2 + 1 : fft_size;

frame_period_sample =...
  round((temporal_positions(2) - temporal_positions(1)) * fs);
win_len = frame_period_sample * 2 - 1;
half_win_len = frame_period_sample - 1;
win = hanning(win_len);

for i = 2 : length(f0) - 2
  origin = (i - 1) * frame_period_sample - half_win_len;
  safe_index = min(length(y), origin : origin + win_len - 1);
    
  tmp = excitation_signal(safe_index) .* win;
  spec = spectrogram(:, i);
  periodic_spectrum = [spec; spec(end - 1 : -1 : 2)];
  
  tmp_cepstrum = real(fft(log(abs(periodic_spectrum)) / 2));
  tmp_complex_cepstrum = zeros(fft_size, 1);
  tmp_complex_cepstrum(latter_index) = tmp_cepstrum(latter_index) * 2;
  tmp_complex_cepstrum(1) = tmp_cepstrum(1);
  
  spectrum = exp(ifft(tmp_complex_cepstrum));
  response = real(ifft(spectrum .* fft(tmp, fft_size)));

  safe_index = min(length(y), origin : origin + fft_size - 1);
  y(safe_index) = y(safe_index) + response;
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [pulse_locations_index, vuv_interpolated] =...
  TimeBaseGeneration(temporal_positions, f0, fs, vuv, time_axis)
f0_interpolated_raw = ...
  interp1(temporal_positions, f0, time_axis, 'linear', 'extrap');
vuv_interpolated = ...
  interp1(temporal_positions, vuv, time_axis, 'linear', 'extrap');
vuv_interpolated = vuv_interpolated > 0.5;

default_f0 = 500;
f0_interpolated = f0_interpolated_raw .* vuv_interpolated;
f0_interpolated(f0_interpolated == 0) = ...
  f0_interpolated(f0_interpolated == 0) + default_f0;

total_phase = cumsum(2 * pi * f0_interpolated / fs);
wrap_phase = rem(total_phase, 2 * pi);
pulse_locations = time_axis(abs(diff(wrap_phase)) > pi);
pulse_locations_index = round(pulse_locations * fs) + 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function multi_aperiodicity = ...
  AperiodicityGenration(temporal_positions, band_aperiodicity, time_axis)
number_of_aperiodicities = size(band_aperiodicity, 1);
multi_aperiodicity = zeros(number_of_aperiodicities, length(time_axis));

for i = 1 : number_of_aperiodicities
  multi_aperiodicity(i, :) = interp1(temporal_positions,...
    10 .^ (band_aperiodicity(i, :) / 10), time_axis, 'linear');
end;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function n = GenerateNoise(N, noise_seed, frequency_band)
persistent current_index;

if isempty(current_index)
  current_index = zeros(1, size(noise_seed, 2));
end
noise_length = size(noise_seed, 1);

index =...
  rem(current_index(frequency_band) : current_index(frequency_band) + N - 1,...
  noise_length);
n = noise_seed(index + 1, frequency_band);
current_index(frequency_band) = index(end);
