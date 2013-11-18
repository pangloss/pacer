# A sample Gemfile
source "http://rubygems.org"

gemspec

group :development do
  gem 'rspec', '~> 2.10.0'
  gem 'rr', '~> 1.0'
  gem 'simplecov'
  gem 'rake'

  # pacer-* gems are required for testing pacer.
  # If you have the gem repos cloned locally, we'll use them.
  #
  [ 'pacer-neo4j', 'pacer-orient', 'pacer-dex'].each do |lib|
    if File.directory? "../#{lib}"
      gem lib, :path => "../#{lib}" 
    end
  end

  if File.directory? "../mcfly"
    gem 'pacer-mcfly', :path => "../mcfly" 
  end


   
  gem 'autotest-standalone'
  gem 'autotest-growl'
  gem 'pry'
  gem 'awesome_print', '0.4.0'
end

