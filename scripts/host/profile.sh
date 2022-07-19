#!/bin/bash -e

RUNS=50

BENCHMARK=$1
BENCH_OUTPUT=${3:-$2}

if [[ -z "$BENCH_OUTPUT" || -z "$BENCHMARK" ]]; then
    echo "Usage: $0 benchmark path/to/output.log"
    exit 1
fi


source ./scripts/host/setup-env.sh

source ./scripts/host/benchmark.sh "$BENCHMARK" "$BENCHMARK" "$2" "$BENCH_OUTPUT"

sleep 5

source ./scripts/host/collect-pgo.sh images/ubuntu_20_04_1.img "$BENCHMARK" 

source ./scripts/host/revert-env.sh
