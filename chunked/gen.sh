#!/usr/bin/bash
set -eux

export BATCH="2023-04-28"

export MPD=stream.mpd
export INPUT_STREAM_ID=t16
export INPUT_DIR=output/cfhd_sets/12.5_25_50/$INPUT_STREAM_ID/$BATCH/
export OUTPUT_STREAM_ID=chunked
export OUTPUT=chunked
export OUTPUT_DIR=output/cfhd_sets/12.5_25_50/$OUTPUT_STREAM_ID/$BATCH/


# clean copy of input
mkdir -p $OUTPUT_DIR
rm -rf $OUTPUT_DIR/*
cp -r $INPUT_DIR/* $OUTPUT_DIR/


#######################################################
# chunking
pushd $OUTPUT_DIR/1

## styp generation: take it from the first segment
head -c12 0.m4s > styp

## chunk segments
for f in `ls *.m4s`; do
    $(dirname $0)/isobmff_chunker.py 5 `basename $f .m4s`
    rm $f
done

rm styp

## modify MPD
cp $(dirname $0)/stream.mpd ../stream.mpd

popd
#######################################################

# zip
pushd output
rm cfhd_sets/12.5_25_50/$OUTPUT_STREAM_ID/$BATCH/$INPUT_STREAM_ID.zip
zip -r cfhd_sets/12.5_25_50/$OUTPUT_STREAM_ID/$BATCH/$OUTPUT_STREAM_ID.zip cfhd_sets/12.5_25_50/$OUTPUT_STREAM_ID/$BATCH/*
popd
