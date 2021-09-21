# Diskstats Collector

## Metric and label naming

* node_disk_discard_time_seconds_total {"device"=>...}
* node_disk_discards_completed_total {"device"=>...}
* node_disk_discards_merged_total {"device"=>...}
* node_disk_discards_sectors_total {"device"=>...}
* node_disk_flush_requests_time_seconds_total {"device"=>...}
* node_disk_flush_requests_total {"device"=>...}
* node_disk_io_now {"device"=>...}
* node_disk_io_time_seconds_total {"device"=>...}
* node_disk_io_time_weighted_seconds_total {"device"=>...}
* node_disk_read_bytes_total {"device"=>...}
* node_disk_reads_completed_total {"device"=>...}
* node_disk_reads_merged_total {"device"=>...}
* node_disk_reads_time_seconds_total {"device"=>...}
* node_disk_write_time_seconds_total {"device"=>...}
* node_disk_writes_completed_total {"device"=>...}
* node_disk_writes_merged_total {"device"=>...}
* node_disk_written_bytes_total {"device"=>...}

## Metric and its data sources

Diskstats collector access the following data sources.

* /proc/diskstats
