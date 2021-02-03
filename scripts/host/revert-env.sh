#!/bin/bash

set -e

# Enable turboboost
echo 0 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo

# Enable hyper threading
echo on | sudo tee /sys/devices/system/cpu/smt/control

# Set scaling governor to powersave
for i in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
do
    echo powersave | sudo tee $1
done

# Enable ASLR
echo 1 | sudo tee /proc/sys/kernel/randomize_va_space
