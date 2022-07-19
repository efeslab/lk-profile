#!/bin/bash -e

# Disable turboboost
echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo

# Set scaling governor to performance
for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    echo performance | sudo tee "$i"
done

# Disable hyper threading
echo off | sudo tee /sys/devices/system/cpu/smt/control

# Disable ASLR
echo 0 | sudo tee /proc/sys/kernel/randomize_va_space

# Drop file system cache
echo 3 | sudo tee /proc/sys/vm/drop_caches
sync
