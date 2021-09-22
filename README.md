# fluent-plugin-node-exporter-metrics

[![CI on GitHub Actions](https://github.com/fluent-plugins-nursery/fluent-plugin-node-exporter-metrics/actions/workflows/linux-test.yaml/badge.svg)](https://github.com/fluent-plugins-nursery/fluent-plugin-node-exporter-metrics/actions/workflows/linux-test.yaml)

[Fluentd](https://fluentd.org/) input plugin to collect metrics which is similar to Fluent-bit's [node_exporter_metrics](https://docs.fluentbit.io/manual/pipeline/inputs/node-exporter-metrics).


fluent-plugin-node-exporter-metrics provides 2 types of input/parser plugins.

* node_exporter_metrics (Input plugin)
* node_exporter_metrics (Parser plugin, for debugging purpose)

## Installation

### Prerequisite

As fluent-plugin-node-exporter-metrics depends external libraries,
you must install dependency libraries in beforehand.

Note that CMake 3.13 or later must be installed.

### CentOS 7/RHEL 7

```
$ sudo yum install libcap-ng-devel gcc cmake3 make
```

### CentOS 8/RHEL 8

```
$ sudo dnf install libcap-ng-devel gcc cmake make
```


### RubyGems

```
$ gem install fluent-plugin-node-exporter-metrics
```

Or (If you already using td-agent)

```
$ sudo td-agent-gem install fluent-plugin-node-exporter-metrics
```

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-plugin-node-exporter-metrics"
```

And then execute:

```
$ bundle
```

## Documentation

### node_exporter_metrics (Input plugin)

11 collectors are available.
All collector is enabled by default.

See each collector documentation in details.

* [cpu](docs/cpu.md)
* [cpufreq](docs/cpufreq.md) (requires specific permission to use)
* [diskstats](docs/diskstats.md)
* [filefd](docs/filefd.md)
* [loadavg](docs/loadavg.md)
* [meminfo](docs/meminfo.md)
* [netdev](docs/netdev.md)
* [stat](docs/stat.md)
* [time](docs/time.md)
* [uname](docs/uname.md)
* [vmstat](docs/vmstat.md)

#### Configuration

| parameter       | type              | description                                                    | default |
|-----------------|-------------------|----------------------------------------------------------------|---------|
| scrape_interval | time (optional)   | Interval to scrape metrics from node                           | `5`     |
| procfs_path     | string (optional) | Path to mount point to collect process information and metrics | `/proc` |
| sysfs_path      | string (optional) | Path to file-system to collect system metrics                  | `/sys`  |
| tag             | string (optional) | Tag string                                                     |         |
| cpu             | bool (optional)   | Enable cpu collector                                           | `true`  |
| cpufreq         | bool (optional)   | Enable cpufreq collector                                       | `true`  |
| diskstats       | bool (optional)   | Enable diskstats collector                                     | `true`  |
| filefd          | bool (optional)   | Enable filefd collector                                        | `true`  |
| loadavg         | bool (optional)   | Enable loadavg collector                                       | `true`  |
| meminfo         | bool (optional)   | Enable meminfo collector                                       | `true`  |
| netdev          | bool (optional)   | Enable netdev collector                                        | `true`  |
| stat            | bool (optional)   | Enable stat collector                                          | `true`  |
| time            | bool (optional)   | Enable time collector                                          | `true`  |
| uname           | bool (optional)   | Enable uname collector                                         | `true`  |
| vmstat          | bool (optional)   | Enable vmstat collector                                        | `true`  |

Here is the sample configuration.

```
<source>
  @type node_exporter_metrics
  tag node_metrics
</source>
```

Event is emitted as `{"cmetrics": <MESSAGEPACK_BINARY_BLOBS>}`.

```
2021-09-21 10:47:54.255725938 +0900 node_metrics: {"cmetrics":"...."}
```

### node_exporter_metrics (Parser plugin, for debugging purpose only)

This parser plugin is designed for debugging purpose to check metrics binary blobs.

#### Configuration

No configuration parameters.

Here is the sample configuration to use `@type node_exporter_metrics` in filter section.

```
<source>
  @type node_exporter_metrics
  tag node_metrics
  cpu false
  cpufreq false
  diskstats false
  filefd false
  loadavg false
  meminfo false
  netdev false
  stat false
  time true
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

Here is the result.

```
2021-09-21 10:57:48.015023773 +0900 node_metrics: [{"name":"node_time_seconds","value":1.632189468,"desc":"System time in seconds since epoch (1970).","ts":1632189468014812147}]
```

## FAQ

### Why is error_class=Fluent::ConfigError error="Linux capability CAP_DAC_READ_SEARCH must be enabled" happen?

See [Prerequisite for cpufreq](docs/cpufreq.md#prerequisite) section for enabling cpufreq collector.

## Copyright

* Copyright(c) 2021- Kentaro Hayashi
* License
  * Apache License, Version 2.0
