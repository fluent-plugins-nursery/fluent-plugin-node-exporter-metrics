require "helper"
require "fluent/plugin/in_node_exporter_metrics"
require "fluent/plugin/node_exporter/loadavg_collector"

class NodeExporterLoadavgColectorTest < Test::Unit::TestCase
  sub_test_case "loadavg" do

    def parse(input)
      stub(File).read { input }
      collector = Fluent::Plugin::NodeExporter::LoadavgMetricsCollector.new
      collector.run
      yield collector
    end

    def test_invalid_fields
      proc_loadavg = <<EOS
0.32 0.30 0.31 2/1880 70024 0
EOS
      parse(proc_loadavg) do |collector|
        loadavg1 = collector.cmetrics[:loadavg1]
        loadavg5 = collector.cmetrics[:loadavg5]
        loadavg15 = collector.cmetrics[:loadavg15]
        assert_equal([0.0, 0.0, 0.0],
                     [loadavg1.val, loadavg5.val, loadavg15.val])
      end
    end

    def test_valid_fields
      proc_loadavg = <<EOS
0.10 0.20 0.30 2/1880 70024
EOS
      parse(proc_loadavg) do |collector|
        loadavg1 = collector.cmetrics[:loadavg1]
        loadavg5 = collector.cmetrics[:loadavg5]
        loadavg15 = collector.cmetrics[:loadavg15]
        assert_equal([0.10, 0.20, 0.30],
                     [loadavg1.val, loadavg5.val, loadavg15.val])
      end
    end
  end
end
