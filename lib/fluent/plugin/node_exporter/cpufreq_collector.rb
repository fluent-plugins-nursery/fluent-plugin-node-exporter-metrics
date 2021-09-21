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
require "fluent/plugin/node_exporter/collector"

module Fluent
  module Plugin
    module NodeExporter
      class CpufreqMetricsCollector < MetricsCollector
        def initialize(config={})
          super(config)

          if Fluent.linux?
            @frequency_hertz = CMetrics::Gauge.new
            @frequency_hertz.create("node", "cpu", "frequency_hertz",
                                    "Current cpu thread frequency in hertz.", ["cpu"])

            @frequency_max_hertz = CMetrics::Gauge.new
            @frequency_max_hertz.create("node", "cpu", "frequency_max_hertz",
                                       "Maximum cpu thread frequency in hertz.", ["cpu"])

            @frequency_min_hertz = CMetrics::Gauge.new
            @frequency_min_hertz.create("node", "cpu", "frequency_min_hertz",
                                       "Minimum cpu thread frequency in hertz.", ["cpu"])

            @scaling_frequency_hertz = CMetrics::Gauge.new
            @scaling_frequency_hertz.create("node", "cpu", "scaling_frequency_hertz",
                                            "Current scaled CPU thread frequency in hertz.", ["cpu"])

            @scaling_frequency_max_hertz = CMetrics::Gauge.new
            @scaling_frequency_max_hertz.create("node", "cpu", "scaling_frequency_max_hertz",
                                       "Maximum scaled CPU thread frequency in hertz.", ["cpu"])

            @scaling_frequency_min_hertz = CMetrics::Gauge.new
            @scaling_frequency_min_hertz.create("node", "cpu", "scaling_frequency_min_hertz",
                                       "Minimum scaled CPU thread frequency in hertz.", ["cpu"])
          end
        end

        def run
          cpufreq_update
        end

        def cpuinfo_cur_freq_exist?
          path = File.join(@sysfs_path, "devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq")
          File.exist?(path)
        end

        def cpufreq_update
          scan_sysfs_path("devices/system/cpu/cpu[0-9]*").each do |path|
            next unless Dir.exist?(File.join(path, "cpufreq"))

            cpuinfo_cur_freq_path = File.join(path, "cpufreq", "cpuinfo_cur_freq")
            cpuinfo_max_freq_path = File.join(path, "cpufreq", "cpuinfo_max_freq")
            cpuinfo_min_freq_path = File.join(path, "cpufreq", "cpuinfo_min_freq")
            scaling_cur_freq_path = File.join(path, "cpufreq", "scaling_cur_freq")
            scaling_max_freq_path = File.join(path, "cpufreq", "scaling_max_freq")
            scaling_min_freq_path = File.join(path, "cpufreq", "scaling_min_freq")
            cpu_id = File.basename(path).sub(/cpu(\d+)/, "\\1")
            @frequency_hertz.set(File.read(cpuinfo_cur_freq_path).to_f, [cpu_id]) if File.exist?(cpuinfo_cur_freq_path)
            @frequency_max_hertz.set(File.read(cpuinfo_max_freq_path).to_f, [cpu_id]) if File.exist?(cpuinfo_max_freq_path)
            @frequency_min_hertz.set(File.read(cpuinfo_min_freq_path).to_f, [cpu_id]) if File.exist?(cpuinfo_min_freq_path)
            @scaling_frequency_hertz.set(File.read(scaling_cur_freq_path).to_f, [cpu_id]) if File.exist?(scaling_cur_freq_path)
            @scaling_frequency_max_hertz.set(File.read(scaling_max_freq_path).to_f, [cpu_id]) if File.exist?(scaling_max_freq_path)
            @scaling_frequency_min_hertz.set(File.read(scaling_min_freq_path).to_f, [cpu_id]) if File.exist?(scaling_min_freq_path)
          end
        end

        def cmetrics
          {
            frequency_hertz: @frequency_hertz,
            frequency_max_hertz: @frequency_max_hertz,
            frequency_min_hertz: @frequency_min_hertz,
            scaling_frequency_hertz: @scaling_frequency_hertz,
            scaling_frequency_max_hertz: @scaling_frequency_max_hertz,
            scaling_frequency_min_hertz: @scaling_frequency_min_hertz
          }
        end
      end
    end
  end
end
