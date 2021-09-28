#
# Copyright (C) 2021- Kentaro Hayashi
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
      class DiskstatsMetricsCollector < MetricsCollector

        IGNORED_DEVICES = /^(ram|loop|fd|(h|s|v|xv)d[a-z]|nvme\d+n\d+p)\d+$/
        # https://www.kernel.org/doc/Documentation/ABI/testing/procfs-diskstats
        # major number ... time spent flushing
        DISKSTATS_KNOWN_FIELDS = 20
        # assume sector size = 512
        SECTOR_SIZE = 512

        METRIC_NAMES = %w(
                reads_completed_total
                reads_merged_total
                read_bytes_total
                read_time_seconds_total
                writes_completed_total
                writes_merged_total
                written_bytes_total
                write_time_seconds_total
                io_now
                io_time_seconds_total
                io_time_weighted_seconds_total
                discards_completed_total
                discards_merged_total
                discarded_sectors_total
                discard_time_seconds_total
                flush_requests_total
                flush_requests_time_seconds_total
        )

        DISCARD_METRIC_NAMES = %w(
               discards_completed_total
               discards_merged_total
               discarded_sectors_total
               discard_time_seconds_total
        )

        FLUSH_METRIC_NAMES = %w(
               flush_requests_total
               flush_requests_time_seconds_total
        )

        def initialize(config={})
          super(config)

          @reads_completed_total = CMetrics::Counter.new
          @reads_completed_total.create("node", "disk", "reads_completed_total",
                                        "The total number of reads completed successfully.",
                                        ["device"])

          @reads_merged_total = CMetrics::Counter.new
          @reads_merged_total.create("node", "disk", "reads_merged_total",
                                     "The total number of reads merged.",
                                     ["device"])

          @read_bytes_total = CMetrics::Counter.new
          @read_bytes_total.create("node", "disk", "read_bytes_total",
                                   "The total number of bytes read successfully.",
                                   ["device"])

          @read_time_seconds_total = CMetrics::Counter.new
          @read_time_seconds_total.create("node", "disk", "reads_time_seconds_total",
                                          "The total number of seconds spent by all reads.",
                                          ["device"])

          @writes_completed_total = CMetrics::Counter.new
          @writes_completed_total.create("node", "disk", "writes_completed_total",
                                      "The total number of writes completed successfully.",
                                      ["device"])

          @writes_merged_total = CMetrics::Counter.new
          @writes_merged_total.create("node", "disk", "writes_merged_total",
                                      "The number of writes merged.",
                                      ["device"])

          @written_bytes_total = CMetrics::Counter.new
          @written_bytes_total.create("node", "disk", "written_bytes_total",
                                      "The total number of bytes written successfully.",
                                      ["device"])

          @write_time_seconds_total = CMetrics::Counter.new
          @write_time_seconds_total.create("node", "disk", "write_time_seconds_total",
                                           "This is the total number of seconds spent by all writes.",
                                           ["device"])

          @io_now = CMetrics::Gauge.new
          @io_now.create("node", "disk", "io_now",
                         "The number of I/Os currently in progress.",
                         ["device"])

          @io_time_seconds_total = CMetrics::Counter.new
          @io_time_seconds_total.create("node", "disk", "io_time_seconds_total",
                                        "Total seconds spent doing I/Os.",
                                        ["device"])

          @io_time_weighted_seconds_total = CMetrics::Counter.new
          @io_time_weighted_seconds_total.create("node", "disk", "io_time_weighted_seconds_total",
                                                 "The number of I/Os currently in progress.",
                                                 ["device"])

          if kernel_version_over4_18?
            # Kernel >= 4.18
            @discards_completed_total = CMetrics::Counter.new
            @discards_completed_total.create("node", "disk", "discards_completed_total",
                                             "The total number of discards completed successfully.",
                                             ["device"])

            @discards_merged_total = CMetrics::Counter.new
            @discards_merged_total.create("node", "disk", "discards_merged_total",
                                          "The total number of discards merged.", ["device"])

            @discarded_sectors_total = CMetrics::Counter.new
            @discarded_sectors_total.create("node", "disk", "discards_sectors_total",
                                            "The total number of sectors discarded successfully.",
                                            ["device"])

            @discard_time_seconds_total = CMetrics::Counter.new
            @discard_time_seconds_total.create("node", "disk", "discard_time_seconds_total",
                                               "The total number of seconds spent by all discards.",
                                               ["device"])
          end

          if kernel_version_over5_5?
            @flush_requests_total = CMetrics::Counter.new
            @flush_requests_total.create("node", "disk", "flush_requests_total",
                                         "The total number of flush requests completed successfully",
                                         ["device"])

            @flush_requests_time_seconds_total = CMetrics::Counter.new
            @flush_requests_time_seconds_total.create("node", "disk", "flush_requests_time_seconds_total",
                                                      "This is the total number of seconds spent by all flush requests.",
                                                      ["device"])
          end
        end

        def kernel_version_over4_18?
          Gem::Version.new(Etc.uname[:release].split('-', 2).first) >= Gem::Version.new("4.18")
        end

        def kernel_version_over5_5?
          Gem::Version.new(Etc.uname[:release].split('-', 2).first) >= Gem::Version.new("5.5.0")
        end

        def target_devices
          devices = []
          diskstats_path = File.join(@procfs_path, "diskstats")
          File.readlines(diskstats_path).each do |line|
            _, _, device, _ = line.split(' ', DISKSTATS_KNOWN_FIELDS)
            unless IGNORED_DEVICES.match?(device)
              devices << device
            end
          end
          devices
        end

        def run
          diskstats_update
        end

        def diskstats_update
          diskstats_path = File.join(@procfs_path, "diskstats")
          File.readlines(diskstats_path).each do |line|
            _, _, device,
            reads_completed_value, reads_merged_value, read_bytes_value, read_time_seconds_value,
            writes_completed_value, writes_merged_value, written_bytes_value, write_time_seconds_value,
            io_now_value, io_time_seconds_value, io_time_weighted_seconds_value,
            discards_completed_value, discards_merged_value, discarded_sectors_value, discard_time_seconds_value,
            flush_requests_value, flush_requests_time_seconds_value = line.split(' ', DISKSTATS_KNOWN_FIELDS)
            unless IGNORED_DEVICES.match?(device)
              METRIC_NAMES.each do |field|
                case field
                when "reads_completed_total"
                  @reads_completed_total.set(reads_completed_value.to_f, [device])
                when "reads_merged_total"
                  @reads_merged_total.set(reads_merged_value.to_f, [device])
                when "read_bytes_total"
                  @read_bytes_total.set(read_bytes_value.to_f * SECTOR_SIZE, [device])
                when "read_time_seconds_total"
                  @read_time_seconds_total.set(read_time_seconds_value.to_f * 0.001, [device])
                when "writes_completed_total"
                  @writes_completed_total.set(writes_completed_value.to_f, [device])
                when "writes_merged_total"
                  @writes_merged_total.set(writes_merged_value.to_f, [device])
                when "written_bytes_total"
                  @written_bytes_total.set(written_bytes_value.to_f * SECTOR_SIZE, [device])
                when "write_time_seconds_total"
                  @write_time_seconds_total.set(write_time_seconds_value.to_f * 0.001, [device])
                when "io_now"
                  @io_now.set(io_now_value.to_f, [device])
                when "io_time_seconds_total"
                  @io_time_seconds_total.set(io_time_seconds_value.to_f * 0.001, [device])
                when "io_time_weighted_seconds_total"
                  @io_time_weighted_seconds_total.set(io_time_weighted_seconds_value.to_f * 0.001, [device])
                when "discards_completed_total"
                  if kernel_version_over4_18?
                    @discards_completed_total.set(discards_completed_value.to_f, [device])
                  end
                when "discards_merged_total"
                  if kernel_version_over4_18?
                    @discards_merged_total.set(discards_merged_value.to_f, [device])
                  end
                when "discarded_sectors_total"
                  if kernel_version_over4_18?
                    @discarded_sectors_total.set(discarded_sectors_value.to_f, [device])
                  end
                when "discard_time_seconds_total"
                  if kernel_version_over4_18?
                    @discard_time_seconds_total.set(discard_time_seconds_value.to_f * 0.001, [device])
                  end
                when "flush_requests_total"
                  if kernel_version_over5_5?
                    @flush_requests_total.set(flush_requests_value.to_f, [device])
                  end
                when "flush_requests_time_seconds_total"
                  if kernel_version_over5_5?
                    @flush_requests_time_seconds_total.set(flush_requests_time_seconds_value.to_f * 0.001, [device])
                  end
                end
              end
            end
          end
        end

        def cmetrics
          metrics = {
                reads_completed_total: @reads_completed_total,
                reads_merged_total: @reads_merged_total,
                read_bytes_total: @read_bytes_total,
                read_time_seconds_total: @read_time_seconds_total,
                writes_completed_total: @writes_completed_total,
                writes_merged_total: @writes_merged_total,
                written_bytes_total: @written_bytes_total,
                write_time_seconds_total: @write_time_seconds_total,
                io_now: @io_now,
                io_time_seconds_total: @io_time_seconds_total,
                io_time_weighted_seconds_total: @io_time_weighted_seconds_total
          }
          if kernel_version_over4_18?
            metrics.merge!({
                              discards_completed_total: @discards_completed_total,
                              discards_merged_total: @discards_merged_total,
                              discarded_sectors_total: @discarded_sectors_total,
                              discard_time_seconds_total: @discard_time_seconds_total
                            })
          end
          if kernel_version_over5_5?
            metrics.merge!({
                              flush_requests_total: @flush_requests_total,
                              flush_requests_time_seconds_total: @flush_requests_time_seconds_total
                            })
          end
          metrics
        end
      end
    end
  end
end
