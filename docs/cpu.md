# CPU Collector

## Metrics and corresponding entry

### node_cpu_core_throttles_total, node_cpu_package_throttles_total

* /sys/devices/system/cpu/cpuN/thermal_throttle/package_throttle_count
* /sys/devices/system/cpu/cpuN/thermal_throttle/core_throttle_count
* /sys/devices/system/cpu/cpuN/topology/core_id
* /sys/devices/system/cpu/cpuN/topology/physical_package_id

### node_cpu_seconds_total node_cpu_guest_seconds_total

* /proc/stat

```
node_cpu_seconds_total{cpu="0",mode="idle"} = 20292.34
node_cpu_seconds_total{cpu="0",mode="iowait"} = 325.64999999999998
node_cpu_seconds_total{cpu="0",mode="irq"} = 0
node_cpu_seconds_total{cpu="0",mode="nice"} = 6.5
node_cpu_seconds_total{cpu="0",mode="softirq"} = 331.44
node_cpu_seconds_total{cpu="0",mode="steal"} = 0
node_cpu_seconds_total{cpu="0",mode="system"} = 76.25
node_cpu_seconds_total{cpu="0",mode="user"} = 245.50999999999999
node_cpu_seconds_total{cpu="1",mode="idle"} = 20436.389999999999
node_cpu_seconds_total{cpu="1",mode="iowait"} = 157.58000000000001
node_cpu_seconds_total{cpu="1",mode="irq"} = 0
node_cpu_seconds_total{cpu="1",mode="nice"} = 8.6799999999999997
node_cpu_seconds_total{cpu="1",mode="softirq"} = 73.989999999999995
node_cpu_seconds_total{cpu="1",mode="steal"} = 0
node_cpu_seconds_total{cpu="1",mode="system"} = 89.480000000000004
node_cpu_seconds_total{cpu="1",mode="user"} = 259.69999999999999
```
