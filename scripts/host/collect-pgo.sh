#!/bin/bash -e

DISK=${1:-}
PROFILE_NAME=${2:-}

if [[ -z $PROFILE_NAME || -z $DISK ]]; then
    echo "Usage: $0 path/to/disk.img profile_name"
    exit 1
fi

MOUNTDIR=/mnt/tmppgofs
BASEDIR=$(pwd)
OUTPUTDIR=$BASEDIR/profiles

sudo mkdir -p $MOUNTDIR
mkdir -p $OUTPUTDIR

# Copy data to output directory
sudo mount -t ext4 $DISK $MOUNTDIR
sudo cp $MOUNTDIR/$PROFILE_NAME* $OUTPUTDIR
sudo umount $MOUNTDIR

sudo chmod 644 $OUTPUTDIR/$PROFILE_NAME*
sudo chown $(whoami):$(whoami) $OUTPUTDIR/$PROFILE_NAME*

