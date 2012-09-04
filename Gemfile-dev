# A sample Gemfile
source "http://rubygems.org"

gemspec

group :development do
  gem 'rspec', '~> 2.10.0'
  gem 'rr', '~> 1.0'
  gem 'simplecov'
  gem 'yard'
  gem 'rake'

  # pacer-* gems are required for testing pacer.
  # If you have the gem repos cloned locally, we'll use them.
  #
  libs = [
    ['pacer-neo4j', '2.0.0.pre'],
    ['pacer-orient', '2.0.0.pre'],
    ['pacer-dex', '2.0.0.pre']
  ] 
  libs.each do |lib, version|
    if File.directory? "../#{lib}"
      gem lib, :path => "../#{lib}" 
    end
  end

   
  gem 'autotest-standalone'
  gem 'autotest-growl'
  gem 'pry'
  gem 'awesome_print', '0.4.0'
end

