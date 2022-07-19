# One Profile Fits All: Profile-Guided Linux Kernel Optimizations

The scripts here support Clang-based PGO and GCOV-based profile collection for
the Linux kernel. This project uses QEMU for system emulation to run benchmarks 
for specific data center applications. These applications include Apache, 
Nginx, Redis, Memcached, Leveldb, Rocksdb, MySQL, and PostgreSQL. 


```
@article{ugur2022oneprof,
    author = {Ugur, Muhammed and Jiang, Cheng and Erf, Alex and Ahmed Khan, Tanvir and Kasikci, Baris},
    title = {One Profile Fits All: Profile-Guided Linux Kernel Optimizations for Data Center Applications},
    year = {2022},
    month = {jun},
    publisher = {Association for Computing Machinery},
    address = {New York, NY, USA},
    volume = {56},
    number = {1},
    doi = {10.1145/3544497.3544502},
    journal = {SIGOPS Oper. Syst. Rev.},
    pages = {26–33},
}
```

For more info on GCOV:

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

### 5.11
```
wget https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-5.11.tar.xz
xz -cd linux-5.11.tar.xz | tar xvf -
```
Make sure you have the requirements to compile a Linux kernel

https://www.kernel.org/doc/html/v5.11/process/changes.html


## Configuration

Check `configs` for previously set configurations for specific kernel versions.

Manual configuration:

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
For Clang-based PGO, apply the appropriate patch (i.e. `patches/clang-pgo-v9.patch`).

In the kernel directory:
```
make -j8
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

## Environment

Update system settings before running benchmarks:

```
./scripts/host/setup-env.sh
```

```
./scripts/host/revert-env.sh
```

## Benchmarks

Make sure that you have dependences for the benchmark you want to run on the host.
Then, specify the application that you would like to collect data for and also
whether you would like to use GCOV `GCOV=1` or Clang-based PGO `PROFILE=1`. Feel
free to change the benchmark parameters in `scripts/host/benchmark.sh` as necessary:
```
./scripts/host/benchmark.sh {redis|memcached|apache|nginx|leveldb|rocksdb|mysql|postgresql} {profile_name} {options} {path/to/output.log}
```
If the benchmark is successful, run the following to get profile data for GCOV:
```
./scripts/host/collect-gcov.sh linux-5.9.6 images/ubuntu_base_20_04_1.img benchmark
```
This will mount the rootfs to the host system and copy the data from the guest
to the host. There will be a `gcov-data` directory with the gcov data in 
`{benchmark}-profile.tar.gz` format.

For Clang:
```
./scripts/host/collect-pgo.sh images/ubuntu_base_20_04_1.img {profile_name}
```

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

For GCOV, work around breakages with kvm. Update `arch/x86/kvm/Makefile` on line 3 to:
```
ccflags-y += -Iarch/x86/kvm -fno-profile-use
```

## Compilation
Specify which benchmark data you would like to re-compile the kernel with.

For Clang:
```
./scripts/host/pgo.sh {profile_name}
```
