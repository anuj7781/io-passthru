Setup
=====

1. These experiments require us to be super user, which can be done using ```sudo su```

2. The setup consists of two Intel Optane Gen2 NVMe drives. NVMe device should
be formatted with 512b as lba-format, as experiments have been conducted with 512b workload,
```
# nvme id-ns -H /dev/nvme0n1

# nvme format --lbaf=0 /dev/nvme0n1
You are about to format nvme0n1, namespace 0x1.
WARNING: Format may irrevocably delete this device's data.
You have 10 seconds to press Ctrl-C to cancel this operation.

Use the force [--force] option to suppress this warning.
Sending format operation ...
Success formatting namespace:1

# nvme id-ns -H /dev/nvme0n1
LBA Format  0 : Metadata Size: 0   bytes - Data Size: 512 bytes - Relative Performance: 0x2 Good (in use)
LBA Format  1 : Metadata Size: 8   bytes - Data Size: 512 bytes - Relative Performance: 0x2 Good
LBA Format  2 : Metadata Size: 0   bytes - Data Size: 4096 bytes - Relative Performance: 0x2 Good
LBA Format  3 : Metadata Size: 8   bytes - Data Size: 4096 bytes - Relative Performance: 0x2 Good
LBA Format  4 : Metadata Size: 64  bytes - Data Size: 4096 bytes - Relative Performance: 0x2 Good


# nvme list
Node                  Generic               SN                   Model                                    Namespace Usage                      Format           FW Rev
--------------------- --------------------- -------------------- ---------------------------------------- --------- -------------------------- ---------------- --------
/dev/nvme1n1          /dev/ng1n1            PHAL11730018400AGN   INTEL SSDPF21Q400GB                      1         400.09  GB / 400.09  GB    512   B +  0 B   L0310200
/dev/nvme0n1          /dev/ng0n1            PHAL1185001D400AGN   INTEL SSDPF21Q400GB                      1         400.09  GB / 400.09  GB    512   B +  0 B   L0310100
```

3. Enable poll_queues in the NVMe driver system wide
```
# modprobe -r nvme && modprobe nvme poll_queues=1
# cat /sys/block/nvme0n1/queue/io_poll
1
```

Peak performance using single CPU core
======================================
measure_linear_core.sh uses single cpu core for one device to measure peak
performance of io_uring_char and io_uring_block path.

1. Copy the script to your fio repo ```cp benchmark/measure-linear-core.sh /home/test/fio/```

2. Run the script, pass 1 (# of nvme-devices) as argument.

3. Results will be placed in pt1 and blk1 files in the output directory.

Sample command:
```
# ./measure-linear-core.sh 1
```

Scalability across queue-depths
===============================
measure_scaling.sh compares the scalability of io_uring_char and io_uring_block path
across different queue-depths.

1. Copy the script to your fio repo ```cp benchmark/measure-scaling.sh /home/test/fio/```

2. Run the script, pass two arguments: char-device and block-device, respectively.

3. Results will be placed in pt and blk file in the output directory.

Sample command:
```
# ./measure-scaling.sh /dev/ng0n1 /dev/nvme0n1
```

Scalability across multiple devices
===================================
measure_linear_core.sh uses a distinct core for each device to measure peak performance
of io_uring_char and io_uring_block path across multiple devices.

1. Copy the script to your fio repo  ```cp benchmark/measure-linear-core.sh /home/test/fio/```

2. Run the script, pass number of nvme-devices as argument.

3. Results will be placed in pt${device_count} and blk${device_count} files in the output directory.

Sample command:
```
# ./measure-linear-core.sh 2
```

Submission latency and cpu-utilization
=======================================
measure-fb-latency.sh measures the latency and cpu-util of io_uring_char and io_uring_block_path with/without fixed-buffers
across different block sizes.

1. Copy the script to your fio repo  ```cp benchmark/measure-fb-latency.sh /home/test/fio/```

2. Run the script, pass two arguments: char-device and block-device, respectively.

3. Results will be placed in the output directory, corresponding to each fio run.

Sample command:
```
# ./measure-fb-latency.sh /dev/ng0n1 /dev/nvme0n1
```

Sqpoll and batching
===================
measure-sqpoll-batching.sh measures the effect of sqpoll and batching for io_uring_char
and io_uring_block path.

1. Copy the script to your fio repo  ```cp benchmark/measure-sqpoll-batching.sh /home/test/fio/```

2. Run the script, pass three arguments: sqpoll disabled/enabled, char-device and block-device, respectively.

3. The first run will capture results for sqpoll disabled scenario.

Sample command:
```
# ./measure-sqpoll-batching.sh 0 /dev/ng0n1 /dev/nvme0n1
```

4. t/io_uring needs to be modified in-order-to enable sqpoll -
```
# git diff t/io_uring.c
diff --git a/t/io_uring.c b/t/io_uring.c
index bf0aa26e..a32b2e4c 100644
--- a/t/io_uring.c
+++ b/t/io_uring.c
@@ -132,8 +132,8 @@ static int fixedbufs = 1;   /* use fixed user buffers */
 static int dma_map;            /* pre-map DMA buffers */
 static int register_files = 1; /* use fixed files */
 static int buffered = 0;       /* use buffered IO, not O_DIRECT */
-static int sq_thread_poll = 0; /* use kernel submission/poller thread */
-static int sq_thread_cpu = -1; /* pin above thread to this CPU */
+static int sq_thread_poll = 1; /* use kernel submission/poller thread */
+static int sq_thread_cpu = 5; /* pin above thread to this CPU */
 static int do_nop = 0;         /* no-op SQ ring commands */
 static int nthreads = 1;
 static int stats = 0;          /* generate IO stats */

# make -j32
CC t/io_uring.o
LINK t/io_uring
```

5. After making changes in t/io_uring and compilation, we run the same script again
   this time with sqpoll enabled.
Sample command:
```
# ./measure-sqpoll-batching.sh 1 /dev/ng0n1 /dev/nvme0n1
```
