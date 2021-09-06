require "helper"
require "fluent/plugin/in_node_exporter_metrics.rb"

class NodeExporterMetricsInputTest < Test::Unit::TestCase
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


  sub_test_case "configure" do
    def test_default_parameters
      d = create_driver(CONFIG)
      assert_equal([5, "/proc", "/sys"],
                   [d.instance.scrape_interval, d.instance.procfs_path, d.instance.sysfs_path])
    end

    def test_default_collectors
      d = create_driver(CONFIG)
      assert_equal([true] * 11,
                   [d.instance.cpu,
                    d.instance.cpufreq,
                    d.instance.diskstats,
                    d.instance.filefd,
                    d.instance.loadavg,
                    d.instance.meminfo,
                    d.instance.netdev,
                    d.instance.stat,
                    d.instance.time,
                    d.instance.uname,
                    d.instance.vmstat])
    end
  end
end
