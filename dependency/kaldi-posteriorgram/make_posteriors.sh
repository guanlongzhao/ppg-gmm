#!/bin/bash

# Copyright 2014  Pegah Ghahremani
#           2017  Guanlong Zhao
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

# Guanlong adapted from dump_bottleneck_features.sh, this script extracts posteriors
# given input acoustic frames


# Begin configuration section.
feat_type= # input features to nnet, i.e., how the nnet model was trained
stage=1 # training stage
nj=8 # number of parallel jobs
cmd=run.pl # how to run jobs

# Begin configuration.
transform_dir= # fMLLR transforms

# End configuration options.

echo "$0 $@"  # Print the command line for logging

[ -f path.sh ] && . ./path.sh # source the path.
. ./cmd.sh
[ -h steps ] || ln -s $KALDI_ROOT/egs/wsj/s5/steps
[ -h utils ] || ln -s $KALDI_ROOT/egs/wsj/s5/utils
. utils/parse_options.sh || exit 1;

if [ $# != 5 ]; then
   echo "usage: ./make_posteriors.sh <input-data-dir> <output-data-dir> <bnf-nnet-dir> <archive-dir> <log-dir>"
   echo "inputs:"
   echo "  <input-data-dir>   dir that contains Kaldi-formatted data structure"
   echo "  <output-data-dir>  folder that contains the output log-posteriors (.scp file)"
   echo "  <bnf-nnet-dir>     folder that contains pretrained nnet2 model (in raw format)"
   echo "  <archive-dir>      folder to hold output log-posteriors (.ark files)"
   echo "  <log-dir>          folder that holds log files"
   echo "e.g.:  ./make_posteriors.sh data/train data/train/post exp/nnet data/train/post exp/dump_post_log"
   echo "  --nj <nj>                                        # number of parallel jobs"
   echo "  --cmd (utils/run.pl|utils/queue.pl <queue opts>) # how to run jobs."
   exit 1;
fi

data=$1
bnf_data=$2
nnetdir=$3
archivedir=$4
dir=$5

# Assume that final.raw is in nnetdir, it should be a raw model
bnf_nnet=$nnetdir/final.raw
if [ ! -f $bnf_nnet ] ; then
  echo "No such file $bnf_nnet";
  exit 1;
fi

# Set up input features of nnet

# Figure out the input feature type to the nnet
if [ -z "$feat_type" ]; then
  # No input flag: if there's LDA transform matrix, then nnet requires LDA features
  if [ -f $nnetdir/final.mat ]; then
    feat_type=lda;
  fi
fi
echo "$0: feature type is $feat_type"

if [ "$feat_type" == "lda" ] && [ ! -f $nnetdir/final.mat ]; then
  echo "$0: no such file $nnetdir/final.mat" # LDA feature type requires LDA transform matrix
  exit 1
fi

# Split data
name=`basename $data`
sdata=$data/split$nj\utt

mkdir -p $dir/log
mkdir -p $bnf_data
echo $nj > $nnetdir/num_jobs
splice_opts=`cat $nnetdir/splice_opts 2>/dev/null`
[[ -d $sdata && $data/feats.scp -ot $sdata ]] || split_data.sh --per-utt $data $nj || exit 1;

# Generate input features to nnet CMVN + delat|splice-features + [lda-transform]
case $feat_type in
  raw) feats="ark,s,cs:apply-cmvn --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- |";;
  lda) feats="ark,s,cs:apply-cmvn --utt2spk=ark:$sdata/JOB/utt2spk scp:$sdata/JOB/cmvn.scp scp:$sdata/JOB/feats.scp ark:- | splice-feats $splice_opts ark:- ark:- | transform-feats $nnetdir/final.mat ark:- ark:- |"
   ;;
  *) echo "Invalid feature type $feat_type" && exit 1;
esac

# Per speaker adaptation, if any fMLLR transform is available
if [ ! -z "$transform_dir" ]; then
  echo "Using transforms from $transform_dir"
  [ ! -f $transform_dir/trans.1 ] && echo "No such file $transform_dir/trans.1" && exit 1;
  transform_nj=`cat $transform_dir/num_jobs` || exit 1;
  if [ "$nj" != "$transform_nj" ]; then
    for n in $(seq $transform_nj); do cat $transform_dir/trans.$n; done >$dir/trans.ark
    feats="$feats transform-feats --utt2spk=ark:$sdata/JOB/utt2spk ark,s,cs:$dir/trans.ark ark:- ark:- |"
  else
    feats="$feats transform-feats --utt2spk=ark:$sdata/JOB/utt2spk ark,s,cs:$transform_dir/trans.JOB ark:- ark:- |"
  fi
fi

# Feed the given nnet with processed features and perform the forward pass
# Generate the output posteriors and store in Kaldi's ark format
if [ $stage -le 1 ]; then
  echo "Making Posterior scp and ark."
  $cmd JOB=1:$nj $dir/log/make_bnf_$name.JOB.log \
    nnet-compute --apply-log=false $bnf_nnet "$feats" ark:- \| \
    copy-feats ark:- ark,scp:$archivedir/raw_bnfeat_$name.JOB.ark,$archivedir/raw_bnfeat_$name.JOB.scp || exit 1;
fi

rm $dir/trans.ark 2>/dev/null

N0=$(cat $data/feats.scp | wc -l)
N1=$(cat $archivedir/raw_bnfeat_$name.*.scp | wc -l)
if [[ "$N0" != "$N1" ]]; then
  echo "Error happens when generating BNF for $name (Original:$N0  BNF:$N1)"
  exit 1;
fi

# Concatenate feats.scp into bnf_data
for n in $(seq $nj); do  cat $archivedir/raw_bnfeat_$name.$n.scp; done > $bnf_data/feats.scp

for f in segments spk2utt text utt2spk wav.scp char.stm glm kws reco2file_and_channel stm; do
  [ -e $data/$f ] && cp -r $data/$f $bnf_data/$f
done

echo "$0: computing CMVN stats."
steps/compute_cmvn_stats.sh $bnf_data $dir $archivedir

echo "$0: done making BNF feats.scp."

exit 0;
