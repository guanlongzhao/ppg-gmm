function WorldSynthesizer(input_filename, output_filename, f0_param, spec_param, time_param)
% F0���V�t�g�C�X�y�N�g���̐L�k�C���b���Ԃ̐L�k�����{����֐�
% �����FWorldSynthesizer(input_filename, output_filename, f0_param, spec_param, time_param)
% ���FWorldSynthesizer('vaiueo2d.wav', 'output.wav', 1, 1, 1);
[x, fs] = audioread(input_filename);

f0_parameter = Harvest(x, fs);

spectrum_parameter = CheapTrick(x, fs, f0_parameter);
source_parameter = D4C(x, fs, f0_parameter);

% F0�̕ύX
source_parameter.f0 = source_parameter.f0 * f0_param;

% �X�y�N�g���̐L�k
fft_size = (size(spectrum_parameter.spectrogram, 1) - 1) * 2;
w = (0 : fft_size - 1) * fs / fft_size;
w2 = (0 : fft_size / 2) * fs / fft_size / spec_param;
for i = 1 : size(spectrum_parameter.spectrogram, 2)
  tmp = [spectrum_parameter.spectrogram(:, i); spectrum_parameter.spectrogram(end - 1 : -1 : 2, 1)];
  spectrum_parameter.spectrogram(:, i) = interp1(w, tmp, w2, 'linear', 'extrap');
end;

% ���b���Ԃ̐L�k
source_parameter.temporal_positions = source_parameter.temporal_positions * time_param;

y = Synthesis(source_parameter, spectrum_parameter);

audiowrite(output_filename, y, fs);