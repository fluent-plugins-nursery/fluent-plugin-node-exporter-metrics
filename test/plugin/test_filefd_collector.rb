require "helper"
require "fluent/plugin/in_node_exporter_metrics"
require "fluent/plugin/node_exporter/filefd_collector"

class NodeExporterTimeColectorTest < Test::Unit::TestCase
  sub_test_case "filefd" do

    def test_invalid_fields
      config = {
        procfs_path: fixture_procfs_root("filefd", "invalid_fields")
      }
      collector = Fluent::Plugin::NodeExporter::FilefdMetricsCollector.new(config)
      collector.run
      allocated = collector.cmetrics[:filefd_allocated]
      maximum = collector.cmetrics[:filefd_maximum]
      assert_equal([0.0, 0.0],
                   [allocated.val, maximum.val])
    end

    def test_valid_fields
      config = {
        procfs_path: fixture_procfs_root("filefd", "valid_fields")
      }
      collector = Fluent::Plugin::NodeExporter::FilefdMetricsCollector.new(config)
      collector.run
      allocated = collector.cmetrics[:filefd_allocated]
      maximum = collector.cmetrics[:filefd_maximum]
      assert_equal([100.0, 10000.0],
                   [allocated.val, maximum.val])
    end
  end
end
