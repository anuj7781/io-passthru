# Cachelib Experiments

# 1. Introduction #
* This section explains the Cachelib experimentation setup for Non-FDP and FDP cases. 
* Use one of the latest stable kernels in 6.1+ series (Ex: 6.1.34, 6.4.8 etc). We used 6.2 for most of the experiments

# 2. Build and Installlation #
## 2.1 Steps ##
* The normal method of Cachelib build and installation can be referred on https://github.com/facebook/CacheLib.
## 2.2	Install nvme-cli and libnvme ##
```
#nvme-cli and libnvme
git clone https://github.com/linux-nvme/nvme-cli.git
cd nvme-cli
meson setup --force-fallback-for=libnvme .build
meson compile -C .build
meson install -C .build
```
* If the meson version does not support "--force-fallback-for" argument, please install libnvme separately.
## 2.3 Build Non-FDP Cachelib ##
```
git clone https://github.com/facebook/CacheLib
cd CacheLib
./contrib/build.sh -d -j -v

# The resulting library and executables:
./opt/cachelib/bin/cachebench --help
```
## 2.4 Build FDP Cachelib ##
* FDP enabled Cachelib is available on https://github.com/arungeorge83/CacheLib/tree/fdp/blockcache_waf_reduction_upstream
```
git clone  https://github.com/OpenMPDK/CacheLib
git checkout fdp/blockcache_waf_reduction_upstream
cd CacheLib
./contrib/build.sh -d -j -v

# The resulting library and executables:
./opt/cachelib/bin/cachebench --help
```
## 2.5 Device Setup ##
* The following steps are used to setup a 4TB device
```
nvme delete-ns /dev/nvme0 -n 1
#Disable FD
nvme set-feature /dev/nvme0 -f 0x1D -c 0 -s
nvme get-feature /dev/nvme0 -f 0x1D -H

#enable FDP
nvme set-feature /dev/nvme0 -f 0x1D -c 1 -s
nvme get-feature /dev/nvme0 -f 0x1D -H

# Get capacity of drive and use it for further calculations
nvme id-ctrl /dev/nvme0 | grep tnvmcap

# Create namespace
nvme create-ns /dev/nvme0 -b 4096 --nsze=917148203 --ncap=917148203 -p 0,1,2,3 -n 4

#Attach namespace
nvme attach-ns /dev/nvme0 --namespace-id=1 --controllers=0x7

#Precondition - Deallocate
nvme dsm /dev/nvme0n1 -n 1 -b 917148203
```

# 3. Cachebench #
* Cachebench is the built-in workload generator with the Cachelib. It helps to run many synthetic and production workloads on Cachelib.
* A good reference of Cachebench can be found at https://cachelib.org/docs/Cache_Library_User_Guides/Configuring_cachebench_parameters/
* Example:
```
./opt/cachelib/bin/cachebench  --json_test_config cachelib/cachebench/test_configs/simple_test.json => shows running a simple cachelib instance without SSD.
```
* If you want to run hybrid cache(DRAM+SSD) instances,  check one of those configs listed under 'ssd_perf/', and configure the 'nvmCachePaths' and 'writeAmpDeviceList' accordingly. (Some of the configs shows the usage of raid devices, may have to change accordingly)
* Example:
```
./opt/cachelib/bin/cachebench  --json_test_config cachelib/cachebench/test_configs/ssd_perf/graph_cache_leader/config.json "nvmCachePaths": ["/dev/nvme0n1"]
```

# 4. Running Production Workloads #
* Cachebench provides a way to 'replay' production workloads on the cachelib instance.
* <Cachelib_Path>/website/docs/Cache_Library_User_Guides/Developing_for_Cachebench.md explains it in the section 'Replay production cache traces'.
* It can be downloaded from here https://cachelib.org/docs/Cache_Library_User_Guides/Cachebench_FB_HW_eval#running-cachebench-with-the-trace-workload.
```
  aws s3 cp --no-sign-request --recursive  s3://cachelib-workload-sharing/pub/ ./ --no-verify-ssl
  aws s3 ls --no-sign-request s3://cachelib-workload-sharing/pub/kvcache/202210/ --no-verify-ssl
```
* We also sometimes convert the workloads to 'write-only' to get faster results (sed -i '/GET/d' *.csv).
* For example, the regular KVCache workload takes more than a week to reproduce high-WAF scenarios, while a write-only KVCache workload takes only 2-3 days for the same on a 24-core machine.

## 4.1	Workload Running: Non-FDP Case ##
* Example: replay based config file. 
```
{
  "cache_config":
  {
    "cacheSizeMB": 43000,
    "cacheDir": "/root/cachelib_metadata",
    "allocFactor": 1.08,
    "maxAllocSize": 524288,
    "minAllocSize": 64,
    "navyReaderThreads": 72,
    "navyWriterThreads": 36,
    "nvmCachePaths": ["/dev/nvme1n1p2"],                               -> Needs to be changed to /dev/ng0n1 etc. for FDP case
    "nvmCacheSizeMB" : 952320,                                         -> Affects the OP (Cachelib utilization / Total Device Size)
    "writeAmpDeviceList": ["nvme1n1"],
    "navyBigHashBucketSize": 4096,
    "navyBigHashSizePct": 4,
    "navySmallItemMaxSize": 640,
    "navySegmentedFifoSegmentRatio": [1.0],
    "navyHitsReinsertionThreshold": 1,
    "navyBlockSize": 4096,
    "nvmAdmissionRetentionTimeThreshold": 7200,
    "navyParcelMemoryMB": 6048,
    "enableChainedItem": true,
    "htBucketPower": 29,
    "moveOnSlabRelease": false,
    "poolRebalanceIntervalSec": 2,
    "poolResizeIntervalSec": 2,
    "rebalanceStrategy": "hits"
  },
  "test_config":
  {
    "opRatePerSec": 550000,                                             -> Affects the QPS (1 M is better)
    "opRateBurstSize": 200,
    "enableLookaside": false,
    "generator": "replay",						-> Chooses the replay option
    "replayGeneratorConfig":
    {
        "ampFactor": 100						-> Scales the trace to real workload
    },
    "repeatTraceReplay": true,
    "repeatOpCount" : true,
    "onlySetIfMiss" : false,
    "numOps": 100000000000,
    "numThreads": 10,
    "prepopulateCache": true,
    "traceFileNames": [
            "kvcache_traces_1.csv",
            "kvcache_traces_2.csv",
            "kvcache_traces_3.csv",
            "kvcache_traces_4.csv",
            "kvcache_traces_5.csv"
    ]
  }
```

## 4.2 Workload Running: FDP Case ##
* Example: replay based config file. 

```
{
  "cache_config":
  {
    "cacheSizeMB": 20000,
    "cacheDir": "/root/cachelib_metadata-1",
    "allocFactor": 1.08,
    "maxAllocSize": 524288,
    "minAllocSize": 64,
    "navyReaderThreads": 72,
    "navyWriterThreads": 36,
    "nvmCachePaths": ["/dev/ng0n1"],                                    -> /dev/ng0n1 etc. for FDP case
    "nvmCacheSizeMB" : 2666496,
    "writeAmpDeviceList": ["nvme0n1"],
    "navyBigHashBucketSize": 4096,
    "navyBigHashSizePct": 0,
    "navySmallItemMaxSize": 640,
    "navySegmentedFifoSegmentRatio": [1.0],
    "navyHitsReinsertionThreshold": 1,
    "navyBlockSize": 4096,
    "nvmAdmissionRetentionTimeThreshold": 7200,
    "navyParcelMemoryMB": 6048,
    "enableChainedItem": true,
    "devicePlacement": true,                                            -> FDP Enable flag
    "htBucketPower": 29,
    "moveOnSlabRelease": false,
    "poolRebalanceIntervalSec": 2,
    "poolResizeIntervalSec": 2,
    "rebalanceStrategy": "hits"
  },
  "test_config":
  {
    "opRatePerSec": 1000000,
    "opRateBurstSize": 200,
    "enableLookaside": false,
    "generator": "replay",
    "replayGeneratorConfig":
    {
        "ampFactor": 200
    },
    "repeatTraceReplay": true,
    "repeatOpCount" : true,
    "onlySetIfMiss" : false,
    "numOps": 100000000000,
    "numThreads": 10,
    "prepopulateCache": true,
    "traceFileNames": [
        "kvcache_traces_1.csv",
        "kvcache_traces_2.csv",
        "kvcache_traces_3.csv",
        "kvcache_traces_4.csv",
        "kvcache_traces_5.csv"
    ]
  }
}

```
