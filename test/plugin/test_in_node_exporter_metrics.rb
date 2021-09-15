require "helper"
require "fluent/plugin/in_node_exporter_metrics.rb"

class NodeExporterMetricsInputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
    @capability = Fluent::Capability.new(:current_process)
  end

  teardown do
    Fluent::Engine.stop
  end

  CONFIG = config_element("ROOT", "", {
                            "scrape_interval" => 5,
                            "procfs_path" => "/proc",
                            "sysfs_path" => "/sys",
                            "cpufreq" => false # assume linux capability is not set by default environment
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

    def test_empty_collectors
      params = {}
      %w(cpu cpufreq diskstats filefd loadavg meminfo netdev stat time uname vmstat).each do |collector|
        params[collector] = false
      end
      assert_raise(Fluent::ConfigError.new("all collectors are disabled. Enable at least one collector.")) do
        create_driver(config_element("ROOT", "", params))
      end
    end

    def test_default_collectors
      d = create_driver(CONFIG)
      if @capability.have_capability?(:effective, :dac_read_search)
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
      else
        assert_equal([true, false, true, true, true, true, true, true, true, true, true],
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

    def test_customizable
      d = create_driver(config_element("ROOT", "", {
                                                  "scrape_interval" => 10,
                                                  "procfs_path" => "/proc/dummy",
                                                  "sysfs_path" => "/sys/dummy",
                                                  "cpu" => "true",
                                                  "cpufreq" => "false",
                                                  "diskstats" => "false",
                                                  "filefd" => "false",
                                                  "loadavg" => "false",
                                                  "meminfo" => "false",
                                                  "netdev" => "false",
                                                  "stat" => "false",
                                                  "time" => "false",
                                                  "uname" => "false",
                                                  "vmstat" => "false"
                                                }))
      assert_equal([10.0, "/proc/dummy", "/sys/dummy", true, false, false, false, false, false, false, false, false, false, false],
                   [d.instance.scrape_interval,
                    d.instance.procfs_path,
                    d.instance.sysfs_path,
                    d.instance.cpu,
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

  sub_test_case "capability" do
    def test_no_capability_error
      unless @capability.have_capability?(:effective, :dac_read_search)
        assert_raise(Fluent::ConfigError.new("Linux capability CAP_DAC_READ_SEARCH must be enabled")) do
          d = create_driver(config_element("ROOT", "", {}))
          d.run
        end
      end
    end
  end
end
