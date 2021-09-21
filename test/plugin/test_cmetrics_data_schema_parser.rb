require "helper"
require "fluent/plugin/node_exporter/cmetrics_dataschema_parser"

class CMetricsDataSchemaParserTest < Test::Unit::TestCase

  NSEC_IN_SECONDS = 1000 * 1000 * 1000

  setup do
    @parser = Fluent::Plugin::NodeExporter::CMetricsDataSchemaParser.new
    @nsecs = Time.parse("2021/09/01").to_i * NSEC_IN_SECONDS
  end

  sub_test_case "parser" do
    def test_without_labels
      objs = [{"meta"=>
               {"ver"=>2,
                "type"=>1,
                "opts"=>
                {"ns"=>"node",
                 "ss"=>"",
                 "name"=>"time_seconds",
                 "desc"=>"System time in seconds since epoch (1970)."},
                "label_dictionary"=>[],
                "static_labels"=>[],
                "labels"=>[]},
               "values"=>[{"ts"=>@nsecs, "value"=>1.632131027}]}]
      assert_equal([
                     {
                       "desc"=>"System time in seconds since epoch (1970).",
                       "name"=>"node_time_seconds",
                       "value"=>1.632131027,
                       "ts"=>@nsecs
                     }
                   ],
                   @parser.parse(objs))
    end

    def test_with_labels
      objs = [{"meta"=>
               {"ver"=>2,
                "type"=>1,
                "opts"=>
                {"ns"=>"node",
                 "ss"=>"uname",
                 "name"=>"info",
                 "desc"=>
                 "Labeled system information as provided by the uname system call."},
                "label_dictionary"=>
                ["sysname",
                 "release",
                 "version",
                 "machine",
                 "nodename",
                 "domainname",
                 "Linux",
                 "5.10.0-8-amd64",
                 "#1 SMP Debian",
                 "x86_64",
                 "jet",
                 "(none)"],
                "static_labels"=>[],
                "labels"=>[0, 1, 2, 3, 4, 5]},
               "values"=>
               [{"ts"=>@nsecs,
                 "value"=>1.0,
                 "labels"=>[6, 7, 8, 9, 10, 11]}]}]
      assert_equal([
                     {"desc"=>"Labeled system information as provided by the uname system call.",
                      "labels"=>
                      {"domainname"=>"(none)",
                       "machine"=>"x86_64",
                       "nodename"=>"jet",
                       "release"=>"5.10.0-8-amd64",
                       "sysname"=>"Linux",
                       "version"=>"#1 SMP Debian"},
                      "name"=>"node_uname_info",
                      "ts"=>@nsecs,
                      "value"=>1.0}
                   ],
                   @parser.parse(objs))
    end
  end
end
