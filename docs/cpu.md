# CPU Collector

## Metric and label naming

* node_cpu_core_throttles_total
* node_cpu_guest_seconds_total
* node_cpu_package_throttles_total
* node_cpu_seconds_total node

## Metric and its data sources

Cpu collector access the following data sources.

### node_cpu_core_throttles_total, node_cpu_package_throttles_total

* /sys/devices/system/cpu/cpuN/thermal_throttle/package_throttle_count
* /sys/devices/system/cpu/cpuN/thermal_throttle/core_throttle_count
* /sys/devices/system/cpu/cpuN/topology/core_id
* /sys/devices/system/cpu/cpuN/topology/physical_package_id

NOTE: This metric is not available on all platforms.

### node_cpu_seconds_total, node_cpu_guest_seconds_total

* /proc/stat
