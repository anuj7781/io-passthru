This repository contains the artifacts of I/O Passthru: Upstreaming a flexible and
efficient I/O Path in Linux published at FAST'24 : https://www.usenix.org/conference/fast24/presentation/joshi

# Overview
* Installing Linux
* Installing fio

# Ubuntu Distro
* The performance was benchmarked using 6.2 kernel. 6.2 kernel comes preinstalled with ubuntu 23.04 (or Ubuntu 22.04.3 LTS). Please see this: https://ubuntu.com/about/release-cycle#ubuntu-kernel-release-cycle
* Ubuntu 23.04 iso: https://releases.ubuntu.com/lunar/ubuntu-23.04-desktop-amd64.iso
* Or we can install custom kernel as shown below,

# Installing Linux
* Clone upstream linux repo: ```git clone https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git```
* Change directory: ```cd linux```
* Checkout v6.2: ```git checkout v6.2```
* Tools installation: ```sudo apt-get install git build-essential kernel-package fakeroot libncurses5-dev libssl-dev ccache bison flex libelf-dev dwarves zstd```
* Copy the existing kernel config: ```cp /boot/config-$(uname -r) .config```
* Update current config utilising a provided .config as base: ```make olddefconfig```
* Compile the kernel: ```make -j $(getconf _NPROCESSORS_ONLN)```
* Installing the kernel: ```sudo make modules_install install -j $(getconf _NPROCESSORS_ONLN)```
* Install headers:  ```make HEADERS_INSTALL INSTALL_HDR_PATH=/usr```
* Reboot and select required kernel from grub-menu
* Verify the kernel booted is custom build by, ```uname -r```
* Refer: https://kernelnewbies.org/KernelBuild

# Installing fio
* Clone upstream fio: ```git clone https://github.com/axboe/fio```
* Change directory: ```cd fio```
* Checkout fio-3.35: ```git checkout fio-3.35```
* Compile fio: ```make -j $(getconf _NPROCESSORS_ONLN)```
* Install  fio: ```make install```

# Userspace Integration

Link to patches for adding userspace support:

* xNVMe io_uring_cmd engine: ```https://github.com/OpenMPDK/xNVMe/pull/51```
* xNVMe big sqe/cqe support: ```https://github.com/OpenMPDK/xNVMe/pull/84```
* spdk: ```https://github.com/spdk/spdk/commit/6f338d4bf3a8a91b7abe377a605a321ea2b05bf7```
* fio: ```https://lore.kernel.org/fio/20220531133155.17493-1-ankit.kumar@samsung.com/```
* t/io_uring: ```https://lore.kernel.org/fio/20220826113306.4139-1-anuj20.g@samsung.com/```

# Benchmarking
* Please refer to the benchmark subdirectory in this repo.
  Link: https://github.com/anuj7781/io-passthru/tree/master/benchmark
