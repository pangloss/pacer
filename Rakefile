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
  spec.rcov = true
  spec.rcov_opts = %w{--exclude generator_internal,jsignal_internal,gems\/,spec\/}
end

task :default => :spec

desc 'Generate documentation'
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', '-', 'LICENSE.txt']
  t.options = ['--no-private']
end

file 'pom.xml' => 'lib/pacer/version.rb' do
  pom = File.read 'pom.xml'
  when_writing('Update pom.xml version number') do
    open 'pom.xml', 'w' do |f|
      pom.each_line do |line|
        line.sub!(%r{<gem.version>.*</gem.version>}, "<gem.version>#{ Pacer::VERSION }</gem.version>")
        line.sub!(%r{<blueprints.version>.*</blueprints.version>}, "<blueprints.version>#{ Pacer::BLUEPRINTS_VERSION }</blueprints.version>")
        line.sub!(%r{<pipes.version>.*</pipes.version>}, "<pipes.version>#{ Pacer::PIPES_VERSION }</pipes.version>")
        f << line
      end
    end
  end
end

file Pacer::JAR_PATH => 'pom.xml' do
  when_writing("Execute 'mvn package' task") do
    system('mvn clean package')
  end
end

task :check_18_mode do
  if RUBY_VERSION !~ /1\.8/
    warn 'Releasing gems in 1.9 mode does not work as of JRuby 1.6.5'
    raise 'Nooooooo!'
  end
end
task :jar => Pacer::JAR_PATH
task :build => Pacer::JAR_PATH
task :install => Pacer::JAR_PATH
task :release => :check_18_mode
