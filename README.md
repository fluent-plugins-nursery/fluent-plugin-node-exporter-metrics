# fluent-plugin-node-exporter-metrics

[Fluentd](https://fluentd.org/) input plugin to do something.

TODO: write description for you plugin.

## Installation

### RubyGems

```
$ gem install fluent-plugin-node-exporter-metrics
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

# Documentation

There are 11 collectors available.

* [cpu](docs/cpu.md)
* [cpufreq](docs/cpufreq.md)
* [diskstats](docs/diskstats.md)
* [filefd](docs/filefd.md)
* [loadavg](docs/loadavg.md)
* [meminfo](docs/meminfo.md)
* [netdev](docs/netdev.md)
* [stat](docs/stat.md)
* [time](docs/time.md)
* [uname](docs/uname.md)
* [vmstat](docs/vmstat.md)

## Configuration

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


## Copyright

* Copyright(c) 2021- Kentaro Hayashi
* License
  * Apache License, Version 2.0
