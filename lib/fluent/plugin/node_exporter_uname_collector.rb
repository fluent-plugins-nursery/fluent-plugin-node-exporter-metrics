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
      class UnameMetricsCollector < MetricsCollector
        def initialize(config={})
          super(config)

          @gauge = CMetrics::Gauge.new
          @gauge.create("node", "uname", "info",
                        "Labeled system information as provided by the uname system call.",
                        ["sysname", "release", "version", "machine", "nodename", "domainname"])
        end

        def run
          uname_update
        end

        def uname_update
          # Etc.uname returns at least sysname,release,version,machine,nodename
          # but it is not guaranteed to return domainname.
          domainname = if Etc.uname.has_key?(:domainname)
                         Etc.uname[:domainname]
                       else
                         "(none)"
                       end
          # Use 1 explicitly for default gauge value
          @gauge.set(1, [
                       Etc.uname[:sysname],
                       Etc.uname[:release],
                       Etc.uname[:version],
                       Etc.uname[:machine],
                       Etc.uname[:nodename],
                       domainname])
        end

        def cmetrics
          {
            info: @gauge
          }
        end
      end
    end
  end
end
