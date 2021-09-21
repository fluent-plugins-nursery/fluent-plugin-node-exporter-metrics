# Cpufreq Collector

## Prerequisite

If ruby binary is executed with non-root user, linux capability
must be enabled for cpufreq collector.

```sh
$ sudo setcap cap_dac_read_search=+eip PATH_TO_RUBY
```

If you already installed td-agent, you can use `fluent-cap-ctl`.

```sh
$ sudo /opt/td-agent/bin/fluent-cap-ctl --add dac_read_search -f /opt/td-agent/bin/ruby 
Updating dac_read_search done.
Adding dac_read_search done.
```

## Metric and label naming

* node_cpu_frequency_hertz {"cpu"=>...}
* node_cpu_frequency_max_hertz {"cpu"=>...}
* node_cpu_frequency_min_hertz {"cpu"=>...}
* node_cpu_scaling_frequency_hertz {"cpu"=>...}
* node_cpu_scaling_frequency_max_hertz {"cpu"=>...}
* node_cpu_scaling_frequency_min_hertz {"cpu"=>...}

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
