# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ttcp/version"

Gem::Specification.new do |s|
  s.name        = "ttcp"
  s.version     = TTCP::VERSION
  s.authors     = ["Matt Connolly"]
  s.email       = ["matt@soundevolution.com.au"]
  s.homepage    = ""
  s.summary     = %q{A ruby implementation of the TTCP network test program.}
  s.description = %q{Based on the C command line tool at http://www.pcausa.com/Utilities/pcattcp.htm}

  s.rubyforge_project = "ttcp-rb"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "bundler"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"
  s.add_development_dependency "ci_reporter"
  # s.add_runtime_dependency "rest-client"
end
