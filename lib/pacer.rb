if not defined?(JRUBY_VERSION) or JRUBY_VERSION =~ /^(0|1\.[0-5]|1\.6\.[0-3])/
  # NOTE: This is because JRuby 1.6.4 fixes a bug that made it impossible to
  # instantiate Java classes with a varargs constructor signature  with 0
  # arguments. Marko would not accept a patch to create a 0 args constructor to
  # work around the problem, therefore this version of Pacer will not work
  # under any older versions of JRuby. The oldest Pacer version that will work
  # is 0.8.1.
  raise Exception, 'Pacer >= 0.8.2 requires JRuby version 1.6.4 or higher. It is strongly recommended that you use the latest JRuby release.'
end

if RUBY_VERSION == '1.8.7'
  STDERR.puts <<WARNING
WARNING: Pacer is developed using JRuby in 1.9 mode. I recommend you
  restart JRuby in 1.9 mode, either with the --1.9 flag, or by
  defaulting to 1.9 mode by setting the environment variable
  JRUBY_OPTS=--1.9
WARNING
end

require 'java'
require 'pp'
require 'rubygems'

module Pacer
  unless const_defined? :PATH
    PATH = File.expand_path(File.join(File.dirname(__FILE__), '..'))
    lib_path = File.join(PATH, 'lib')
    $:.unshift lib_path unless $:.any? { |path| path == lib_path }
  end

  require 'pacer/version'

  if RUBY_VERSION =~ /^1.9/
    Enumerator = ::Enumerator
  else
    Enumerator = Enumerable::Enumerator
  end

  require JAR

  require 'pacer/exceptions'
  require 'pacer/graph'
  require 'pacer/pipes'
  require 'pacer/core'
  require 'pacer/routes'
  require 'pacer/wrappers'
  require 'pacer/route'
  require 'pacer/extensions'
  require 'pacer/blueprints'
  require 'pacer/support'
  require 'pacer/utils'
  require 'pacer/filter'
  require 'pacer/transform'
  require 'pacer/side_effect'

  class << self
    # A global place for pacer to put debug info if it's tucked deep in
    # its internals. Should typically not be used unless a mysterious
    # bug needs to be analyzed but that never really happens ;)
    attr_accessor :debug_info

    # Returns the time pacer was last reloaded (or when it was started).
    def reload_time
      if defined? @reload_time
        @reload_time
      else
        START_TIME
      end
    end

    # Reload all Ruby modified files in the Pacer library. Useful for debugging
    # in the console. Does not do any of the fancy stuff that Rails reloading
    # does.  Certain types of changes will still require restarting the
    # session.
    def reload!
      require 'pathname'
      Pathname.new(File.expand_path(__FILE__)).parent.find do |path|
        if path.extname == '.rb' and path.mtime > reload_time
          puts path.to_s
          load path.to_s
        end
      end
      clear_plugin_cache
      @reload_time = Time.now
    end

    # Set to true to prevent inspecting any route from printing
    # the matching elements to the screen.
    def hide_route_elements=(bool)
      @hide_route_elements = bool
    end

    # Returns whether elements should be displayed. Also yields,
    # temporarily setting the value to true to prevent a route
    # containing routes from printing the contained routes' elements or
    # going recursive if the route were to somehow contain itself.
    #
    # @todo don't use negative method names.
    #
    # @yield print elements while inside this block
    # @return [true, false] should you not print elemets?
    def hide_route_elements
      @hide_route_elements = nil unless defined? @hide_route_elements
      if block_given?
        if @hide_route_elements
          yield
        else
          begin
            @hide_route_elements = true
            yield
          ensure
            @hide_route_elements = false
          end
        end
      else
        @hide_route_elements
      end
    end

    # Returns how many terminal columns we have.
    # @return [Fixnum] number of terminal columns
    def columns
      if defined? @columns
        @columns
      else
        150
      end
    end

    # Tell Pacer how many terminal columns we have so it can print
    # elements out in nice columns.
    # @param [Fixnum] n number of terminal columns
    def columns=(n)
      @columns = n
    end

    # Returns how many matching items should be displayed by #inspect before we
    # give up and display nothing but the route definition.
    # @return [Fixnum] maximum number of elements to display
    def inspect_limit
      if defined? @inspect_limit
        @inspect_limit
      else
        500
      end
    end

    # Set the maximum number of elements to print on the screen when
    # inspecting a route.
    # @param [Fixnum] n maximum number of elements to display
    def inspect_limit=(n)
      @inspect_limit = n
    end

    # Set Pacer's general verbosity.
    # @param [:very, true, false] default is true, :very is more
    #   verbose, false is quiet
    def verbose=(v)
      @verbose = v
    end

    # Current verbosity setting
    # @return [:very, true, false]
    def verbose?
      @verbose = nil unless defined? @verbose
      @verbose = true if @verbose.nil?
      @verbose
    end
    alias verbose verbose?

    # Clear all cached data that may become invalid when {#reload!} is
    # called.
    #
    # @todo reimpliment as callbacks to keep the code all in one place.
    def clear_plugin_cache
      Wrappers::VertexWrapper.clear_cache
      Wrappers::EdgeWrapper.clear_cache
      Route::Helpers.clear_cache
    end

    # Is the object a vertex?
    def vertex?(element)
      element.is_a? Pacer::Vertex or
        (element.respond_to? :element and
         element.element.is_a? Pacer::Vertex)
    end

    # Is the object an edge?
    def edge?(element)
      element.is_a? Pacer::Edge
        (element.respond_to? :element and
         element.element.is_a? Pacer::Edge)
    end

    def vertex_route?(obj)
      obj.is_a? Pacer::Core::Graph::VerticesRoute
    end
    alias vertices_route? vertex_route?

    def edge_route?(obj)
      obj.is_a? Pacer::Core::Graph::EdgesRoute
    end
    alias edges_route? edge_route?

    # Blueprints constant for manual index.
    # @return [com.tinkerpop.blueprints.pgm.Index::Type::MANUAL]
    def manual_index
      com.tinkerpop.blueprints.pgm.Index::Type::MANUAL
    end

    # Blueprints constant for automatic index.
    # @return [com.tinkerpop.blueprints.pgm.Index::Type::AUTOMATIC]
    def automatic_index
      com.tinkerpop.blueprints.pgm.Index::Type::AUTOMATIC
    end

    # If a pipe is giving you trouble, you can get all of the
    # intermediate pipes by using this method.
    #
    # @example how to use it:
    #   Pacer.debug_pipe(graph.v.out_e)
    #
    # Each returned pipe can be iterated with it's #next method to see
    # what it would have returned if it were the end pipe.
    #
    # @return [[java.util.Iterator, Array<Hash>, com.tinkerpop.pipes.Pipe]]
    #   the iterator is the data source. Each Hash in the array is
    #   information about one pipe in the pipeline that was created.
    #   These are in order of creation, not necessarily of attachment.
    #   However the hash will contain what pipe was used as the source
    #   for the given pipe along with all arguments used to create the
    #   pipe as well as other information if it seemed useful.
    def debug_pipe(pipe)
      @debug_pipes = []
      result = pipe.send :iterator
      [debug_source, debug_pipes, result]
    end

    def debug_pipe!
      @debug_pipes = []
    end

    # All of the currently open graphs that are tied to the filesystem
    # or a url or address.
    # @return [Hash] address => graph
    def open_graphs
      @open_graphs = Hash.new { |h, k| h[k] = {} } unless defined? @open_graphs
      @open_graphs
    end

    # Tell pacer to record that we're starting a graph.
    #
    # @param [Class] type type of graph
    # @param [String] key address of the graph
    # @yield the block should return the instantiated graph.
    # @return [GraphMixin] the instantiated graph
    def starting_graph(type, key)
      graph = open_graphs[type][key]
      return graph if graph
      graph = yield
      open_graphs[type][key] = graph
    end

    # Used internally to collect debug information while using
    # {#debug_pipe}
    attr_accessor :debug_source
    # Used internally to collect debug information while using
    # {#debug_pipe}
    attr_reader :debug_pipes
  end
end

at_exit do
  # Close all open graphs
  Pacer.open_graphs.each do |type, graphs|
    graphs.each do |path, graph|
      begin
        graph.shutdown
      rescue Exception, StandardError => e
        pp e
      end
    end
  end
end
