#!/bin/bash

# Copyright 2017 Guanlong Zhao
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This is to generate posteriors as features
# Prepare data
# Assuming that data is organized under $input_dir
# An example:
# $input_dir
# ├── recordings
# │   ├── 0001.wav
# │   ├── 0002.wav
# │   ├── 0003.wav

SCRIPTPATH=$(dirname "$0")
cd $SCRIPTPATH

. ./cmd.sh
. ./path.sh
[ -h steps ] || ln -s $KALDI_ROOT/egs/wsj/s5/steps
[ -h utils ] || ln -s $KALDI_ROOT/egs/wsj/s5/utils

n_split=1   # how many splits you want
input_dir=$1
output_dir=$2

./data_prep.sh --n_split $n_split ${input_dir} ${output_dir}

# Get posteriors
for part in $(seq $n_split); do 
    ./make_posteriors.sh --nj 8 ${output_dir}/split$n_split\utt/$part ${output_dir}/split$n_split\utt/$part/post ./exp/nnet7a_960_gpu ${output_dir}/split$n_split\utt/$part/post ${output_dir}/dump_post_log/$part
done

cd -

# Sample code: ./run.sh input_dir output_dir