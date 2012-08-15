module Pacer
  # Methods to be mixed into Blueprints Graph objects from any
  # implementation.
  #
  # Adds more convenient/rubyish methods and adds support for extensions
  # to some methods where needed.
  class GraphML
    # Import the data in a GraphML file.
    #
    # Will fail if the data already exsts in the current graph.
    #
    # @param [String] path
    def self.import(graph, path)
      path = File.expand_path path
      begin
        stream = java.net.URL.new(path).open_stream
      rescue java.net.MalformedURLException
        stream = java.io.FileInputStream.new path
      end
      graph.send :creating_elements do
        com.tinkerpop.blueprints.util.io.graphml.GraphMLReader.input_graph graph.blueprints_graph, stream
      end
      true
    ensure
      stream.close if stream
    end

    # Export the graph to GraphML
    #
    # @param [String] path will be replaced if it exists
    def self.export(graph, path)
      path = File.expand_path path
      stream = java.io.FileOutputStream.new path
      com.tinkerpop.blueprints.util.io.graphml.GraphMLWriter.outputGraph graph.blueprints_graph, stream
    ensure
      stream.close if stream
    end
  end
end
