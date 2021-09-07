require "helper"
require "fluent/plugin/in_node_exporter_metrics"
require "fluent/plugin/node_exporter_stat_collector"

class NodeExporterTimeColectorTest < Test::Unit::TestCase
  sub_test_case "stat" do

    def test_stat
      proc_stat = <<EOS
intr 100 33
ctxt 10000
processes 1000
btime 1630974699
procs_running 2
procs_blocked 3
EOS
      stub(File).readlines { proc_stat.split("\n") }
      collector = Fluent::Plugin::NodeExporter::StatMetricsCollector.new
      collector.run
      intr_total = collector.cmetrics[:intr_total]
      context_switches_total = collector.cmetrics[:context_switches_total]
      forks_total = collector.cmetrics[:forks_total]
      boot_time_seconds = collector.cmetrics[:boot_time_seconds]
      procs_running = collector.cmetrics[:procs_running]
      procs_blocked = collector.cmetrics[:procs_blocked]
      assert_equal([100.0, 10000.0, 1000.0, 1630974699.0, 2.0, 3.0],
                   [intr_total.val, context_switches_total.val,
                    forks_total.val, boot_time_seconds.val, procs_running.val, procs_blocked.val])
    end
  end
end
