require 'rubygems'
require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'
require 'yard'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.ruby_opts = '--debug'
  spec.skip_bundler = true
  spec.rcov = true
  spec.rcov_opts = %w{--exclude generator_internal,jsignal_internal,gems\/,spec\/}
end

task :default => :spec

desc 'Generate documentation'
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', '-', 'LICENSE.txt']
  t.options = ['--no-private']
end
