#!/bin/bash -e

NEW_IMAGE=${1:-}
ROOTFS_TAR=${2:-}

if [[ -z $NEW_IMAGE || -z $ROOTFS_TAR ]]; then
    echo "Usage: $0 name_of_new_disk.img path/to/rootfs.tar.gz"
    exit 1
fi

mkdir -p images

BASEDIR="$(pwd)"
DISK=$BASEDIR/images/$NEW_IMAGE
TAR=$ROOTFS_TAR

MOUNT=/mnt/tmpfs

# 16 GB
dd if=/dev/zero of=$DISK bs=4096 count=4M

mkfs.ext4 $DISK
sudo mkdir -p $MOUNT
sudo mount -o loop $DISK $MOUNT
sudo tar zxvf $TAR -C $MOUNT

sudo cp /etc/resolv.conf $MOUNT/etc/
sudo cp $BASEDIR/scripts/guest/packages.sh $MOUNT/root/
sudo cp $BASEDIR/scripts/guest/init.sh $MOUNT/root/
sudo cp $BASEDIR/scripts/guest/ssh.sh $MOUNT/root/
sudo cp $BASEDIR/scripts/guest/gather.sh $MOUNT/root/
sudo cp $BASEDIR/scripts/guest/leveldb.sh $MOUNT/root/
sudo cp $BASEDIR/scripts/guest/rocksdb.sh $MOUNT/root/

sudo mount -t proc /proc $MOUNT/proc
sudo mount -t sysfs /sys $MOUNT/sys
sudo mount -o bind /dev $MOUNT/dev
sudo mount -o bind /dev/pts $MOUNT/dev/pts

sudo chroot $MOUNT /bin/bash -c "
./root/packages.sh
./root/init.sh
./root/ssh.sh
./root/leveldb.sh
./root/rocksdb.sh

exit
"
# Configurations
sudo cp $BASEDIR/overlay/etc/redis.conf $MOUNT/etc/redis
sudo cp $BASEDIR/overlay/etc/nginx.conf $MOUNT/etc/nginx
sudo cp $BASEDIR/overlay/etc/mysqld.cnf $MOUNT/etc/mysql/mysql.conf.d
sudo cp $BASEDIR/overlay/etc/pg_hba.conf $MOUNT/etc/postgresql/12/main
sudo cp $BASEDIR/overlay/etc/postgresql.conf $MOUNT/etc/postgresql/12/main

sudo umount $MOUNT/proc
sudo umount $MOUNT/sys
sudo umount $MOUNT/dev/pts
sudo umount $MOUNT/dev
sudo umount $MOUNT
