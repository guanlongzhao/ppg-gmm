%%  Test script for WORLD analysis/synthesis with new waveform generator
% 2018/04/04: First version

[x, fs] = audioread('vaiueo2d.wav');

f0_parameter = Harvest(x, fs);
spectrum_parameter = CheapTrick(x, fs, f0_parameter);
source_parameter = D4CRequiem(x, fs, f0_parameter);

seeds_signals = GetSeedsSignals(fs);
y = SynthesisRequiem(source_parameter, spectrum_parameter, seeds_signals);
