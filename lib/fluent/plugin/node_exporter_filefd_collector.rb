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
require "resolv"
require "fluent/plugin/input"
require "fluent/plugin/node_exporter_collector"

module Fluent
  module Plugin
    module NodeExporter
      class FilefdMetricsCollector < MetricsCollector
        def initialize(config={})
          super(config)

          @allocated = CMetrics::Gauge.new
          @allocated.create("node", "filefd", "allocated", "File descriptor statistics: allocated.")

          @maximum = CMetrics::Gauge.new
          @maximum.create("node", "filefd", "maximum", "File descriptor statistics: maximum.")
        end

        def run
          filefd_update
        end

        def filefd_update
          # Etc.uname returns at least sysname,release,version,machine,nodename
          # but it is not guaranteed to return domainname.
          file_nr_path = File.join(@procfs_path, "/sys/fs/file-nr")
          entry = File.read(file_nr_path).split
          unless entry.size == 3
            $log.warn("invalid number of field <#{file_nr_path}>: #{entry.size}")
            return
          end
          @allocated.set(entry.first.to_f)
          @maximum.set(entry.last.to_f)
        end

        def cmetrics
          {
            filefd_allocated: @allocated,
            filefd_maximum: @maximum
          }
        end
      end
    end
  end
end
