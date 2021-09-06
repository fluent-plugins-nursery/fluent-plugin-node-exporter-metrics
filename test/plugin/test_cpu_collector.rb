require "helper"
require "fluent/plugin/in_node_exporter_metrics"
require "fluent/plugin/node_exporter_cpu_collector"

class NodeExporterCpuColectorTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  teardown do
    Fluent::Engine.stop
  end

  CONFIG = config_element("ROOT", "", {
                            "scrape_interval" => 5,
                            "procfs_path" => "/proc",
                            "sysfs_path" => "/sys"
                          })

  DEFAULT_COLLECTORS = CONFIG + config_element("", "", {
                                               })

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::NodeExporterMetricsInput).configure(conf)
  end

  sub_test_case "cpu_thermal_throttle" do
    def test_cpu0_thermal_throttle
      config = {
        scpape_interval: 1,
        procfs_path: fixture_procfs_root("cpu", "with_thermal_throttle"),
        sysfs_path: fixture_sysfs_root("cpu", "with_thermal_throttle")
      }
      collector = Fluent::Plugin::NodeExporterCpuMetricsCollector.new(config)
      collector.run
      # CPU0/1 thermal throttle
      core_throttles_total = collector.cmetrics.first
      assert_equal([1.0, 2.0],
                   [core_throttles_total.val(["0", "0"]), core_throttles_total.val(["1", "0"])])
    end
  end
end
