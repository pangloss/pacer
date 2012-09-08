# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "pacer/version"

Gem::Specification.new do |s|
  s.name = "pacer"
  s.version = Pacer::VERSION
  s.platform = 'java'
  s.authors = ["Darrick Wiebe"]
  s.email = "darrick@innatesoftware.com"
  s.homepage = "http://github.com/pangloss/pacer"
  s.license = "MIT"
  s.summary = %Q{A very efficient and easy to use graph traversal engine.}
  s.description = %Q{Pacer defines routes through a graph and then traverses them very quickly.}

  s.files = `git ls-files`.split("\n") + [Pacer::JAR_PATH]
  s.test_files = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ['lib']
end

