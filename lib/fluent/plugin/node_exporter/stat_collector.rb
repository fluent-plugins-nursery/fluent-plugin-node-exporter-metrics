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
      class StatMetricsCollector < MetricsCollector
        def initialize(config={})
          super(config)

          @intr_total = CMetrics::Counter.new
          @intr_total.create("node", "", "intr_total", "Total number of interrupts serviced.")

          @context_switches_total = CMetrics::Counter.new
          @context_switches_total.create("node", "", "context_switches_total", "Total number of context switches.")

          @forks_total = CMetrics::Counter.new
          @forks_total.create("node", "", "forks_total", "Total number of forks.")

          @boot_time_seconds = CMetrics::Gauge.new
          @boot_time_seconds.create("node", "", "boot_time_seconds", "Node boot time, in unixtime.")

          @procs_running = CMetrics::Gauge.new
          @procs_running.create("node", "", "procs_running", "Number of processes in runnable state.")

          @procs_blocked = CMetrics::Gauge.new
          @procs_blocked.create("node", "", "procs_blocked", "Number of processes blocked waiting for I/O to complete.")
        end

        def run
          loadavg_update
        end

        def loadavg_update
          stat_path = File.join(@procfs_path, "stat")
          File.readlines(stat_path).each do |line|
            entry, value, _ = line.split
            case entry
            when "intr"
              @intr_total.set(value.to_f)
            when "ctxt"
              @context_switches_total.set(value.to_f)
            when "btime"
              @boot_time_seconds.set(value.to_f)
            when "processes"
              @forks_total.set(value.to_f)
            when "procs_running"
              @procs_running.set(value.to_f)
            when "procs_blocked"
              @procs_blocked.set(value.to_f)
            end
          end
        end

        def cmetrics
          {
            intr_total: @intr_total,
            context_switches_total: @context_switches_total,
            forks_total: @forks_total,
            boot_time_seconds: @boot_time_seconds,
            procs_running: @procs_running,
            procs_blocked: @procs_blocked
          }
        end
      end
    end
  end
end
