require "helper"
require "fluent/plugin/in_node_exporter_metrics"
require "fluent/plugin/node_exporter_loadavg_collector"

class NodeExporterTimeColectorTest < Test::Unit::TestCase
  sub_test_case "loadavg" do

    def test_invalid_fields
      config = {
        procfs_path: fixture_procfs_root("loadavg", "invalid_fields")
      }
      collector = Fluent::Plugin::NodeExporter::LoadavgMetricsCollector.new(config)
      collector.run
      loadavg1 = collector.cmetrics[:loadavg1]
      loadavg5 = collector.cmetrics[:loadavg5]
      loadavg15 = collector.cmetrics[:loadavg15]
      assert_equal([0.0, 0.0, 0.0],
                   [loadavg1.val, loadavg5.val, loadavg15.val])
    end

    def test_valid_fields
      config = {
        procfs_path: fixture_procfs_root("loadavg", "valid_fields")
      }
      collector = Fluent::Plugin::NodeExporter::LoadavgMetricsCollector.new(config)
      collector.run
      loadavg1 = collector.cmetrics[:loadavg1]
      loadavg5 = collector.cmetrics[:loadavg5]
      loadavg15 = collector.cmetrics[:loadavg15]
      assert_equal([0.10, 0.20, 0.30],
                   [loadavg1.val, loadavg5.val, loadavg15.val])
    end
  end
end
