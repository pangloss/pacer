require 'pacer-neo4j/rspec'

class RSpec::GraphRunner
  module Stubs
    def all(*args)
    end

    def tg(*args)
    end

    def neo4j(*args)
    end

    def rg(*args)
    end

    def multigraph(*args)
    end

    def dex(*args)
    end

    def orient(*args)
    end
  end

  module Tg
    def all(usage_style = :read_write, indices = true, &block)
      tg(usage_style, indices, &block)
    end

    def tg(usage_style = :read_write, indices = true, &block)
      return unless use_graph? 'tg'
      describe 'tg' do
        let(:graph) { Pacer.tg }
        let(:graph2) { Pacer.tg }
        instance_eval(&block)
      end
    end
  end

  module RubyGraph
    def all(usage_style = :read_write, indices = true, &block)
      super
      rg(usage_style, indices, &block)
    end

    def rg(usage_style = :read_write, indices = true, &block)
      for_graph('rg', usage_style, indices, false, ruby_graph, ruby_graph2, nil, block)
    end

    protected

    def ruby_graph
      Pacer::PacerGraph.new Pacer::RubyGraph.new, Pacer::SimpleEncoder
    end

    def ruby_graph2
      Pacer::PacerGraph.new Pacer::RubyGraph.new, Pacer::SimpleEncoder
    end
  end

  module MultiGraph
    def all(usage_style = :read_write, indices = true, &block)
      super
      multigraph(usage_style, indices, &block)
    end

    def multigraph(usage_style = :read_write, indices = true, &block)
      for_graph('multigraph', usage_style, indices, false, multi_graph, multi_graph2, nil, block)
    end

    protected

    def multi_graph
      Pacer::MultiGraph.blank
    end

    def multi_graph2
      Pacer::MultiGraph.blank
    end
  end


  include Stubs
  include Tg
  include RubyGraph
  include MultiGraph
  include Neo4j
  #include Dex
  #include Orient

  def initialize(*graphs)
    @graphs = graphs.map { |s| s.to_s.downcase.split(/\s*,\s*/) }.flatten.map { |s| s.strip }.reject { |s| s == '' }
  end

  def inspect
    if @graphs.empty?
      "Testing all graphs."
    else
      "Testing graphs: #{ @graphs.join ', ' }."
    end
  end

  def use_graph?(name)
    if @graphs.empty?
      true
    else
      @graphs.include? name
    end
  end

protected

  def for_graph(name, usage_style, indices, transactions, source_graph_1, source_graph_2, unindexed_graph, block)
    return unless use_graph? name
    clear_graph = proc { |g| clear g }
    describe name do
      let(:graph) do
        if indices
          source_graph_1
        else
          unindexed_graph
        end
      end
      let(:graph2) do
        source_graph_2
      end
      if usage_style == :read_only
        before(:all) do
          if indices
            clear_graph.call source_graph_1
          elsif unindexed_graph
            clear_graph.call unindexed_graph
          end
          clear_graph.call source_graph_2
        end
      end
      around do |spec|
        if usage_style == :read_write
          if indices
            clear_graph.call source_graph_1
          elsif unindexed_graph
            clear_graph.call unindexed_graph
          end
          clear_graph.call source_graph_2
        end
        if transactions and spec.use_transactions?
          graph.transaction do |g1_commit, g1_rollback|
            graph2.transaction do |_, g2_rollback|
              spec.metadata[:graph_commit] = g1_commit
              begin
                spec.run
              ensure
                g1_rollback.call rescue nil
                g2_rollback.call rescue nil
              end
            end
          end
        else
          spec.run
        end
      end
      instance_eval(&block)
    end
  end

  def clear(graph)
    graph.transaction do
      graph.blueprints_graph.getVertices.each do |v|
        begin
          graph.remove_vertex v
        rescue
        end
      end
      graph.indices.each do |idx|
        graph.drop_index idx.index_name
      end
    end
    #if graph.v.any?
    #  fail "Graph still has vertices"
    #elsif graph.e.any?
    #  fail "Graph still has edges"
    #elsif graph.indices.any?
    #  fail "Graph still has indices"
    #elsif graph.key_indices.any?
    #  fail "Graph still has key indices"
    #end
  end
end

