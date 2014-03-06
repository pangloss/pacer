maybe_require 'pacer-neo4j/rspec'
maybe_require 'pacer-orient/rspec'
maybe_require 'pacer-dex/rspec'
maybe_require 'pacer-mcfly/rspec'

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

    def mcfly(*args)
    end
  end

  module Tg
    def all(usage_style = :read_write, indices = true, &block)
      tg(usage_style, indices, &block)
    end

    def tg(usage_style = :read_write, indices = true, &block)
      return unless use_graph? 'tg'
      describe 'tg' do
        let(:graph_name) { 'tg' }
        let(:graph) { Pacer.tg }
        let(:graph2) { Pacer.tg }
        instance_eval(&block)
      end
    end
  end

  include Stubs
  include Tg
  include Neo4j if defined? Neo4j
  include Dex if defined? Dex
  include Orient if defined? Orient
  include McFly if defined? McFly

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

  def for_graph(name, usage_style, indices, transactions, source_graph_1, source_graph_2, unindexed_graph, block, clear_graph = nil)
    return unless use_graph? name
    clear_graph ||= proc { |g| clear g }
    describe name do
      let(:graph_name) { name }
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
        if graph and transactions and spec.use_transactions?
          graph.transaction do |g1_commit, g1_rollback|
            graph2.transaction do |g2_commit, g2_rollback|
              spec.metadata[:graph_commit] = g1_commit
              spec.metadata[:graph2_commit] = g2_commit
              begin
                spec.run
              ensure
                graph.drop_temp_indices
                graph2.drop_temp_indices
                begin
                  g1_rollback.call
                rescue Pacer::NestedTransactionRollback, Pacer::NestedMockTransactionRollback
                end
                begin
                  g2_rollback.call #rescue nil
                rescue Pacer::NestedTransactionRollback, Pacer::NestedMockTransactionRollback
                end
              end
            end
          end
        elsif graph and transactions and spec.use_read_transaction?
          graph.read_transaction do
            graph2.read_transaction do
              spec.run
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

