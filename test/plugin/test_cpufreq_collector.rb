require "helper"
require "fluent/plugin/in_node_exporter_metrics"
require "fluent/plugin/node_exporter/cpufreq_collector"

class CpufreqColectorTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
    @capability = Fluent::Capability.new
  end

  teardown do
    Fluent::Engine.stop
  end

  CONFIG = config_element("ROOT", "", {
                            "scrape_interval" => 5,
                            "procfs_path" => "/proc",
                            "sysfs_path" => "/sys"
                          })

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::NodeExporterMetricsInput).configure(conf)
  end

  sub_test_case "cpufreq" do
    data(
      with: ["with_cur_freq", [
               2200000.0, 2500000.0, 2000000.0,
               2300000.0, 2400000.0, 2100000.0,
               2600000.0, 2900000.0, 2400000.0,
               2900000.0, 3000000.0, 2700000.0]],
      without: ["without_cur_freq", [
                  nil, 2500000.0, 2000000.0,
                  nil, 2400000.0, 2100000.0,
                  2600000.0, 2900000.0, 2400000.0,
                  2900000.0, 3000000.0, 2700000.0]]
    )
    test "cpuinfo_cur_frequency" do |(fixture, expected)|
      config = {
        sysfs_path: fixture_sysfs_root("cpufreq", fixture)
      }
      collector = Fluent::Plugin::NodeExporter::CpufreqMetricsCollector.new(config)
      collector.run
      frequency_hertz = collector.cmetrics[:frequency_hertz]
      frequency_max_hertz = collector.cmetrics[:frequency_max_hertz]
      frequency_min_hertz = collector.cmetrics[:frequency_min_hertz]
      scaling_frequency_hertz = collector.cmetrics[:scaling_frequency_hertz]
      scaling_frequency_max_hertz = collector.cmetrics[:scaling_frequency_max_hertz]
      scaling_frequency_min_hertz = collector.cmetrics[:scaling_frequency_min_hertz]
      assert_equal(expected,
                   [frequency_hertz.val(["0"]),
                    frequency_max_hertz.val(["0"]),
                    frequency_min_hertz.val(["0"]),
                    frequency_hertz.val(["1"]),
                    frequency_max_hertz.val(["1"]),
                    frequency_min_hertz.val(["1"]),
                    scaling_frequency_hertz.val(["0"]),
                    scaling_frequency_max_hertz.val(["0"]),
                    scaling_frequency_min_hertz.val(["0"]),
                    scaling_frequency_hertz.val(["1"]),
                    scaling_frequency_max_hertz.val(["1"]),
                    scaling_frequency_min_hertz.val(["1"]),
                   ])
    end
  end
end
