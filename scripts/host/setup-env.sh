#!/bin/bash

set -e

# Disable turboboost
echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo

# Disable hyper threading
echo off | sudo tee /sys/devices/system/cpu/smt/control

# Set scaling governor to performance
for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
do
    echo performance | sudo tee $1
done

# Drop file system cache
echo 3 | sudo tee /proc/sys/vm/drop_caches
sync

# Disable ASLR
echo 0 | sudo tee /proc/sys/kernel/randomize_va_space
