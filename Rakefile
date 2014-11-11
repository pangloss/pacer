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

#==================================================

V = /(?<before>\s*VERSION\s*=\s*")(?<major>\d+)\.(?<minor>\d+)\.(?<point>\d+)(?:\.(?<pre>\w+))?(?<after>".*)/
VERSION_FILE = 'lib/pacer/version.rb'

def change_version(file = VERSION_FILE)
  f = File.read(file)
  lines = f.each_line.map do |line|
    match = V.match line
    if match
      yield line, match[:before], match[:major], match[:minor], match[:point], match[:pre], match[:after]
    else
      line
    end
  end
  File.open(file, 'w') do |f|
    f.puts lines.join
  end
end

task :stable do
  change_version do |line, before, major, minor, point, pre, after|
    if pre
      "#{before}#{major}.#{minor}.#{point}#{after}\n"
    else
      "#{before}#{major}.#{minor}.#{point.next}#{after}\n"
    end
  end
end

task :pre do
  change_version do |line, before, major, minor, point, pre, after|
    if pre
      line
    else
      "#{before}#{major}.#{minor}.#{point.next}.pre#{after}\n"
    end
  end
end

task :is_clean do
  sh "git status | grep 'working directory clean'"
end

task :is_on_master do
  sh "git status | grep 'On branch master'"
end

task :is_up_to_date do
  sh "git pull | grep 'Already up-to-date.'"
end

task :is_stable_version do
  load VERSION_FILE
  unless Pacer::VERSION =~ /^\d+\.\d+\.\d+$/
    fail "Not on a stable version: #{ Pacer::VERSION }"
  end
end

task :prepare_release_push => [:is_clean, :is_on_master, :is_up_to_date, :stable]

task :_only_push_release do
  load VERSION_FILE
  sh "git add #{VERSION_FILE} && git commit -m 'Version #{ Pacer::VERSION }' && git push"
end

task :only_push_release => [:prepare_release_push, :_only_push_release]

task :next_dev_cycle => [:pre, :is_clean] do
  load VERSION_FILE
  sh "git add #{VERSION_FILE} && git commit -m 'New development cycle with version #{ Pacer::VERSION }'"
end

task :push_release => [:only_push_release, :next_dev_cycle]

task :release => [:is_clean, :is_on_master, :is_stable_version] 
