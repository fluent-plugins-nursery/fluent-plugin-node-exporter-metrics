# Netdev Collector

## Metric and label naming

* node_network_receive_bytes_total {"device"=>...}
* node_network_receive_compressed_total {"device"=>...}
* node_network_receive_drop_total {"device"=>...}
* node_network_receive_errs_total {"device"=>...}
* node_network_receive_fifo_total {"device"=>...}
* node_network_receive_frame_total {"device"=>...}
* node_network_receive_multicast_total {"device"=>...}
* node_network_receive_packets_total {"device"=>...}
* node_network_transmit_bytes_total {"device"=>...}
* node_network_transmit_carrier_total {"device"=>...}
* node_network_transmit_colls_total {"device"=>...}
* node_network_transmit_compressed_total {"device"=>...}
* node_network_transmit_drop_total {"device"=>...}
* node_network_transmit_errs_total {"device"=>...}
* node_network_transmit_fifo_total {"device"=>...}
* node_network_transmit_packets_total {"device"=>...}

## Metric and its data sources

Netdev collector access the following data sources.

* /proc/net/dev
