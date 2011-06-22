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

file 'pom.xml' => 'lib/pacer/version.rb' do
  pom = File.read 'pom.xml'
  when_writing('Update pom.xml version number') do
    updated = false
    open 'pom.xml', 'w' do |f|
      pom.each_line do |line|
        if not updated and line =~ %r{<version>.*</version>}
          f << line.sub(%r{<version>.*</version>}, "<version>#{ Pacer::VERSION }</version>")
          updated = true
        else
          f << line
        end
      end
    end
  end
end

pipes_jar = 'pipes/target/pipes-0.6-SNAPSHOT-standalone.jar'

file Pacer::JAR_PATH => ['pom.xml', pipes_jar] do
  when_writing("Execute 'mvn package' task") do
    system('mvn clean package')
  end
end

file pipes_jar do
  puts "Pacer requires a customized blueprints pipes install:"
  if !File.exists?('pipes')
    puts "...downloading pangloss' pipes repo from git@github.com/pangloss/pipes.git"
    `git clone https://github.com/pangloss/pipes.git` 
  else
    puts "...found pangloss' pipes repo in pacer/pipes"
  end
  Dir.chdir("pipes")
  puts "running 'mvn install' in #{Dir.getwd}"
  `mvn install`
  puts "pangloss/pipes installed"
end

desc "Build the pacer jar (you'll need this to run pacer)"
task :jar => Pacer::JAR_PATH
task :build => Pacer::JAR_PATH
task :install => Pacer::JAR_PATH
