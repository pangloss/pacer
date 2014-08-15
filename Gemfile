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
  [ 'pacer-orient', 'pacer-dex' ].each do |lib|
    if File.directory? "../#{lib}"
      gem lib, :path => "../#{lib}" 
    end
  end

  # Neo4j versions are mutually incompatible
  # To test Pacer against Neo4j 1.x when the neo2 gem is present, use:
  #
  #   neo=1 bundle
  #   rspec
  #
  # To switch back, just use:
  #
  #   bundle
  #   rspec
  #
  if File.directory? "../pacer-neo4j" and (ENV['neo'] == '1' or not File.directory? "../pacer-neo4j2")
    gem 'pacer-neo4j', :path => "../pacer-neo4j"
  end

  if File.directory? "../pacer-neo4j2" and ENV['neo'] != '1' 
    gem 'pacer-neo4j2', :path => "../pacer-neo4j2"
  end

  if File.directory? "../mcfly"
    gem 'pacer-mcfly', :path => "../mcfly" 
  end


   
  gem 'autotest-standalone'
  gem 'autotest-growl'
  gem 'pry'
  gem 'awesome_print', '0.4.0'
end

