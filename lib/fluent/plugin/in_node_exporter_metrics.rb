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
    class NodeExporterMetricsInput < Fluent::Plugin::Input
      Fluent::Plugin.register_input("node_exporter_metrics", self)

      helpers :timer

      desc "Interval to scrape metrics from node"
      config_param :scrape_interval, :time, default: 5
      desc "Path to mount point to collect process information and metrics"
      config_param :procfs_path, :string, default: "/proc"
      desc "Path to file-system to collect system metrics"
      config_param :sysfs_path, :string, default: "/sys"

      desc "Enable cpu collector"
      config_param :cpu, :bool, default: true
      desc "Enable cpu collector"
      config_param :cpufreq, :bool, default: true
      desc "Enable diskstats collector"
      config_param :diskstats, :bool, default: true
      desc "Enable filefd collector"
      config_param :filefd, :bool, default: true
      desc "Enable loadavg collector"
      config_param :loadavg, :bool, default: true
      desc "Enable meminfo collector"
      config_param :meminfo, :bool, default: true
      desc "Enable netdev collector"
      config_param :netdev, :bool, default: true
      desc "Enable stat collector"
      config_param :stat, :bool, default: true
      desc "Enable time collector"
      config_param :time, :bool, default: true
      desc "Enable uname collector"
      config_param :uname, :bool, default: true
      desc "Enable vmstat collector"
      config_param :vmstat, :bool, default: true

    end
  end
end
