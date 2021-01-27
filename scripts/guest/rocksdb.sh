#!/bin/bash

wget https://github.com/facebook/rocksdb/archive/v6.15.2.tar.gz -O rocksdb.tar.gz
tar -zxvf rocksdb.tar.gz
rm rocksdb.tar.gz
mv rocksdb-6.15.2 root/rocksdb
cd root/rocksdb
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DWITH_SNAPPY=bundled .. && cmake --build . -j8
