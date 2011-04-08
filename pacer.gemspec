# -*- encoding: utf-8 -*-
Gem::Specification.new do |s|
  s.name = "pacer"
  s.version = File.read('VERSION').strip
  s.platform = 'jruby'
  s.authors = ["Darrick Wiebe"]
  s.email = "darrick@innatesoftware.com"
  s.homepage = "http://github.com/pangloss/pacer"
  s.license = "MIT"
  s.summary = %Q{A very efficient and easy to use graph traversal engine.}
  s.description = %Q{Pacer defines routes through a graph and then traverses them very quickly.}

  s.add_dependency 'pacer-graph', '1.0.0'
  s.add_dependency 'parslet', '1.2'
  s.add_dependency 'fastercsv', '>= 1.5.4'
  s.add_development_dependency 'rspec', '~> 2.5.0'
  s.add_development_dependency 'rr', '~> 1.0'
  s.add_development_dependency 'rcov'
  s.add_development_dependency 'yard'
  s.add_development_dependency 'rake'

  s.files = `git ls-files`.split("\n")
  s.test_files = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ['lib']
end

