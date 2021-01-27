#!/bin/bash

wget https://github.com/google/leveldb/archive/1.22.tar.gz -O leveldb.tar.gz
tar -zxvf leveldb.tar.gz
rm leveldb.tar.gz
mv leveldb-1.22 root/leveldb
cd root/leveldb
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release .. && cmake --build .
