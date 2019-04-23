# SPTK MCEP Encoder and Decoder for Matlab
I want to use SPTK's `mcep` and `mgc2sp` in Matlab on Windows, but I could not get SPTK compiled on Windows. To make my life easier, I ported those two functions to Matlab, so that's the story. I could use Linux and call the SPTK binaries from `bash`, but I just do not want to do that.

## Port `mcep`
Originally I was going to implement a pure Matlab version, but after finishing half of the work I realized that the Matlab version is very slow, especially those two subroutines `freqt` and `frqtr`. So I added Matlab `mex` support to `freqt`, `frqtr`, and `theq`, and used the compiled C code directly. Eventually, the only difference between the Matlab and the C version is that the Matlab version uses its own `fft` and `ifft` functions.

In Matlab, you can call `spec2mcep` to convert STRAIGHT spectrogram to mcep, an example use case is,
```matlab
% sp is a spectrogram, mc is the output MCEP
% This command extracts a 24 order (exclude the energy) MCEP
% The all-pass constant is 0.35 here
mc = spec2mcep(sp, 0.35, 24, 2, 30, 0.001, 1e-6);
```
Refer to the function documentation for more details.

## Port `mgc2sp`
`mgc2sp` is actually for converting Mel-Generalized Cepstrums (MGC) to spectrums. By setting the parameter `gamma` to 0, we can use this function to convert MCEP, because MCEP is just a special case of MGC. Long story short, the converted Matlab function is 99% in `C` and 1% in `Matlab`, so it should be almost the same as SPTK's implementation.

In Matlab, you can call `mcep2spec` to convert mcep to STRAIGHT spectrogram, an example use case is,
```matlab
% sp is a spectrogram, mc is the input MCEP
% The recovered spectrogram has 513 frequency bins, corresponding to a 1024 FFTL
% The all-pass constant is 0.35 here
sp = mcep2spec(mc, 0.35, 513);
```
Refer to the function documentation for more details.

## Install
If you are familiar with Matlab `mex`, you know what to do. If you are not, please read [Matlab's documentation](https://www.mathworks.com/help/matlab/matlab_external/introducing-mex-files.html).

Compile all the `C` source files in this repo. I tested two compilers, `MinGW64` and `VC++ 2015`, the mex files generated using `VC++ 2015` is slightly faster.

## Notes
- All mex functions do not have input validation, so use at your own risk, may break your Matlab XD
- I only tested those functions in Matlab R2016a (Windows version), should work on other OS though
- I also included precompiled mex files here, those are compiled using `VC++ 2015` in Matlab R2016a, you may or may not be able to use them directly
- An initial test shows that this implementation gives almost the same output as SPTK's

Guanlong Zhao (gzhao@tamu.edu)

###### Mon Apr 22 14:07:57 CDT 2019