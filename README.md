# PPG-GMM
This repository hosts an open source implementation for the accent conversion system described in our submission to _IEEE/ACM Transactions on Audio, Speech, and Language Processing (TASLP)_, titled "Using Phonetic Posteriorgram Based Frame Pairing for Segmental Accent Conversion."

## System requirement
- OS: `Ubuntu 16.04` (tested and recommended) or `CentOS 7.5` (tested but you may run into some issues)
- Matlab: `R2019a` (tested and recommended) or `R2016a` (tested); any versions between these two should work but not tested
- Essentially, as long as you can install _Kaldi_, the _Montreal Forced Aligner_, and _Matlab_ on your OS, this package should work just fine
- Fast CPU and large RAM (>=16GB) are preferred

## Install

### Download the source code
```
git clone https://github.com/guanlongzhao/ppg-gmm.git
cd test/data
mkdir temp
```

### Install dependencies
- Install [kaldi-5.3](https://github.com/kaldi-asr/kaldi/tree/5.3)
- Install [Montreal Forced Aligner (v1.0)](https://github.com/MontrealCorpusTools/Montreal-Forced-Aligner/tree/v1.0)
    - Make sure the aligner binary file is executable on your machine
- Install `mcep-sptk-matlab`
    - Run `script/installMcepSptkMatlab.m` in Matlab
    - Note that you need a working C/C++ compiler installed, and Matlab has to be configured to use that compiler
    - See the [documentation](https://www.mathworks.com/help/matlab/ref/mex.html) for the `mex` function in Matlab for more details
- Configure `kaldi-posteriorgram`
    - Set `KALDI_ROOT` in `dependency/kaldi-posteriorgram/path.sh` to the root directory of your Kaldi installation (e.g., `/home/kaldi`)
    - Give execute permission to all `.sh` files. For example, `chmod u+x *.sh`
- Configure `function/dataPrep.m`
    - Set `aligner` to the absolute path of the Montreal Forced Aligner binary (the `mfa_align` file, e.g., `/home/mfa/mfa_align`)
    - Set `dictionary` to the absolute path of the Montreal Forced Aligner dictionary file. If you do not have one, you can download it [here](https://psi.engr.tamu.edu/wp-content/uploads/2019/04/dictionary.txt)
    - Set `acousticModel` to the absolute path of the Montreal Forced Aligner pre-trained model (the `english.zip` file, e.g., `/home/mfa/english.zip`)

## Add to search path
Add all dependencies (packages under `dependency`) and `function` to the Matlab search path
- Use the Matlab GUI tool `Set Path`, or
- Run `script/addDependencies.m` in Matlab, note that this will only add the dependencies to the search path of the current Matlab session

## Run tests
- **Prepare test data [important]**: in Matlab, run the script `script/prepareFixturesForTests.m`
- Run all tests: go to the `test` folder in Matlab, and type `runtests`
- It takes about ~30 min to finish all tests, depending on your machine specifications
- To run a particular test (e.g., `TEST_NAME`), type `runtests('TEST_NAME')`
- `ppgGmmEndToEndTest`: The end-to-end system test, can also be used as a reference on how the system works; this one takes about 10 min to finish

## Run demo script
- In Matlab, run `script/demo.m`
    - This script generates a voice that sounds like the speaker in `test/data/tgt` but with the accent of the speaker in `test/data/src`
    - You will find the accent conversion syntheses under `test/data/temp/demo/ac_syntheses`
    - The resulting syntheses will have low acoustic quality because the demo only uses 30 utterances for training
    - Some higher-quality samples we used in the paper can be found at https://guanlongzhao.github.io/demo/ppg-gmm
- How to apply your own data? Read and modify `script/demo.m`

## Notes
- In the paper, we used the [TANDEM-STRAIGHT](http://www.wakayama-u.ac.jp/~kawahara/STRAIGHTadv/index_e.html) vocoder (`TandemSTRAIGHTmonolithicPackage012`) and it is not open-source. Therefore, we cannot include that package here
    - Instead, we used [WORLD](https://github.com/mmorise/World) in this implementation
    - We kept the TANDEM-STRAIGHT related code in this repo in case you have access to TANDEM-STRAIGHT. Note that we used `MulticueF0v14` from [Legacy-STRAIGHT](https://github.com/HidekiKawahara/legacy_STRAIGHT) as the pitch tracker to improve the performance of TANDEM-STRAIGHT, as noted in the paper
- This implementation is not the original experimental code used for the experiments in the paper, but it is a close re-implementation of the original system

## Running into issues?
- In the output folder of your experiment, you will find log files named in the form of `log_[TIMESTAMP]`. Try to read the logs and see if there is anything suspicious
- The most common issues are,
    - **Why the aligner freezes?** If the aligner could not find all the words in your dictionary, it will pause and ask you whether to abort and fix this or continue. Generally, I will just ignore this and continue. The whole point of the alignment is to find the silent segments more accurately, and there are many other ways to do this
    - **Why the PPG extraction fails?**
        - The most probable reason is that the shell scripts under `dependency/kaldi-posteriorgram` do not have the execute permission
        - Sometimes Matlab loads a different `libstdc++` than the one that Kaldi was compiled with, and this will make all the system calls to Kaldi binaries made by Matlab to fail. The solution is to load the `libstdc++` that Kaldi uses when starting your Matlab session; see `script/addDependencies.m` for more details
    - **Why Matlab tells me that some functions are missing?**
        - You probably did not add all the dependencies to the Matlab search path
        - If it is a built-in Matlab function, you probably need to use a different Matlab version or install the corresponding toolboxes (e.g., Statistics and Machine Learning Toolbox for `pdist2`, Communications Toolbox for `vec2mat`, and Parallel Computing Toolbox for `parfor`). Some of these functions have open-source solutions. For example, I found a `pdist2` function [here](https://www.mathworks.com/matlabcentral/mlc-downloads/downloads/submissions/29004/versions/2/previews/FPS_in_image/FPS%20in%20image/Help%20Functions/SearchingMatches/pdist2.m/index.html)
- Feel free to open an issue or initiate a pull request for any bugs you found

## Citation
Please cite the following paper if you used this system in your publication,

```
@article{zhao2019using,
  title={Using Phonetic Posteriorgram Based Frame Pairing for Segmental Accent Conversion},
  author={Zhao, Guanlong and Gutierrez-Osuna, Ricardo},
  journal={Submitted to IEEE/ACM Transactions on Audio, Speech, and Language Processing},
  year={2019}
}
```

## License
- For everything under `dependency`, please refer to their respective license terms
- For codes under `function`, `script`, and `test`, they are released under the [Apache License 2.0](http://www.apache.org/licenses/LICENSE-2.0) license.

## Contact
Guanlong Zhao (gzhao@tamu.edu), Department of Computer Science and Engineering, Texas A&M University