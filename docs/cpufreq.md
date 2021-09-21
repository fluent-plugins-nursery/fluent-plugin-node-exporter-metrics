# Cpufreq Collector

## Prerequisite

If ruby binary is executed with non-root user, linux capability
must be enabled for cpufreq collector.

```sh
$ sudo setcap cap_dac_read_search=+eip PATH_TO_RUBY
```

If you already installed td-agent, you can use `fluent-cap-ctl`.

```sh
$ sudo fluent-cap-ctl --add dac_read_search -f PATH_TO_RUBY
```

## Metric and label naming

* node_cpu_frequency_hertz
* node_cpu_frequency_max_hertz
* node_cpu_frequency_min_hertz
* node_cpu_scaling_frequency_hertz
* node_cpu_scaling_frequency_max_hertz
* node_cpu_scaling_frequency_min_hertz
* node_time_seconds

NOTE: node_cpu_frequency_hertz is not available on all platforms.

## Metric and its data sources

Cpufreq collector access the following data sources.

* /sys/devices/system/cpu/cpuN/cpufreq/cpuinfo_cur_freq
* /sys/devices/system/cpu/cpuN/cpufreq/cpuinfo_max_freq
* /sys/devices/system/cpu/cpuN/cpufreq/cpuinfo_min_freq
* /sys/devices/system/cpu/cpuN/cpufreq/scaling_cur_freq
* /sys/devices/system/cpu/cpuN/cpufreq/scaling_max_freq
* /sys/devices/system/cpu/cpuN/cpufreq/scaling_min_freq

NOTE: cpuinfo_cur_freq is not available on all platforms, so 
there is case that node_cpu_frequency_hertz is not available.
