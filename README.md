# Overview
* Installing Linux
* Installing fio

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

# Benchmarking
* Please refer to the benchmark subdirectory in this repo.
  Link: https://github.com/anuj7781/io-passthru/tree/master/benchmark
