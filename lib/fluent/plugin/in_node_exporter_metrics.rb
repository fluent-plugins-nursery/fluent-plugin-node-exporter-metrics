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
require "fluent/env"
require "fluent/capability"
require "fluent/plugin/input"
require "fluent/plugin/node_exporter/cpu_collector"
require "fluent/plugin/node_exporter/cpufreq_collector"
require "fluent/plugin/node_exporter/diskstats_collector"
require "fluent/plugin/node_exporter/filefd_collector"
require "fluent/plugin/node_exporter/loadavg_collector"
require "fluent/plugin/node_exporter/meminfo_collector"
require "fluent/plugin/node_exporter/netdev_collector"
require "fluent/plugin/node_exporter/stat_collector"
require "fluent/plugin/node_exporter/time_collector"
require "fluent/plugin/node_exporter/uname_collector"
require "fluent/plugin/node_exporter/vmstat_collector"

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
      desc "Tag string"
      config_param :tag, :string, default: nil
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

      def configure(conf)
        super
        @collectors = []
        config = {
          procfs_path: @procfs_path,
          sysfs_path: @sysfs_path
        }
        @collectors << NodeExporter::CpuMetricsCollector.new(config) if @cpu
        @collectors << NodeExporter::DiskstatsMetricsCollector.new(config) if @diskstats
        @collectors << NodeExporter::FilefdMetricsCollector.new(config) if @filefd
        @collectors << NodeExporter::LoadavgMetricsCollector.new(config) if @loadavg
        @collectors << NodeExporter::MeminfoMetricsCollector.new(config) if @loadavg
        @collectors << NodeExporter::NetdevMetricsCollector.new(config) if @netdev
        @collectors << NodeExporter::StatMetricsCollector.new(config) if @stat
        @collectors << NodeExporter::TimeMetricsCollector.new(config) if @time
        @collectors << NodeExporter::UnameMetricsCollector.new(config) if @uname
        @collectors << NodeExporter::VmstatMetricsCollector.new(config) if @vmstat

        if @collectors.empty?
          raise ConfigError, "all collectors are disabled. Enable at least one collector."
        end

        if Fluent.linux?
          if @cpufreq
            @capability = Fluent::Capability.new(:current_process)
            unless @capability.have_capability?(:effective, :dac_read_search)
              raise ConfigError, "Linux capability CAP_DAC_READ_SEARCH must be enabled"
            end
            @collectors << NodeExporter::CpufreqMetricsCollector.new(config) if @cpufreq
          end
        elsif Fluent.windows?
          raise ConfigError, "node_exporter_metrics is not supported"
        end
      end

      def start
        super
        timer_execute(:execute_node_exporter_metrics, @scrape_interval, &method(:refresh_watchers))
      end

      def refresh_watchers
        begin
          @serde = CMetrics::Serde.new
          @collectors.each do |collector|
            begin
              collector.run
              collector.cmetrics.each do |key, cmetric|
                @serde.concat(cmetric) if cmetric
              end
            rescue => e
              $log.error(e.message)
            end
          end
          record = {
            "cmetrics" => @serde.to_msgpack
          }
          es = OneEventStream.new(Fluent::EventTime.now, record)
          router.emit_stream(@tag, es)
        end
      rescue => e
        $log.error(e.message)
      end

      def shutdown
      end
    end
  end
end
