# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "opensrs/version"

Gem::Specification.new do |spec|

  spec.name          = "opensrs"
  spec.version       = OpenSRS::VERSION
  spec.authors       = [ "Joshua Delsman" ]
  spec.email         = [ "j@srv.im" ]
  spec.summary       = "OpenSRS API for Ruby"
  spec.description   = "Provides support to utilize the OpenSRS API with Ruby."
  spec.homepage      = "https://github.com/voxxit/opensrs"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "libxml-ruby", "~> 3"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "shoulda"
  spec.add_development_dependency "nokogiri", '~> 1.11.4'
  spec.add_development_dependency "pry"
  spec.add_development_dependency 'activesupport', '~> 4.2.2'
  spec.add_development_dependency 'rubocop', '~> 1'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'code-scanning-rubocop', '~> 0.5'
end
