#!/bin/bash

set -e

LINUX=${1:-}
APP=${2:-}
COMPILE_LOG=${3:-}

if [[ -z $APP || -z $LINUX || -z $COMPILE_LOG ]]; then
    echo "Usage: $0 linux-version {redis|memcached|nginx|apache|leveldb|rocksdb|mysql|postgresql} compile.log"
    exit 1
fi

BUILD_DIR="$(pwd)"/$LINUX
GCOV_DATA="$(pwd)"/gcov-data/$APP

make_path() {
    echo $1 | sed -r 's/[/]+/#/g'
}

echo "Copying profile to build directory..."
FILES=$(find $GCOV_DATA -depth -type f -name "*.gcda")
for FILE in ${FILES[@]}; do
    FLAT=$(make_path $FILE)
    HEAD=${FLAT##*$APP}
    NEW="$(make_path $BUILD_DIR)$HEAD"
    cp $FILE $BUILD_DIR/$NEW
done
echo "Finished copying!"

cd $LINUX

echo "Cleaning build..."
make clean
echo "Finished cleaning!"

echo "Compiling kernel..."

# Useful flags:
#
# -Wno-missing-profile
# V=1
# CC=/usr/bin/gcc-version
#
make \
    KCFLAGS="-fprofile-use=$BUILD_DIR -fprofile-correction -Wno-coverage-mismatch -Wno-error=coverage-mismatch" \
    -j8 \
    2>&1 | tee ../$COMPILE_LOG

find . -name "*.gcda" -exec rm {} \;

