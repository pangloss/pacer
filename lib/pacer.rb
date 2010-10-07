require 'java'
require 'pp'

module Pacer
  unless defined? VERSION
    VERSION = '0.1.0' 
    PATH = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    $:.unshift File.join(PATH, 'lib')
  end

  require File.join(PATH, 'vendor/pipes-0.1-SNAPSHOT-standalone.jar')

  require 'pacer/graph'
  require 'pacer/pipes'
  require 'pacer/routes'
  require 'pacer/neo4j'
  require 'pacer/tg'

  def self.reload!
    Dir[File.join(PATH, 'lib/**/*.rb')].each { |file| load file }
    true
  end
end


