$LOAD_PATH.unshift(File.expand_path("../../", __FILE__))
require "test-unit"
require "test/unit/rr"
require "fluent/test"
require "fluent/test/driver/input"
require "fluent/test/helpers"
require "fluent/plugin/in_node_exporter_metrics"

Test::Unit::TestCase.include(Fluent::Test::Helpers)
Test::Unit::TestCase.extend(Fluent::Test::Helpers)

def fixture_filesystem_root(collector, test_case, filesystem)
  File.expand_path(File.join(File.dirname(__FILE__), "fixtures",
                             collector, test_case, filesystem))
end

def fixture_sysfs_root(collector, test_case)
  fixture_filesystem_root(collector, test_case, "sys")
end

def fixture_procfs_root(collector, test_case)
  fixture_filesystem_root(collector, test_case, "proc")
end

