require "helper"
require "fluent/plugin/in_node_exporter_metrics"
require "fluent/plugin/node_exporter/filefd_collector"

class FilefdColectorTest < Test::Unit::TestCase
  sub_test_case "filefd" do

    def parse(input)
      stub(File).read { input }
      collector = Fluent::Plugin::NodeExporter::FilefdMetricsCollector.new
      collector.run
      yield collector
    end

    def test_invalid_fields
      proc_filefd = <<EOS
100	0	10000	1
EOS
      parse(proc_filefd) do |collector|
        allocated = collector.cmetrics[:filefd_allocated]
        maximum = collector.cmetrics[:filefd_maximum]
        assert_equal([0.0, 0.0],
                     [allocated.val, maximum.val])
      end
    end

    def test_valid_fields
      proc_filefd = <<EOS
100	0	10000
EOS
      parse(proc_filefd) do |collector|
        allocated = collector.cmetrics[:filefd_allocated]
        maximum = collector.cmetrics[:filefd_maximum]
        assert_equal([100.0, 10000.0],
                     [allocated.val, maximum.val])
      end
    end
  end
end
