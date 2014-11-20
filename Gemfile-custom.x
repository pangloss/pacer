group :development do
  # pacer-* gems are required for testing pacer.
  # If you have the gem repos cloned locally, we'll use them.
  #
  # Note: when testing orient, use the jruby --headless option to prevent the ui window BS.
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

  neo_test_ver = ENV.fetch('neo') do
    if File.directory?("../pacer-neo4j2")
      '2'
    elsif File.directory?("../pacer-neo4j")
      '1'
    else
      '0'
    end
  end
  if neo_test_ver == '1'
    gem 'pacer-neo4j', :path => "../pacer-neo4j"
  elsif neo_test_ver == '2'
    gem 'pacer-neo4j2', :path => "../pacer-neo4j2"
  end

  if File.directory? "../mcfly"
    gem 'pacer-mcfly', :path => "../mcfly" 
  end
end
