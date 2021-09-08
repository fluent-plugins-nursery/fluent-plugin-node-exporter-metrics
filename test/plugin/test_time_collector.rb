require "helper"
require "fluent/plugin/in_node_exporter_metrics"
require "fluent/plugin/node_exporter/time_collector"

class TimeColectorTest < Test::Unit::TestCase
  sub_test_case "time_seconds" do
    def test_time_now
      collector = Fluent::Plugin::NodeExporter::TimeMetricsCollector.new
      stub(Fluent::EventTime).now { Fluent::EventTime.new(1e9) }
      collector.run
      time_seconds = collector.cmetrics[:time_seconds]
      assert_equal(1.0, time_seconds.val)
    end
  end
end
