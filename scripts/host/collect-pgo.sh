#!/bin/bash -e

DISK=${1:-}
APP=${2:-}

if [[ -z $APP || -z $DISK ]]; then
    echo "Usage: $0 path/to/disk.img prof-name"
    exit 1
fi

MOUNTDIR=/mnt/tmppgofs
BASEDIR=$(pwd)
OUTPUTDIR=$BASEDIR/pgo-data
APPDIR=$OUTPUTDIR/$APP

APPDATA=$APP.profraw

sudo mkdir -p $MOUNTDIR
mkdir -p $APPDIR

# Copy data to output directory
sudo mount -t ext4 $DISK $MOUNTDIR
sudo cp $MOUNTDIR/$APPDATA $APPDIR
sudo umount $MOUNTDIR

sudo chmod 644 $APPDIR/$APPDATA
sudo chown meugur:meugur $APPDIR/$APPDATA
