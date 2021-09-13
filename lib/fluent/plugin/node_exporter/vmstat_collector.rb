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
      class VmstatMetricsCollector < MetricsCollector

        VMSTAT_ENTRIES_REGEX = /^(oom_kill|pgpg|pswp|pg.*fault).*/

        def initialize(config={})
          super(config)

          @metrics = {}
        end

        def run
          vmstat_update
        end

        def vmstat_update
          vmstat_path = File.join(@procfs_path, "vmstat")
          File.readlines(vmstat_path).each do |line|
            if VMSTAT_ENTRIES_REGEX.match?(line)
              key, value = line.split(' ', 2)
              @untyped = CMetrics::Untyped.new
              @untyped.create("node", "vmstat", key, "#{vmstat_path} information field #{key}.")
              @untyped.set(value.to_f)
              @metrics[key] = @untyped
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
