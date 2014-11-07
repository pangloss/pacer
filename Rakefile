require 'rubygems'
require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_path = 'bin/rspec'
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec

task :check_18_mode do
  if RUBY_VERSION !~ /1\.8/
    warn 'Releasing gems in 1.9 mode does not work as of JRuby 1.6.5'
    raise 'Nooooooo!'
  end
end
