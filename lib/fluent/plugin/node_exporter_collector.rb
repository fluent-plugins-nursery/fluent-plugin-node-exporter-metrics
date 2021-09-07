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

module Fluent
  module Plugin
    module NodeExporter
      class MetricsCollector
        def initialize(config={})
          @scrape_interval = config[:scrape_interval] || 5
          @procfs_path = config[:procfs_path] || "/proc"
          @sysfs_path = config[:sysfs_path] || "/sys"
        end

        def scan_sysfs_path(pattern)
          Dir.glob(File.join(@sysfs_path, pattern)).sort_by do |a, b|
            if a and b
              File.basename(a).delete("a-z").to_i <=> File.basename(b).delete("a-z").to_i
            else
              0
            end
          end
        end

        def cmetrics
          raise NotImplementedError
        end
      end
    end
  end
end
