lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'match_nodes/version'

Gem::Specification.new do |spec|
  spec.name          = "match_nodes"
  spec.version       = MatchNodes::VERSION
  spec.authors       = ["Conan Dalton"]
  spec.email         = ["conan@conandalton.net"]
  spec.summary       = %q{Matcher for HTML or similarly structured text}
  spec.description   = %q{Use in view specs to flexibly specify contents of a html fragment}
  spec.homepage      = "http://github.com/conanite/match_nodes"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency 'rspec_numbering_formatter'
  spec.add_dependency 'nokogiri'
end
