# coding: utf-8

lib = File.expand_path('../lib', __FILE__)

$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'opensrs/version'

Gem::Specification.new do |spec|

  spec.name          = "opensrs"
  spec.version       = OpenSRS::Version::VERSION
  spec.authors       = ["Joshua Delsman"]
  spec.email         = ["voxxit@users.noreply.github.com"]
  spec.summary       = "OpenSRS API for Ruby"
  spec.description   = "Provides support to utilize the OpenSRS API with Ruby/Rails."
  spec.homepage      = "https://github.com/voxxit/opensrs"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "libxml-ruby", ">= 0"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 2.0"
  spec.add_development_dependency "shoulda", ">= 0"
  spec.add_development_dependency "nokogiri", ">= 0"

end
