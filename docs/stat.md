# Stat Collector

## Metric and label naming

* node_boot_time_seconds
* node_context_switches_total
* node_forks_total
* node_intr_total
* node_procs_blocked
* node_procs_running

## Metric and its data sources

Stat collector access the following data sources.

* /proc/stat

## Examples

As metrics are collected in a binary form, use `@type node_exporter_metrics` parser.

```
<source>
  @type node_exporter_metrics
  tag node_metrics
  cpu true
  cpufreq false
  diskstats true
  filefd false
  loadavg false
  meminfo false
  netdev false
  stat false
  time false
  uname false
  vmstat false
</source>

<filter node_metrics>
  @type parser
  key_name cmetrics
  <parse>
    @type node_exporter_metrics
  </parse>
</filter>

<match node_metrics>
  @type stdout
</match>
```

Here is the result:

```
{"name":"node_cpu_seconds_total","value":16597.12,"desc":"Seconds the CPUs spent in each mode.","time":0,"labels":{"cpu":"0","mode":"idle"}},
...
```

