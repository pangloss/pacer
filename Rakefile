require 'rubygems'
require 'bundler'
Bundler::GemHelper.install_tasks

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.rspec_path = 'bin/rspec'
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :mvn_tests do
  cd 'ext' do
    sh 'mvn test'
  end
end

task :default => :spec
task :spec => :compile

task :check_18_mode do
  if RUBY_VERSION !~ /1\.8/
    warn 'Releasing gems in 1.9 mode does not work as of JRuby 1.6.5'
    raise 'Nooooooo!'
  end
end

require 'xn_gem_release_tasks'
XNGemReleaseTasks.setup Pacer, 'lib/pacer/version.rb'

task :build => :compile

require 'rake/javaextensiontask'
Rake::JavaExtensionTask.new('pacer-ext') do |ext|
  require 'lock_jar'
  LockJar.lock
  locked_jars = LockJar.load

  ext.name = 'pacer-ext'
  ext.ext_dir = 'ext/src/main/java'
  ext.lib_dir = 'lib'
  ext.source_version = '1.7'
  ext.target_version = '1.7'
  ext.classpath = locked_jars.map {|x| File.expand_path x}.join ':'
end

task :compile => :mvn_tests
