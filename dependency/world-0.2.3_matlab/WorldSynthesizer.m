function WorldSynthesizer(input_filename, output_filename, f0_param, spec_param, time_param)
% F0をシフト，スペクトルの伸縮，発話時間の伸縮を実施する関数
% 書式：WorldSynthesizer(input_filename, output_filename, f0_param, spec_param, time_param)
% 例題：WorldSynthesizer('vaiueo2d.wav', 'output.wav', 1, 1, 1);
[x, fs] = audioread(input_filename);

f0_parameter = Harvest(x, fs);

spectrum_parameter = CheapTrick(x, fs, f0_parameter);
source_parameter = D4C(x, fs, f0_parameter);

% F0の変更
source_parameter.f0 = source_parameter.f0 * f0_param;

% スペクトルの伸縮
fft_size = (size(spectrum_parameter.spectrogram, 1) - 1) * 2;
w = (0 : fft_size - 1) * fs / fft_size;
w2 = (0 : fft_size / 2) * fs / fft_size / spec_param;
for i = 1 : size(spectrum_parameter.spectrogram, 2)
  tmp = [spectrum_parameter.spectrogram(:, i); spectrum_parameter.spectrogram(end - 1 : -1 : 2, 1)];
  spectrum_parameter.spectrogram(:, i) = interp1(w, tmp, w2, 'linear', 'extrap');
end;

% 発話時間の伸縮
source_parameter.temporal_positions = source_parameter.temporal_positions * time_param;

y = Synthesis(source_parameter, spectrum_parameter);

audiowrite(output_filename, y, fs);