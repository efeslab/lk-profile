#!/bin/bash

set -e 

KERNEL=${1:-}
DISK=${2:-}

if [[ -z $KERNEL || -z $DISK ]]; then
    echo "Usage: $0 path/to/vmlinux path/to/disk.img"
    exit 1
fi

qemu-system-x86_64 \
    -kernel $KERNEL \
    -boot c \
    -m 2048 \
    -hda $DISK \
    -append 'root=/dev/sda rw console=ttyS0 nokaslr' \
    -display none \
    -serial mon:stdio \
    -enable-kvm \
    -cpu host \
    -smp 1 \
    -nic user,hostfwd=tcp::7369-:7369,hostfwd=tcp::1080-:80,hostfwd=tcp::2222-:22,hostfwd=tcp::3306-:3306,hostfwd=tcp::5432-:5432

