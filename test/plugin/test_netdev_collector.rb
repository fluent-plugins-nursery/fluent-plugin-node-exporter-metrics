require "helper"
require "fluent/plugin/in_node_exporter_metrics"
require "fluent/plugin/node_exporter/netdev_collector"

class NodeExporterNetdevColectorTest < Test::Unit::TestCase
  sub_test_case "netdev" do

    def parse(input)
      stub(File).readlines { input.split("\n") }
      collector = Fluent::Plugin::NodeExporter::NetdevMetricsCollector.new
      collector.run
      yield collector
    end

    def test_netdev_lo
      proc_netdev = <<EOS
Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
    lo:    1          2    3    4    5     6          7         8     9         10   11   12   13    14      15         16
EOS
      parse(proc_netdev) do |collector|
        expected = 16.times.collect do |i| (i + 1).to_f end

        values = []
        Fluent::Plugin::NodeExporter::NetdevMetricsCollector::RECEIVE_FIELDS.each do |field|
          values << collector.cmetrics["receive_#{field}_total"].val(["lo"])
        end
        Fluent::Plugin::NodeExporter::NetdevMetricsCollector::TRANSMIT_FIELDS.each do |field|
          values << collector.cmetrics["transmit_#{field}_total"].val(["lo"])
        end
        assert_equal(expected, values)
      end
    end
  end
end
