# Uname Collector

## Metric and label naming

* node_uname_info

## Metric and its data sources

Uname collector access the following data sources.

* Etc.uname

NOTE: `Etc.uname` returns at least sysname,release,version,machine,nodename
but it is not guaranteed to return domainname.
