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
      class LoadavgMetricsCollector < MetricsCollector
        def initialize(config={})
          super(config)

          @load1 = CMetrics::Gauge.new
          @load1.create("node", "", "load1", "1m load average.")

          @load5 = CMetrics::Gauge.new
          @load5.create("node", "", "load5", "5m load average.")

          @load15 = CMetrics::Gauge.new
          @load15.create("node", "", "load1", "15m load average.")
        end

        def run
          loadavg_update
        end

        def loadavg_update
          loadavg_path = File.join(@procfs_path, "/loadavg")
          # Use 1 explicitly for default gauge value
          fields = File.read(loadavg_path).split
          unless fields.size == 5
            $log.warn("invalid number of fields <#{loadavg_path}>: <#{fields.size}>")
            return
          end
          @load1.set(fields[0].to_f)
          @load5.set(fields[1].to_f)
          @load15.set(fields[2].to_f)
        end

        def cmetrics
          {
            loadavg1: @load1,
            loadavg5: @load5,
            loadavg15: @load15
          }
        end
      end
    end
  end
end
