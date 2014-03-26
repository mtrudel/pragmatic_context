# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pragmatic_context/version'

Gem::Specification.new do |spec|
  spec.name          = "pragmatic_context"
  spec.version       = PragmaticContext::VERSION
  spec.authors       = ["Mat Trudel"]
  spec.email         = ["mat@geeky.net"]
  spec.summary       = %q{JSON-LD from a JSON perspective}
  spec.description   = %q{A library to declaratively add JSON-LD support to your Mongoid models}
  spec.homepage      = "http://github.com/mtrudel/pragmatic_context"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
