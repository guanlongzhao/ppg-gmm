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

# The expected organization is,
# $input_dir
# ├── recordings
# │   ├── 0001.wav
# │   ├── 0002.wav
# │   ├── 0003.wav

n_split=8

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. ./cmd.sh
[ -h steps ] || ln -s $KALDI_ROOT/egs/wsj/s5/steps
[ -h utils ] || ln -s $KALDI_ROOT/egs/wsj/s5/utils
. utils/parse_options.sh || exit 1;

# Input
if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <src-dir> <dst-dir>"
  echo "e.g.: $0 /export/data/speaker data/speaker"
  echo "options:"
  echo "  --n_split 8"
  exit 1
fi

src=$1
dst=$2

# Setting
if [ ! -d $dst ]; then
  echo "Creating output dir $dst"
  mkdir -p $dst || exit 1;
fi
[ ! -d $src ] && echo "$0: no such directory $src" && exit 1;
wav_scp=$dst/wav.scp; [[ -f "$wav_scp" ]] && rm $wav_scp
utt2spk=$dst/utt2spk; [[ -f "$utt2spk" ]] && rm $utt2spk

# Get wav.scp and utt2spk
# all spakers' root dirs
reader_dir=$src
reader=$(basename $reader_dir)
wav_dir=$reader_dir  # dir that contains wave files
[ ! -d $wav_dir ] && echo "$0: expected dir $wav_dir to exist" && exit 1;
# create wav.scp, mapping from utt_id to utt location
find -L $wav_dir/ -iname "*.wav" | sort | xargs -I% basename % .wav | \
awk -v "dir=$wav_dir" -v "reader=$reader" '{printf "%s_%s %s/%s.wav\n", reader,\
$0, dir, $0}' >>$wav_scp || exit 1
# create utt2spk
find -L $wav_dir/ -iname "*.wav" | sort | xargs -I% basename % .wav | \
awk -v "reader=$reader" '{printf "%s_%s %s\n", reader, $0, reader}' >>$utt2spk || exit 1

# Get spk2utt
spk2utt=$dst/spk2utt
utils/utt2spk_to_spk2utt.pl <$utt2spk >$spk2utt || exit 1

# Validation
utils/validate_data_dir.sh --no-feats --no-text $dst || exit 1;

# Data split
utils/split_data.sh --per-utt $dst $n_split

# Get MFCCs
splits=$n_split
# splits=1 # for debug
mkdir -p $dst/make_mfcc_log/
mkdir -p $dst/mfcc/
for part in $(seq $splits); do 
  steps/make_mfcc.sh --cmd utils/run.pl --mfcc-config ./conf/mfcc.conf --nj 8 --write-utt2num-frames true \
    $dst/split$n_split\utt/$part/ $dst/make_mfcc_log/$part $dst/mfcc/$part

# Get CMVN stats
  steps/compute_cmvn_stats.sh $dst/split$n_split\utt/$part/ $dst/make_mfcc_log/$part $dst/mfcc/$part
done
