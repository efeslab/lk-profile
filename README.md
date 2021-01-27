# kernel-pgo
Profile creation for Linux kernel profile-guided optimizations.

This project uses QEMU for system emulation to run benchmarks for specific
applications. These applications include 
Apache, Nginx, Redis, Memcached, Leveldb, Rocksdb, MySQL, and PostgreSQL.

GCOV data for these benchmarks is then collected to use for profile data 
creation. For more info:

https://www.kernel.org/doc/html/latest/dev-tools/gcov.html

https://www.man7.org/linux/man-pages/man1/gcov.1.html

# Build Linux Kernel
## Download
Download a Linux kernel 5.x version.

### 5.9.6
```
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.9.6.tar.xz
xz -cd linux-5.9.6.tar.xz | tar xvf -
```
Make sure you have the requirements to compile a Linux kernel

https://www.kernel.org/doc/html/v5.9/process/changes.html

## Configuration
```
cd linux-dir
make menuconfig
```
Set the following:
```
General architecture-dependent options --> GCOV-based kernel profiling --> Enable gcov-based kernel profiling
General architecture-dependent options --> GCOV-based kernel profiling --> Profile entire Kernel
Device Drivers --> Network device support --> Ethernet driver support --> Intel(R) PRO/1000 Gigabit Ethernet support
```

Save the config and double check that these variables are set in the `.config` file:
```
CONFIG_PVH=y
CONFIG_DEBUG_FS=y
CONFIG_GCOV_KERNEL=y
CONFIG_GCOV_PROFILE_ALL=y
CONFIG_E1000=y
```
## Compilation
In the kernel directory:
```
make CFLAGS_GCOV=-fprofile-generate -j8
```
# Build rootfs

## Ubuntu Base 20.04
Ubuntu Base is a minimal rootfs for use in the 
creation of custom images for specific needs.

### Download
```
wget https://cdimage.ubuntu.com/cdimage/ubuntu-base/releases/20.04/release/ubuntu-base-20.04.1-base-amd64.tar.gz
```

### Setup
```
# Creates the disk as images/ubuntu_base_20_04_1.img
./scripts/host/create-rootfs.sh images/ubuntu_base_20_04_1.img ubuntu_base_20_04_1-base-amd64.tar.gz
```

# Profile collection
## Run QEMU
Run the emulated system from the repository root:
```
./scripts/host/run-emulator.sh linux-5.9.6/vmlinux images/ubuntu_base_20_04_1.img
```
## Benchmarks
Make sure that you have dependences for the benchmark you want to run on the host.
Then, specify the application that you would like to collect data for:
```
GCOV=1 ./scripts/host/benchmark.sh {redis|memcached|apache|nginx|leveldb|rocksdb} output.log

GCOV=1 ./scripts/host/benchmark.sh {mysql|postgresql} {prepare|run|drop} output.log
```
If the benchmark is successful, run the following to get profile data:
```
./scripts/host/collect-gcov.sh linux-5.9.6 images/ubuntu_base_20_04_1.img benchmark
```
This will mount the rootfs to the host system and copy the data from the guest
to the host. There will be a `gcov-data` directory with the gcov data in 
`{benchmark}-profile.tar.gz` format.

### Apache/Nginx
Install Apache Bench

Ubuntu:
```
apt install apache2-utils
```
### Redis
Install `redis-benchmark`

Ubuntu:
```
apt install redis-server
```
When running the benchmark script for redis, you will need to `Ctrl+c` after the
server starts on the guest to get the benchmark to actually run.

### Memcached
Install `mc-benchmark`
```
git clone git@github.com:antirez/mc-benchmark.git
cd mc-benchmark
make
```
When running the benchmark script for memcached, you will need to `Ctrl+c` after the
server starts on the guest to get the benchmark to actually run.

### MySQL/PostgreSQL
Install latest sysbench

Ubuntu
```
apt install sysbench libpq-dev
```

# PGO
## Kernel Setup
### 5.9.6

Work around breakages with kvm. Update `arch/x86/kvm/Makefile` on line 3 to:
```
ccflags-y += -Iarch/x86/kvm -fno-profile-use
```

## Compilation
Specify which benchmark data you would like to re-compile the kernel with:
```
./scripts/host/kernel-pgo.sh linux-5.9.6 benchmark compile_output.log
```
