require "helper"
require "fluent/plugin/in_node_exporter_metrics"
require "fluent/plugin/node_exporter_vmstat_collector"

class NodeExporterVmstatColectorTest < Test::Unit::TestCase
  sub_test_case "vmstat" do
    def test_empty_metrics
      omit "/proc/vmstat is only available on *nix" if Fluent.windows?

      proc_vmstat = <<EOS
numa_hit 168082746
numa_miss 0
EOS
      stub(File).readlines { proc_vmstat.split("\n") }
      collector = Fluent::Plugin::NodeExporter::VmstatMetricsCollector.new
      collector.run
      assert_equal({}, collector.cmetrics)
    end

    def test_all_metrics
      omit "/proc/vmstat is only available on *nix" if Fluent.windows?

      proc_vmstat = <<EOS
oom_kill 0
pgpgin 1
pgpgout 2
pswpin 3
pswpout 4
pgfault 5
pgmajfault 6
EOS
      stub(File).readlines { proc_vmstat.split("\n") }
      collector = Fluent::Plugin::NodeExporter::VmstatMetricsCollector.new
      collector.run
      values = collector.cmetrics.collect do |key, metric|
        {key => metric.val}
      end
      assert_equal([{"oom_kill" => 0.0},
                    {"pgpgin" => 1.0},
                    {"pgpgout" => 2.0},
                    {"pswpin" => 3.0},
                    {"pswpout" => 4.0},
                    {"pgfault" => 5.0},
                    {"pgmajfault" => 6.0}], values)
    end
  end
end
