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
require "etc"
require "fluent/plugin/input"
require "fluent/plugin/node_exporter_collector"

module Fluent
  module Plugin
    module NodeExporter
      class CpuMetricsCollector < MetricsCollector
        def initialize(config={})
          super(config)

          # It varies whether /sys/devices/system/cpu/cpuN/thermal_throttle exists or not
          @thermal_throttle_path = File.join(@sysfs_path, "devices/system/cpu/cpu0/thermal_throttle")

          @core_throttles_total = if File.exist?(File.join(@thermal_throttle_path, "core_throttle_count"))
                                    CMetrics::Counter.new
                                  else
                                    nil
                                  end
          @core_throttles_total.create("node", "cpu", "core_throttles_total",
                                       "Number of times this CPU core has been throttled.",
                                       ["core", "package"]) if @core_throttles_total

          @package_throttles_total = if File.exist?(File.join(@thermal_throttle_path, "package_throttle_count"))
                                       CMetrics::Counter.new
                                     else
                                       nil
                                     end
          @package_throttles_total.create("node", "cpu", "package_throttles_total",
                                          "Number of times this CPU package has been throttled.",
                                          ["package"]) if @package_throttles_total

          @seconds_total = CMetrics::Counter.new
          @seconds_total.create("node", "cpu", "seconds_total",
                                "Seconds the CPUs spent in each mode.",
                                ["cpu", "mode"])

          @guest_seconds_total = CMetrics::Counter.new
          @guest_seconds_total.create("node", "cpu", "guest_seconds_total",
                                      "Seconds the CPUs spent in guests (VMs) for each mode.",
                                      ["cpu", "mode"])

          @core_throttles_set = {}
          @package_throttles_set = {}
        end

        def run
          cpu_thermal_update
          cpu_stat_update
        end

        def cpu_thermal_update
          scan_sysfs_path("devices/system/cpu/cpu[0-9]*").each do |path|
            next unless @core_throttles_total
            next unless @package_throttles_total
            
            core_id_path = File.join(path, "topology", "core_id")
            physical_package_path = File.join(path, "topology", "physical_package_id")
            core_id = File.read(core_id_path).strip
            physical_package_id = File.read(physical_package_path).strip
            next if @core_throttles_set[{physical_package_id: physical_package_id, core_id: core_id}]
            @core_throttles_set[{physical_package_id: physical_package_id, core_id: core_id}] = true

            core_throttle_count = File.read(File.join(path, "thermal_throttle", "core_throttle_count")).to_i
            @core_throttles_total.set(core_throttle_count, [core_id, physical_package_id])

            next if @package_throttles_set[physical_package_id]
            @package_throttles_set[physical_package_id] = true

            package_throttle_count = File.read(File.join(path, "thermal_throttle", "package_throttle_count")).to_i
            @package_throttles_total.set(package_throttle_count, [physical_package_id])

          end
        end

        STAT_CPU_PATTERN = /^cpu(?<cpuid>\d+)\s(?<user>\d+)\s(?<nice>\d+)\s(?<system>\d+)\s(?<idle>\d+)\s(?<iowait>\d+)\s(?<irq>\d+)\s(?<softirq>\d+)\s(?<steal>\d+)\s(?<guest>\d+)\s(?<guest_nice>\d+)/

        def cpu_stat_update
          stat_path = File.join(@procfs_path, "stat")
          File.readlines(stat_path).each do |line|
            if line.start_with?("cpu ")
              # Ignore CPU total
              next
            elsif line.start_with?("cpu")
              user_hz = Etc.sysconf(Etc::SC_CLK_TCK)
              line.match(STAT_CPU_PATTERN) do |m|
                @seconds_total.set(m[:idle].to_f / user_hz, [m[:cpuid], "idle"])
                @seconds_total.set(m[:iowait].to_f / user_hz, [m[:cpuid], "iowait"])
                @seconds_total.set(m[:irq].to_f / user_hz, [m[:cpuid], "irq"])
                @seconds_total.set(m[:nice].to_f / user_hz, [m[:cpuid], "nice"])
                @seconds_total.set(m[:softirq].to_f / user_hz, [m[:cpuid], "softirq"])
                @seconds_total.set(m[:steal].to_f / user_hz, [m[:cpuid], "steal"])
                @seconds_total.set(m[:system].to_f / user_hz, [m[:cpuid], "system"])
                @seconds_total.set(m[:user].to_f / user_hz, [m[:cpuid], "user"])

                @guest_seconds_total.set(m[:guest].to_f / user_hz, [m[:cpuid], "user"])
                @guest_seconds_total.set(m[:guest_nice].to_f / user_hz, [m[:cpuid], "nice"])
              end
            end
          end
        end

        def cmetrics
          {
            core_throttles_total: @core_throttles_total,
            package_throttles_total: @package_throttles_total,
            seconds_total: @seconds_total,
            guest_seconds_total: @guest_seconds_total
          }.compact
        end
      end
    end
  end
end
