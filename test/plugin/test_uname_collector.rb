require "helper"
require "fluent/plugin/in_node_exporter_metrics"
require "fluent/plugin/node_exporter/uname_collector"

class UnameColectorTest < Test::Unit::TestCase
  sub_test_case "info" do
    WITHOUT_DOMAINNAME = {
      sysname: "Linux",
      release: "5.10.0-8-amd64",
      version: "#1 SMP Debian 5.10.46-4 (2021-08-03)",
      machine: "x86_64",
      nodename: "jessie",
    }

    WITH_DOMAINNAME = {
      sysname: "Linux",
      release: "5.10.0-8-amd64",
      version: "#1 SMP Debian 5.10.46-4 (2021-08-03)",
      machine: "x86_64",
      nodename: "jackie",
      domainname: "marion"
    }

    def parse
      collector = Fluent::Plugin::NodeExporter::UnameMetricsCollector.new
      collector.run
      yield collector
    end

    def test_with_domainmame
      stub(Etc).uname { WITH_DOMAINNAME }
      parse do |collector|
        info = collector.cmetrics[:info]
        assert_equal(1, info.val(WITH_DOMAINNAME.values))
      end
    end

    def test_without_domainmame
      stub(Etc).uname { WITHOUT_DOMAINNAME }
      parse do |collector|
        collector.run
        info = collector.cmetrics[:info]
        assert_equal(1, info.val(WITHOUT_DOMAINNAME.values << "(none)"))
      end
    end
  end
end
