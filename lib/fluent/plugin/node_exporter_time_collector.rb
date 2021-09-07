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
      class TimeMetricsCollector < MetricsCollector
        def initialize(config={})
          super(config)

          @gauge = CMetrics::Gauge.new
          @gauge.create("node", "", "time_seconds",
                        "System time in seconds since epoch (1970).")
        end

        def run
          time_update
        end

        def time_update
          current_time = Fluent::EventTime.now
          value = current_time.to_i / 1e9
          @gauge.set(value)
        end

        def cmetrics
          {
            time_seconds: @gauge
          }
        end
      end
    end
  end
end
