# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'slurpy/version'

Gem::Specification.new do |spec|
  spec.name          = "slurpy"
  spec.version       = SlurpyMetadata::VERSION
  spec.authors       = ["Andrea Della Corte"]
  spec.email         = ["andreadellacorte85@gmail.com"]
  spec.description   = %q{Retrieves the SLUShuttle times from the command line.}
  spec.summary       = %q{Command line interface for SLUShuttle.}
  spec.homepage      = "https://github.com/ValiumKnight/slurpy"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_runtime_dependency "typhoeus"
  spec.add_runtime_dependency "thor"
  spec.add_runtime_dependency "api_cache"
  spec.add_runtime_dependency "moneta"
  spec.add_runtime_dependency "timezone"
end
