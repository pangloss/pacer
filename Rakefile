require 'rubygems'
require 'rake'
require 'pathname'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "pacer"
    gem.summary = %Q{A very efficient and easy to use graph traversal engine.}
    gem.description = %Q{Pacer defines routes through a graph and then traverses them very quickly.}
    gem.email = "darrick@innatesoftware.com"
    gem.homepage = "http://github.com/pangloss/pacer"
    gem.authors = ["Darrick Wiebe"]
    gem.license = "MIT"
    gem.add_dependency "nokogiri", "~> 1.4"
    gem.add_development_dependency "rspec", "~> 2.1"
    gem.add_development_dependency "rr", "~> 1.0"
    gem.files = FileList['lib/**/*.rb', 'script/*', '[A-Z]*', 'spec/**/*', 'vendor/*'].to_a
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
  Jeweler::RubygemsDotOrgTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  puts "YARD not available. gem install yard"
end

if Config::CONFIG['host_os'] =~ /mswin/
  def jruby_path
    Pathname.new ENV['path'].split(';').grep(/jruby/).first
  end

  if jruby_path
    def jgem
      jruby_path.join('jgem.bat').to_s
    end

    file jgem do
      File.open(jgem, 'w') do |f|
        f.puts <<-EOF.gsub(/^\s*/, '')
          @ECHO OFF
          IF NOT "%~f0" == "~f0" GOTO :WinNT
          @"jruby" -S "jgem" %1 %2 %3 %4 %5 %6 %7 %8 %9
          GOTO :EOF
          :WinNT
          @"jruby" "%~dpn0" %*
        EOF
      end
    end
    task :install => jgem
    task :build => jgem
  end
end


require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

RSpec::Core::RakeTask.new(:rcov) do |spec|
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec
