#!/bin/bash

set -e

PROFILE=${1:-}

if [[ -z $PROFILE ]]; then
    echo "Usage: $0 path/to/profile.profdata"
    exit 1
fi

cd linux

echo "Copying config"
cp ../configs/config-5.11 .

echo "Cleaning build..."
make clean
echo "Finished cleaning!"

echo "Compiling kernel..."
make \
    CC=clang-13 \
    LD=ld.lld-13 \
    AR=llvm-ar-13 \
    NM=llvm-nm-13 \
    STRIP=llvm-strip-13 \
    OBJCOPY=llvm-objcopy-13 \
    OBJDUMP=llvm-objdump-13 \
    READELF=llvm-readelf-13 \
    HOSTCC=clang-13 \
    HOSTCXX=clang++-13 \
    HOSTAR=llvm-ar-13 \
    HOSTLD=ld.lld-13 \
    LLVM_IAS=1 \
    KCFLAGS="-fprofile-use=$PROFILE" \
    -j8
