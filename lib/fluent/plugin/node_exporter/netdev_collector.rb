#
# Copyright 2021- Kentaro Hayashi
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "cmetrics"
require "fluent/plugin/input"
require "fluent/plugin/node_exporter/collector"

module Fluent
  module Plugin
    module NodeExporter
      class NetdevMetricsCollector < MetricsCollector

        def initialize(config={})
          super(config)

          @metrics = {}
        end

        def run
          netdev_update
        end

        RECEIVE_FIELDS = %w(bytes packets errs drop fifo frame compressed multicast)
        TRANSMIT_FIELDS = %w(bytes packets errs drop fifo colls carrier compressed)

        def target_devices
          devices = []
          netdev_path = File.join(@procfs_path, "net/dev")
          File.readlines(netdev_path).each_with_index do |line, index|
            next if index < 2
            interface, _ = line.split
            interface.delete!(":")
            devices << interface
          end
          devices
        end

        def netdev_update
          netdev_path = File.join(@procfs_path, "net/dev")
          File.readlines(netdev_path).each_with_index do |line, index|
            # net/dev must be 3 columns
            if index == 0 and line.split("|").size != 3
              break
            end
            # first 2 line are header (Inter-face/Receive/Transmit)
            next if index < 2

            interface, *values = line.split
            interface.delete!(":")

            RECEIVE_FIELDS.each_with_index do |field, index|
              metric_name = "receive_#{field}_total"
              @counter = CMetrics::Counter.new
              @counter.create("node", "network", metric_name, "Network device statistic #{interface}.", ["device"])
              @counter.set(values[index].to_f, [interface])
              @metrics[metric_name.intern] = @counter
            end
            TRANSMIT_FIELDS.each_with_index do |field, index|
              metric_name = "transmit_#{field}_total"
              @counter = CMetrics::Counter.new
              @counter.create("node", "network", metric_name, "Network device statistic #{interface}.", ["device"])
              @counter.set(values[index + RECEIVE_FIELDS.size].to_f, [interface])
              @metrics[metric_name.intern] = @counter
            end
          end
        end

        def cmetrics
          @metrics
        end
      end
    end
  end
end
