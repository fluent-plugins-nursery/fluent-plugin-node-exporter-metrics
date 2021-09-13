require "helper"
require "fluent/plugin/in_node_exporter_metrics"
require "fluent/plugin/node_exporter/diskstats_collector"

class DiskstatsColectorTest < Test::Unit::TestCase

  DUMMY_DISKSTATS = <<EOS
 1000       0 nvme0n1 4000 5000 6000 7000 8000 9000 10000 11000 12000 13000 14000 15000 16000 17000 18000 19000 20000
EOS

  def parse(input)
    stub(File).readlines { input.split("\n") }
    collector = Fluent::Plugin::NodeExporter::DiskstatsMetricsCollector.new
    collector.run
    yield collector
  end

  sub_test_case "diskstats" do

    def test_ignore_devices
      omit "/proc/diskstats is only available on *nix" unless Fluent.linux?

      proc_diskstats = <<EOS
 1000       0 ram0 4000 5000 6000 7000 8000 9000 10000 11000 12000 13000 14000 15000 16000 17000 18000 19000 20000 21000
 1000       0 loop1 4000 5000 6000 7000 8000 9000 10000 11000 12000 13000 14000 15000 16000 17000 18000 19000 20000 21000
 1000       0 fd2 4000 5000 6000 7000 8000 9000 10000 11000 12000 13000 14000 15000 16000 17000 18000 19000 20000 21000
 1000       0 hda3 4000 5000 6000 7000 8000 9000 10000 11000 12000 13000 14000 15000 16000 17000 18000 19000 20000 21000
 1000       0 sda4 4000 5000 6000 7000 8000 9000 10000 11000 12000 13000 14000 15000 16000 17000 18000 19000 20000 21000
 1000       0 vda5 4000 5000 6000 7000 8000 9000 10000 11000 12000 13000 14000 15000 16000 17000 18000 19000 20000 21000
 1000       0 xvda6 4000 5000 6000 7000 8000 9000 10000 11000 12000 13000 14000 15000 16000 17000 18000 19000 20000 21000
 1000       0 nvme7p1 4000 5000 6000 7000 8000 9000 10000 11000 12000 13000 14000 15000 16000 17000 18000 19000 20000 21000
EOS
      stub(Etc).uname { {release: "2.4.20-1-amd64"} }
      parse(DUMMY_DISKSTATS) do |collector|
        # all listed devices are ignored
        assert_true(%w(ram0 loop1 fd2 hda3 sda4 vda5 xvda6 nmve7p1).all? { |v|
          collector.cmetrics.keys.all? do |key|
            collector.cmetrics[key].val([v]) == nil
          end
        })
      end
    end


    def test_minimum_metrics
      omit "/proc/diskstats is only available on *nix" unless Fluent.linux?

      # specify lower version to exclude discard and flush metrics explicitly
      stub(Etc).uname { {release: "2.4.20-1-amd64"} }
      parse(DUMMY_DISKSTATS) do |collector|
        expected = (Fluent::Plugin::NodeExporter::DiskstatsMetricsCollector::METRIC_NAMES -
                    Fluent::Plugin::NodeExporter::DiskstatsMetricsCollector::DISCARD_METRIC_NAMES -
                    Fluent::Plugin::NodeExporter::DiskstatsMetricsCollector::FLUSH_METRIC_NAMES).collect { |v| v.intern }
        assert_equal(expected, collector.cmetrics.keys)
      end
    end

    def test_minimum_values
      omit "/proc/diskstats is only available on *nix" unless Fluent.linux?

      # specify lower version to exclude discard and flush metrics explicitly
      stub(Etc).uname { {release: "2.4.20-1-amd64"} }
      parse(DUMMY_DISKSTATS) do |collector|
        assert_equal([4000.0, 5000.0, 6000 * 512, 7.0,
                      8000.0, 9000.0, 10000 * 512, 11.0,
                      12000.0, 13.0, 14.0],
                     [collector.cmetrics[:reads_completed_total].val(["nvme0n1"]),
                      collector.cmetrics[:reads_merged_total].val(["nvme0n1"]),
                      collector.cmetrics[:read_bytes_total].val(["nvme0n1"]),
                      collector.cmetrics[:read_time_seconds_total].val(["nvme0n1"]),
                      collector.cmetrics[:writes_completed_total].val(["nvme0n1"]),
                      collector.cmetrics[:writes_merged_total].val(["nvme0n1"]),
                      collector.cmetrics[:written_bytes_total].val(["nvme0n1"]),
                      collector.cmetrics[:write_time_seconds_total].val(["nvme0n1"]),
                      collector.cmetrics[:io_now].val(["nvme0n1"]),
                      collector.cmetrics[:io_time_seconds_total].val(["nvme0n1"]),
                      collector.cmetrics[:io_time_weighted_seconds_total].val(["nvme0n1"])
                     ])
      end
    end

    def test_extra_fields
      omit "/proc/diskstats is only available on *nix" unless Fluent.linux?

      # non supported extra fields are silently ignored
      proc_diskstats = <<EOS
 1000       0 nvme0n1 4000 5000 6000 7000 8000 9000 10000 11000 12000 13000 14000 15000 16000 17000 18000 19000 20000 21000
EOS
      parse(proc_diskstats) do |collector|
        names = Fluent::Plugin::NodeExporter::DiskstatsMetricsCollector::METRIC_NAMES.collect { |v| v.intern }
        assert_equal(names, collector.cmetrics.keys)
      end
    end
  end

  sub_test_case "discards metrics" do
    def test_with_discards
      omit "/proc/diskstats is only available on *nix" unless Fluent.linux?

      # over 4.18 contains discard metrics
      stub(Etc).uname { {release: "4.18.0-1-amd64"} }
      parse(DUMMY_DISKSTATS) do |collector|
        metric_exists = Fluent::Plugin::NodeExporter::DiskstatsMetricsCollector::DISCARD_METRIC_NAMES.all? do |v|
          collector.cmetrics.keys.include?(v.intern)
        end
        assert_true(metric_exists)
      end
    end

    def test_without_discards
      omit "/proc/diskstats is only available on *nix" unless Fluent.linux?

      # lower than 4.18 do not contain it
      stub(Etc).uname { {release: "2.4.20-1-amd64"} }
      parse(DUMMY_DISKSTATS) do |collector|
        no_metric = Fluent::Plugin::NodeExporter::DiskstatsMetricsCollector::DISCARD_METRIC_NAMES.none? do |v|
          collector.cmetrics.keys.include?(v.intern)
        end
        assert_true(no_metric)
      end
    end

    def test_discard_values
      omit "/proc/diskstats is only available on *nix" unless Fluent.linux?

      stub(Etc).uname { {release: "4.18.0-1-amd64"} }
      parse(DUMMY_DISKSTATS) do |collector|
        assert_equal([15000.0, 16000.0, 17000.0, 18.0],
                     [collector.cmetrics[:discards_completed_total].val(["nvme0n1"]),
                      collector.cmetrics[:discards_merged_total].val(["nvme0n1"]),
                      collector.cmetrics[:discarded_sectors_total].val(["nvme0n1"]),
                      collector.cmetrics[:discard_time_seconds_total].val(["nvme0n1"])])
      end
    end
  end

  sub_test_case "flush metrics" do
    def test_with_flush
      # over 5.5 contains flush metrics
      stub(Etc).uname { {release: "5.5.0-0-amd64"} }
      parse(DUMMY_DISKSTATS) do |collector|
        metric = Fluent::Plugin::NodeExporter::DiskstatsMetricsCollector::FLUSH_METRIC_NAMES.all? do |v|
          collector.cmetrics.keys.include?(v.intern)
        end
        assert_true(metric)
      end
    end

    def test_without_flush
      # lower than 5.5 do not contain flush metrics
      stub(Etc).uname { {release: "5.4.0-8-amd64"} }
      parse(DUMMY_DISKSTATS) do |collector|
        no_metric = Fluent::Plugin::NodeExporter::DiskstatsMetricsCollector::FLUSH_METRIC_NAMES.none? do |v|
          collector.cmetrics.keys.include?(v.intern)
        end
        assert_true(no_metric)
      end
    end

    def test_flush_values
      stub(Etc).uname { {release: "5.5.0-1-amd64"} }
      parse(DUMMY_DISKSTATS) do |collector|
        assert_equal([19000.0, 20.0],
                     [collector.cmetrics[:flush_requests_total].val(["nvme0n1"]),
                      collector.cmetrics[:flush_requests_time_seconds_total].val(["nvme0n1"])])
      end
    end

  end
end
