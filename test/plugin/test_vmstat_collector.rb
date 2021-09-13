require "helper"
require "fluent/plugin/in_node_exporter_metrics"
require "fluent/plugin/node_exporter/vmstat_collector"

class VmstatColectorTest < Test::Unit::TestCase
  sub_test_case "vmstat" do

    def parse(input)
      stub(File).readlines { input.split("\n") }
      collector = Fluent::Plugin::NodeExporter::VmstatMetricsCollector.new
      collector.run
      yield collector
    end

    def test_empty_metrics
      omit "/proc/vmstat is only available on *nix" if Fluent.windows?

      proc_vmstat = <<EOS
numa_hit 168082746
numa_miss 0
EOS
      parse(proc_vmstat) do |collector|
        assert_equal({}, collector.cmetrics)
      end
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
      parse(proc_vmstat) do |collector|
        values = collector.cmetrics.collect do |key, metric|
          {key => metric.val}
        end
        assert_equal([{oom_kill: 0.0},
                      {pgpgin: 1.0},
                      {pgpgout: 2.0},
                      {pswpin: 3.0},
                      {pswpout: 4.0},
                      {pgfault: 5.0},
                      {pgmajfault: 6.0}], values)
      end
    end
  end
end
