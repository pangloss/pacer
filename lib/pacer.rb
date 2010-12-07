require 'java'
require 'pp'

module Pacer
  unless const_defined? :VERSION
    VERSION = '0.1.0'
    PATH = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    $:.unshift File.join(PATH, 'lib')

    unless require(File.join(PATH, 'vendor/pipes-0.2-SNAPSHOT-standalone.jar'))
      STDERR.puts "Please build the pipes library from tinkerpop.com and place the jar in the vendor folder of this library."
      exit 1
    end

    START_TIME = Time.now

    require File.join(PATH, 'vendor/blueprints-neo4j-adapter-0.1-SNAPSHOT-standalone.jar')
    require File.join(PATH, 'vendor/neo4j-lucene-index-0.2-1.2.M05.jar')
  end

  require 'pacer/graph'
  require 'pacer/pipes'
  require 'pacer/routes'
  require 'pacer/neo4j'
  require 'pacer/tg'
  require 'pacer/support'
  require 'pacer/utils'

  class << self
    attr_accessor :verbose

    # Returns the time pacer was last reloaded (or when it was started).
    def reload_time
      @reload_time || START_TIME
    end

    # Reload all Ruby modified files in the Pacer library. Useful for debugging
    # in the console. Does not do any of the fancy stuff that Rails reloading
    # does.  Certain types of changes will still require restarting the
    # session.
    def reload!
      require 'pathname'
      Pathname.new(__FILE__).parent.find do |path|
        if path.extname == '.rb' and path.mtime > reload_time
          puts path.to_s
          load path.to_s
        end
      end
      @reload_time = Time.now
    end

    # Set to true to prevent inspecting any route from printing
    # the matching elements to the screen.
    def hide_route_elements=(bool)
      @hide_route_elements = bool
    end

    def hide_route_elements
      @hide_route_elements
    end

    # Returns how many terminal columns we have.
    def columns
      @columns || 120
    end

    # Tell the graph how many terminal columns we have.
    def columns=(n)
      @columns = n
    end

    # Returns how many matching items should be displayed by #inspect before we
    # give up and display nothing but the route definition.
    def inspect_limit
      @inspect_limit || 500
    end

    # Alter the inspect limit.
    def inspect_limit=(n)
      @inspect_limit = n
    end

    def verbose?
      @verbose
    end

    def vertex?(element)
      element.is_a? com.tinkerpop.blueprints.pgm.Vertex
    end

    def edge?(element)
      element.is_a? com.tinkerpop.blueprints.pgm.Edge
    end

    def manual_index
      com.tinkerpop.blueprints.pgm.Index::Type::MANUAL
    end

    def automatic_index
      com.tinkerpop.blueprints.pgm.Index::Type::AUTOMATIC
    end
  end
end


