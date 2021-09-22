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
      class MeminfoMetricsCollector < MetricsCollector

        def initialize(config={})
          super(config)

          @metrics = {}
          meminfo_path = File.join(@procfs_path, "meminfo")
          File.readlines(meminfo_path).each do |line|
            metric_name, name, value = parse_meminfo_line(line)
            @gauge = CMetrics::Gauge.new
            @gauge.create("node", "memory", name, "#{name}.")
            @metrics[metric_name.intern] = @gauge
          end
        end

        def run
          meminfo_update
        end

        def parse_meminfo_line(line)
          name, value, unit = line.split
          name.delete!(":")
          if name.end_with?("(anon)") or name.end_with?("(file)")
            name.sub!(/\((anon)\)|\((file)\)/, "_\\1\\2")
          end
          if unit
            name << "_bytes"
            value = value.to_f * 1024
          end
          ["node_memory_#{name}", name, value]
        end

        def meminfo_update
          meminfo_path = File.join(@procfs_path, "meminfo")
          File.readlines(meminfo_path).each do |line|
            metric_name, name, value = parse_meminfo_line(line)
            @metrics[metric_name.intern].set(value.to_f)
          end
        end

        def cmetrics
          @metrics
        end
      end
    end
  end
end
