lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name    = "fluent-plugin-node-exporter-metrics"
  spec.version = "0.1.0"
  spec.authors = ["Kentaro Hayashi"]
  spec.email   = ["hayashi@clear-code.com"]

  spec.summary       = %q{Input plugin which collects metrics similar to Prometheus Node Exporter}
  spec.description   = %q{node exporter metrics input plugin implements 11 node exporter collectors}
  spec.homepage      = "https://github.com/fluent-plugins-nursery/fluent-plugin-node-exporter-metrics"
  spec.license       = "Apache-2.0"

  test_files, files  = `git ls-files -z`.split("\x0").partition do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.files         = files
  spec.executables   = files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = test_files
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.2.24"
  spec.add_development_dependency "rake", "~> 13.0.6"
  spec.add_development_dependency "test-unit", "~> 3.4.4"
  spec.add_runtime_dependency "fluentd", [">= 0.14.10", "< 2"]
end
