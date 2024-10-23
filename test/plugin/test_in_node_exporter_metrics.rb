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

  ALL_COLLECTOR_NAMES = %w(cpu cpufreq diskstats filefd loadavg meminfo netdev stat time uname vmstat)

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::NodeExporterMetricsInput).configure(conf)
  end

  def create_minimum_config_params
    params = {"scrape_interval" => 1}
    ALL_COLLECTOR_NAMES.each do |field|
      params[field] = false
    end
    params
  end

  def cpufreq_readable?
    freq_path = "/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq"
    Dir.exist?("/sys/devices/system/cpu/cpu0/cpufreq") and
      File.exist?(freq_path) and
      (File.readable?(freq_path) or cpufreq_capability?)
  end

  def cpufreq_capability?
    @capability.have_capability?(:effective, :dac_read_search)
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

    def test_default_collectors_with_capability
      omit "skip assertion when linux capability is not available" unless cpufreq_readable?
      d = create_driver(config_element("ROOT", "", {}))
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

    sub_test_case "scrape interval" do
      def test_shorter_interval
        d = create_driver(config_element("ROOT", "", { "scrape_interval" => 2 , "cpufreq" => false}))
        d.run(expect_records: 2, timeout: 5)
        assert_equal(2, d.events.size)
      end

      def test_longer_interval
        d = create_driver(config_element("ROOT", "", { "scrape_interval" => 10, "cpufreq" => false}))
        d.run(expect_records: 1, timeout: 10)
        assert_equal(1, d.events.size)
      end
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

  sub_test_case "collectors" do
    sub_test_case "cpu collector" do
      def test_cpu_with_thermal_throttle
        omit "thermal throttle requires specific sysfs" unless Dir.exist?("/sys/devices/system/cpu/cpu0/thermal_throttle")

        params = create_minimum_config_params
        params["cpu"] = true
        d = create_driver(config_element("ROOT", "", params))
        d.run(expect_records: 1, timeout: 2)
        cmetrics = MessagePack.unpack(d.events.first.last["cmetrics"])
        # FIXME: size of core_throttles_total, package_throttles_total values
        assert_equal([
                       4,
                       {"ns"=>"node", "ss"=>"cpu", "name"=>"core_throttles_total","desc"=>"Number of times this CPU core has been throttled."},
                       {"ns"=>"node", "ss"=>"cpu", "name"=>"package_throttles_total", "desc"=>"Number of times this CPU package has been throttled."},
                       {"ns"=>"node", "ss"=>"cpu", "name"=>"seconds_total", "desc"=>"Seconds the CPUs spent in each mode."},
                       {"ns"=>"node", "ss"=>"cpu", "name"=>"guest_seconds_total","desc"=>"Seconds the CPUs spent in guests (VMs) for each mode."},
                       Etc.nprocessors * ["idle", "iowait", "irq", "nice", "softirq", "steal", "system", "user"].size,
                       Etc.nprocessors * ["user", "nice"].size,
                     ],
                     [
                       cmetrics.size,
                       cmetrics.collect do |metric|
                         metric["meta"]["opts"]
                       end,
                       cmetrics[2]["values"].size,
                       cmetrics[3]["values"].size
                     ].flatten)
      end

      def test_cpu_without_thermal_throttle
        omit "thermal throttle requires specific sysfs" if Dir.exist?("/sys/devices/system/cpu/cpu0/thermal_throttle")

        params = create_minimum_config_params
        params["cpu"] = true
        d = create_driver(config_element("ROOT", "", params))
        d.run(expect_records: 1, timeout: 2)
        cmetrics = MessagePack.unpack(d.events.first.last["cmetrics"])
        assert_equal([
                       2,
                       {"ns"=>"node", "ss"=>"cpu", "name"=>"seconds_total", "desc"=>"Seconds the CPUs spent in each mode."},
                       Etc.nprocessors * ["idle", "iowait", "irq", "nice", "softirq", "steal", "system", "user"].size,
                       {"ns"=>"node", "ss"=>"cpu", "name"=>"guest_seconds_total", "desc"=>"Seconds the CPUs spent in guests (VMs) for each mode."},
                       Etc.nprocessors * ["nice", "user"].size,
                     ],
                     [
                       cmetrics.size,
                       cmetrics.first["meta"]["opts"],
                       cmetrics.first["values"].size,
                       cmetrics.last["meta"]["opts"],
                       cmetrics.last["values"].size
                     ])
      end
    end

    sub_test_case "cpufreq collector" do
      def test_cpufreq
        omit "cpufreq collector requires linux capability" unless cpufreq_readable?
        params = create_minimum_config_params
        params["cpufreq"] = true
        d = create_driver(config_element("ROOT", "", params))
        d.run(expect_records: 1, timeout: 2)
        cmetrics = MessagePack.unpack(d.events.first.last["cmetrics"])
        value_counts = if File.exist?("/sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_cur_freq")
                         [Etc.nprocessors] * 6
                       else
                         [0, [Etc.nprocessors] * 5].flatten
                       end
        assert_equal([
                       6,
                       {"desc"=>"Current cpu thread frequency in hertz.",
                        "name"=>"frequency_hertz",
                        "ns"=>"node",
                        "ss"=>"cpu"},
                       {"desc"=>"Maximum cpu thread frequency in hertz.",
                        "name"=>"frequency_max_hertz",
                        "ns"=>"node",
                        "ss"=>"cpu"},
                       {"desc"=>"Minimum cpu thread frequency in hertz.",
                        "name"=>"frequency_min_hertz",
                        "ns"=>"node",
                        "ss"=>"cpu"},
                       {"desc"=>"Current scaled CPU thread frequency in hertz.",
                        "name"=>"scaling_frequency_hertz",
                        "ns"=>"node",
                        "ss"=>"cpu"},
                       {"desc"=>"Maximum scaled CPU thread frequency in hertz.",
                        "name"=>"scaling_frequency_max_hertz",
                        "ns"=>"node",
                        "ss"=>"cpu"},
                       {"desc"=>"Minimum scaled CPU thread frequency in hertz.",
                        "name"=>"scaling_frequency_min_hertz",
                        "ns"=>"node",
                        "ss"=>"cpu"},
                       value_counts
                     ].flatten,
                     [
                       cmetrics.size,
                       cmetrics.collect do |cmetric|
                         cmetric["meta"]["opts"]
                       end,
                       cmetrics.collect do |cmetric|
                         cmetric["values"].size
                       end,
                     ].flatten)
      end

      def test_without_capability
        omit "skip assertion if linux capability is enabled" if cpufreq_capability?
        assert_raise(Fluent::ConfigError.new("Linux capability CAP_DAC_READ_SEARCH must be enabled")) do
          params = create_minimum_config_params
          params["cpufreq"] = true
          create_driver(config_element("ROOT", "", params))
        end
      end
    end

    sub_test_case "diskstats collector" do
      def test_diskstats
        params = create_minimum_config_params
        params["diskstats"] = true
        d = create_driver(config_element("ROOT", "", params))
        d.run(expect_records: 1, timeout: 2)
        c = Fluent::Plugin::NodeExporter::DiskstatsMetricsCollector.new
        cmetrics = MessagePack.unpack(d.events.first.last["cmetrics"])
        assert_equal([
                       true,
                     ],
                     [
                       cmetrics.all? { |cmetric| cmetric["values"].size == c.target_devices.size }
                     ])
      end
    end

    sub_test_case "filefd collector" do
      def test_filefd
        params = create_minimum_config_params
        params["filefd"] = true
        d = create_driver(config_element("ROOT", "", params))
        d.run(expect_records: 1, timeout: 2)
        cmetrics = MessagePack.unpack(d.events.first.last["cmetrics"])
        assert_equal([
                       2,
                       {"ns"=>"node", "ss"=>"filefd", "name"=>"allocated", "desc"=>"File descriptor statistics: allocated."},
                       1,
                       {"ns"=>"node", "ss"=>"filefd", "name"=>"maximum", "desc"=>"File descriptor statistics: maximum."},
                       1
                     ],
                     [
                       cmetrics.size,
                       cmetrics.first["meta"]["opts"],
                       cmetrics.first["values"].size,
                       cmetrics.last["meta"]["opts"],
                       cmetrics.last["values"].size
                     ])
      end
    end

    sub_test_case "loadavg collector" do
      def test_loadavg
        params = create_minimum_config_params
        params["loadavg"] = true
        d = create_driver(config_element("ROOT", "", params))
        d.run(expect_records: 1, timeout: 2)
        cmetrics = MessagePack.unpack(d.events.first.last["cmetrics"])
        assert_equal([
                       3,
                       {"ns"=>"node", "ss"=>"", "name"=>"load1", "desc"=>"1m load average."},
                       {"ns"=>"node", "ss"=>"", "name"=>"load5", "desc"=>"5m load average."},
                       {"ns"=>"node", "ss"=>"", "name"=>"load15", "desc"=>"15m load average."},
                     ],
                     [
                       cmetrics.size,
                       cmetrics[0]["meta"]["opts"],
                       cmetrics[1]["meta"]["opts"],
                       cmetrics[2]["meta"]["opts"]
                     ])
      end
    end

    sub_test_case "meminfo collector" do
      def meminfo_key_exist?(key)
        File.readlines("/proc/meminfo").any? { |v| v.start_with?(key) }
      end

      def test_meminfo
        params = create_minimum_config_params
        params["meminfo"] = true
        d = create_driver(config_element("ROOT", "", params))
        d.run(expect_records: 1, timeout: 2)
        cmetrics = MessagePack.unpack(d.events.first.last["cmetrics"])
        fields = %w(
          MemTotal_bytes
          MemFree_bytes
          MemAvailable_bytes
          Buffers_bytes
          Cached_bytes
          SwapCached_bytes
          Active_bytes
          Inactive_bytes
          Active_anon_bytes
          Inactive_anon_bytes
          Active_file_bytes
          Inactive_file_bytes
          Unevictable_bytes
          Mlocked_bytes
          SwapTotal_bytes
          SwapFree_bytes)
        if meminfo_key_exist?("Zswap")
          fields.concat(%w(
            Zswap_bytes
            Zswapped_bytes
          ))
        end
        fields.concat(%w(
          Dirty_bytes
          Writeback_bytes
          AnonPages_bytes
          Mapped_bytes
          Shmem_bytes
          ))
        fields.concat(["KReclaimable_bytes"]) if meminfo_key_exist?("KReclaimable")
        fields.concat(%w(
          Slab_bytes
          SReclaimable_bytes
          SUnreclaim_bytes
          KernelStack_bytes
          PageTables_bytes))
        fields.concat(["SecPageTables_bytes"]) if meminfo_key_exist?("SecPageTables")
        fields.concat(%w(
          NFS_Unstable_bytes
          Bounce_bytes
          WritebackTmp_bytes
          CommitLimit_bytes
          Committed_AS_bytes
          VmallocTotal_bytes
          VmallocUsed_bytes
          VmallocChunk_bytes
          Percpu_bytes
          HardwareCorrupted_bytes
          AnonHugePages_bytes
          ))
        fields.concat(["CmaTotal_bytes"]) if meminfo_key_exist?("CmaTotal")
        fields.concat(["CmaFree_bytes"]) if meminfo_key_exist?("CmaFree")
        fields.concat(["ShmemHugePages_bytes"]) if meminfo_key_exist?("ShmemHugePages")
        fields.concat(["ShmemPmdMapped_bytes"]) if meminfo_key_exist?("ShmemPmdMapped")
        fields.concat(["FileHugePages_bytes"]) if meminfo_key_exist?("FileHugePages")
        fields.concat(["FilePmdMapped_bytes"]) if meminfo_key_exist?("FilePmdMapped")
        fields.concat(["Unaccepted_bytes"]) if meminfo_key_exist?("Unaccepted")
        fields.concat(%w(
          HugePages_Total
          HugePages_Free
          HugePages_Rsvd
          HugePages_Surp
          Hugepagesize_bytes
        ))
        fields.concat(["Hugetlb_bytes"]) if meminfo_key_exist?("Hugetlb")
        fields.concat(%w(
          DirectMap4k_bytes
          DirectMap2M_bytes
          DirectMap1G_bytes
        ))
        opts = []
        fields.each do |field|
          opts << {"ns"=>"node", "ss"=>"memory", "name"=>field, "desc"=>"Memory information field node_memory_#{field}."}
        end
        assert_equal([
                       fields.size,
                       opts
                     ].flatten,
                     [
                       cmetrics.size,
                       cmetrics.collect do |metric| metric["meta"]["opts"] end
                     ].flatten)
      end
    end

    sub_test_case "netdev collector" do
      def test_netdev
        params = create_minimum_config_params
        params["netdev"] = true
        d = create_driver(config_element("ROOT", "", params))
        d.run(expect_records: 1, timeout: 2)
        c = Fluent::Plugin::NodeExporter::NetdevMetricsCollector.new
        cmetrics = MessagePack.unpack(d.events.first.last["cmetrics"])
        opts = []
        Fluent::Plugin::NodeExporter::NetdevMetricsCollector::RECEIVE_FIELDS.each do |field|
          opts << {"ns"=>"node", "ss"=>"network",
                   "name"=>"receive_#{field}_total", "desc"=>"Network device statistic receive_#{field}_total."}
        end
        Fluent::Plugin::NodeExporter::NetdevMetricsCollector::TRANSMIT_FIELDS.each do |field|
          opts << {"ns"=>"node", "ss"=>"network",
                   "name"=>"transmit_#{field}_total", "desc"=>"Network device statistic transmit_#{field}_total."}
        end
        assert_equal([
                       16, # receive 8 + transmit 8 entries
                       opts,
                       [c.target_devices.size] * 16
                     ].flatten,
                     [
                       cmetrics.size,
                       cmetrics.collect do |cmetric|
                         cmetric["meta"]["opts"]
                       end,
                       cmetrics.collect do |cmetric|
                         cmetric["values"].size
                       end
                     ].flatten)
      end
    end

    sub_test_case "stat collector" do
      def test_stat
        params = create_minimum_config_params
        params["stat"] = true
        d = create_driver(config_element("ROOT", "", params))
        d.run(expect_records: 1, timeout: 2)
        cmetrics = MessagePack.unpack(d.events.first.last["cmetrics"])
        assert_equal([
                       6,
                       {"desc"=>"Total number of interrupts serviced.",
                        "name"=>"intr_total",
                        "ns"=>"node",
                        "ss"=>""},
                       {"desc"=>"Total number of context switches.",
                        "name"=>"context_switches_total",
                        "ns"=>"node",
                        "ss"=>""},
                       {"desc"=>"Total number of forks.",
                        "name"=>"forks_total",
                        "ns"=>"node",
                        "ss"=>""},
                       {"desc"=>"Node boot time, in unixtime.",
                        "name"=>"boot_time_seconds",
                        "ns"=>"node",
                        "ss"=>""},
                       {"desc"=>"Number of processes in runnable state.",
                        "name"=>"procs_running",
                        "ns"=>"node",
                        "ss"=>""},
                       {"desc"=>"Number of processes blocked waiting for I/O to complete.",
                        "name"=>"procs_blocked",
                        "ns"=>"node",
                        "ss"=>""},
                     ],
                     [
                       cmetrics.size,
                       cmetrics.collect do |cmetric|
                         cmetric["meta"]["opts"]
                       end,
                     ].flatten)
      end
    end

    sub_test_case "time collector" do
      def test_time
        params = create_minimum_config_params
        params["time"] = true
        d = create_driver(config_element("ROOT", "", params))
        d.run(expect_records: 1, timeout: 2)
        cmetrics = MessagePack.unpack(d.events.first.last["cmetrics"])
        assert_equal([
                       1,
                       {"desc"=>"System time in seconds since epoch (1970).",
                        "name"=>"time_seconds",
                        "ns"=>"node",
                        "ss"=>""}
                     ],
                     [
                       cmetrics.size,
                       cmetrics.collect do |cmetric|
                         cmetric["meta"]["opts"]
                       end,
                     ].flatten)
      end
    end

    sub_test_case "uname collector" do
      def test_uname
        params = create_minimum_config_params
        params["uname"] = true
        d = create_driver(config_element("ROOT", "", params))
        d.run(expect_records: 1, timeout: 2)
        cmetrics = MessagePack.unpack(d.events.first.last["cmetrics"])
        assert_equal([
                       1,
                       {"desc"=>"Labeled system information as provided by the uname system call.",
                        "name"=>"info",
                        "ns"=>"node",
                        "ss"=>"uname"}
                     ],
                     [
                       cmetrics.size,
                       cmetrics.collect do |cmetric|
                         cmetric["meta"]["opts"]
                       end,
                     ].flatten)
      end
    end

    sub_test_case "vmstat collector" do
      def test_vmstat
        params = create_minimum_config_params
        params["vmstat"] = true
        d = create_driver(config_element("ROOT", "", params))
        d.run(expect_records: 1, timeout: 2)
        cmetrics = MessagePack.unpack(d.events.first.last["cmetrics"])
        expected = [
          {"desc"=>"/proc/vmstat information field pgpgin.",
           "name"=>"pgpgin",
           "ns"=>"node",
           "ss"=>"vmstat"},
          {"desc"=>"/proc/vmstat information field pgpgout.",
           "name"=>"pgpgout",
           "ns"=>"node",
           "ss"=>"vmstat"},
          {"desc"=>"/proc/vmstat information field pswpin.",
           "name"=>"pswpin",
           "ns"=>"node",
           "ss"=>"vmstat"},
          {"desc"=>"/proc/vmstat information field pswpout.",
           "name"=>"pswpout",
           "ns"=>"node",
           "ss"=>"vmstat"},
          {"desc"=>"/proc/vmstat information field pgfault.",
           "name"=>"pgfault",
           "ns"=>"node",
           "ss"=>"vmstat"},
          {"desc"=>"/proc/vmstat information field pgmajfault.",
           "name"=>"pgmajfault",
           "ns"=>"node",
           "ss"=>"vmstat"}
        ]
        if Gem::Version.new(Etc.uname[:release].split("-", 2).first) >= Gem::Version.new("4.13.0")
          # oom_kill counter since kernel 4.13+
          expected << {"desc"=>"/proc/vmstat information field oom_kill.",
                       "name"=>"oom_kill",
                       "ns"=>"node",
                       "ss"=>"vmstat"}
        end
        assert_equal([
                       expected.size,
                       expected
                     ].flatten,
                     [
                       cmetrics.size,
                       cmetrics.collect do |cmetric|
                         cmetric["meta"]["opts"]
                       end,
                     ].flatten)
      end
    end
  end
end
