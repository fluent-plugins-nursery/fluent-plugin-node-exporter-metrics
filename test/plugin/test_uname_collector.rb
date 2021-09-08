require "helper"
require "fluent/plugin/in_node_exporter_metrics"
require "fluent/plugin/node_exporter/uname_collector"

class NodeExporterUnameColectorTest < Test::Unit::TestCase
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

    def test_with_domainmame
      collector = Fluent::Plugin::NodeExporter::UnameMetricsCollector.new
      stub(Etc).uname { WITH_DOMAINNAME }
      collector.run
      info = collector.cmetrics[:info]
      assert_equal(1, info.val(WITH_DOMAINNAME.values))
    end

    def test_without_domainmame
      collector = Fluent::Plugin::NodeExporter::UnameMetricsCollector.new
      stub(Etc).uname { WITHOUT_DOMAINNAME }
      collector.run
      info = collector.cmetrics[:info]
      assert_equal(1, info.val(WITHOUT_DOMAINNAME.values << "(none)"))
    end
  end
end
