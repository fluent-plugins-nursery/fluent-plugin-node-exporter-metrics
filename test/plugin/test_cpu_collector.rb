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
    def test_cpu_thermal_throttle
      config = {
        scpape_interval: 1,
        procfs_path: fixture_procfs_root("cpu", "with_thermal_throttle"),
        sysfs_path: fixture_sysfs_root("cpu", "with_thermal_throttle")
      }
      collector = Fluent::Plugin::NodeExporter::CpuMetricsCollector.new(config)
      collector.run
      # CPU0/1 thermal throttle
      core_throttles_total = collector.cmetrics[:core_throttles_total]
      assert_equal([1.0, 2.0],
                   [core_throttles_total.val(["0", "0"]), core_throttles_total.val(["1", "0"])])
    end

    def test_cpu_stat
      config = {
        scpape_interval: 1,
        procfs_path: fixture_procfs_root("cpu", "with_thermal_throttle"),
        sysfs_path: fixture_sysfs_root("cpu", "with_thermal_throttle")
      }
      collector = Fluent::Plugin::NodeExporter::CpuMetricsCollector.new(config)
      stub(Etc).sysconf { 1000 }
      collector.run
      seconds_total = collector.cmetrics[:seconds_total]
      guest_seconds_total = collector.cmetrics[:guest_seconds_total]
      assert_equal([4.0, 5.0, 6.0, 2.0, 7.0, 8.0, 3.0, 1.0, 9.0, 10.0],
                   [seconds_total.val(["0", "idle"]),
                    seconds_total.val(["0", "iowait"]),
                    seconds_total.val(["0", "irq"]),
                    seconds_total.val(["0", "nice"]),
                    seconds_total.val(["0", "softirq"]),
                    seconds_total.val(["0", "steal"]),
                    seconds_total.val(["0", "system"]),
                    seconds_total.val(["0", "user"]),
                    guest_seconds_total.val(["0", "user"]),
                    guest_seconds_total.val(["0", "nice"]),
                   ])
    end
  end
end
