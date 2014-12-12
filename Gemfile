# A sample Gemfile
source "http://rubygems.org"

gemspec

group :development do
  gem 'rspec', '~> 2.10.0'
  gem 'rr', '~> 1.0'
  gem 'simplecov'
  gem 'rake'
  gem 'autotest-standalone'
  gem 'autotest-growl'
  gem 'awesome_print', '0.4.0'
  gem 'coveralls', require: false
  gem 'travis'
end


# Gemfile-custom is .gitignored, but eval'd here so you can add
# whatever dev tools you like to use to your local environment.
eval File.read('Gemfile-custom') if File.exist?('Gemfile-custom')
