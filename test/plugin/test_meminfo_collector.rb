require "helper"
require "fluent/plugin/in_node_exporter_metrics"
require "fluent/plugin/node_exporter/meminfo_collector"

class MeminfoColectorTest < Test::Unit::TestCase
  sub_test_case "metric name" do

    def parse(input)
      stub(File).readlines { input.split("\n") }
      collector = Fluent::Plugin::NodeExporter::MeminfoMetricsCollector.new
      collector.run
      yield collector
    end

    def test_anon_file
      proc_meminfo = <<EOS
Active(anon):       100 kB
Inactive(anon):     200 kB
Active(file):       300 kB
Inactive(file):     400 kB
EOS
      parse(proc_meminfo) do |collector|
        assert_equal([102400.0, 204800.0, 307200.0, 409600.0],
                     [collector.cmetrics["node_memory_Active_anon_bytes"].val,
                      collector.cmetrics["node_memory_Inactive_anon_bytes"].val,
                      collector.cmetrics["node_memory_Active_file_bytes"].val,
                      collector.cmetrics["node_memory_Inactive_file_bytes"].val])
      end
    end

    def test_non_kb
      proc_meminfo = <<EOS
HugePages_Total:       100
HugePages_Free:        200
HugePages_Rsvd:        300
HugePages_Surp:        400
EOS
      parse(proc_meminfo) do |collector|
        assert_equal([100, 200, 300, 400],
                     [collector.cmetrics["node_memory_HugePages_Total"].val,
                      collector.cmetrics["node_memory_HugePages_Free"].val,
                      collector.cmetrics["node_memory_HugePages_Rsvd"].val,
                      collector.cmetrics["node_memory_HugePages_Surp"].val])
      end
    end
  end
end
