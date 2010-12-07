module Pacer
  import com.tinkerpop.blueprints.pgm.Graph

  module Graph
    attr_accessor :in_bulk_job

    def import(path)
      path = File.expand_path path
      begin
        stream = java.net.URL.new(path).open_stream
      rescue java.net.MalformedURLException
        stream = java.io.FileInputStream.new path
      end
      com.tinkerpop.blueprints.pgm.parser.GraphMLReader.input_graph self, stream
      true
    end

    def export(path)
      path = File.expand_path path
      stream = java.io.FileOutputStream.new path
      com.tinkerpop.blueprints.pgm.parser.GraphMLWriter.outputGraph self, stream
    end

    def bulk_job_size=(size)
      @bulk_job_size = size
    end

    def bulk_job_size
      @bulk_job_size || 5000
    end

    def in_bulk_job?
      @in_bulk_job
    end
  end
end

require 'pacer/graph/graph_mixin'
require 'pacer/graph/element_mixin'
require 'pacer/graph/vertex_mixin'
require 'pacer/graph/edge_mixin'
require 'pacer/graph/transactions'
