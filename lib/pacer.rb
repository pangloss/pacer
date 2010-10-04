require 'java'
require 'pp'

module Pacer
  VERSION = '0.1.0'
  PATH = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  $:.unshift File.join(PATH, 'lib')
  require File.join(PATH, 'vendor/pipes-0.1-SNAPSHOT-standalone.jar')

  require 'pacer/graph'
  require 'pacer/pipe'
  require 'pacer/route'
  require 'pacer/neo4j'

  def self.reload!
    Dir[File.join(PATH, '**/*.rb')].each { |file| load file }
  end
end


