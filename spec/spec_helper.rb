require 'rspec'
require 'pacer'
require 'set'

Dir['./spec/support/**/*.rb'].map {|f| require f}
Dir['./spec/tackle/*.rb'].map {|f| require f}

include Pacer::Routes

module RSpec
  module Core
    module Matchers
      def fail
        raise_error(::RSpec::Expectations::ExpectationNotMetError)
      end

      def fail_with(message)
        raise_error(::RSpec::Expectations::ExpectationNotMetError, message)
      end

    end

    module SharedExampleGroup
      def contexts(ctxts, &block)
        ctxts.each do |name, setup_proc|
          context(*[*name]) do
            instance_eval &setup_proc
            instance_eval &block
          end
        end
      end
    end

    class Example
      module ProcsyTransactions
        def use_transactions?
          find_metadata(metadata, :transactions) != false
        end

        def find_metadata(hash, key)
          return unless hash.is_a? Hash
          if hash.key? key
            hash[key]
          elsif hash.key? :example_group
            find_metadata(hash[:example_group], key)
          end
        end
      end

      if not defined? Procsy or Procsy.class == Module
        # RSpec version >= '2.5.0'
        module Procsy
          include ProcsyTransactions
        end
      else
        class Procsy
          include ProcsyTransactions
        end
      end
    end

  end
end

class RSpec::Core::ExampleGroup
  def self.run_all(reporter=nil)
    run(reporter || NullObject.new)
  end
end

def in_editor?
  ENV.has_key?('TM_MODE') || ENV.has_key?('EMACS') || ENV.has_key?('VIM')
end

def for_each_graph(usage_style = :read_write, indices = true, &block)
  for_tg(usage_style, indices, &block)
  for_neo4j(usage_style, indices, &block)
  for_dex(usage_style, indices, &block)
end

def use_graph?(name)
  if ENV['GRAPHS'].to_s == ''
    true
  else
    graphs = ENV['GRAPHS'].downcase.split(/\s*,\s*/)
    graphs.include? name
  end
end

def for_tg(usage_style = :read_write, indices = true, &block)
  return unless use_graph? 'tg'
  describe 'tg' do
    let(:supports_custom_id) { true }
    let(:graph) do
      g = Pacer.tg
      unless indices
        g.drop_index :vertices
        g.drop_index :edges
      end
      g
    end
    let(:graph2) { Pacer.tg }
    instance_eval(&block)
  end
end


def for_graph(name, usage_style, indices, transactions, source_graph_1, source_graph_2, unindexed_graph, block)
  return unless use_graph? name
  describe name do
    let(:supports_custom_id) { false }
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
        source_graph_1.v.delete!
        source_graph_2.v.delete!
        unindexed_graph.v.delete! if unindexed_graph
      end
    end
    around do |spec|
      if usage_style == :read_write
        source_graph_1.v.delete!
        source_graph_2.v.delete!
        unindexed_graph.v.delete! if unindexed_graph
      end
      if transactions and spec.use_transactions?
        graph.manual_transactions do
          graph2.manual_transactions do
            begin
              graph.begin_transaction
              graph2.begin_transaction
              spec.run
            ensure
              graph.rollback_transaction rescue nil
              graph2.rollback_transaction rescue nil
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

def for_neo4j(usage_style = :read_write, indices = true, &block)
  for_graph('neo4j', usage_style, indices, true, $neo_graph, $neo_graph2, $neo_graph_no_indices, block)
end

def for_dex(usage_style = :read_write, indices = true, &block)
  for_graph('dex', usage_style, indices, false, $dex_graph, $dex_graph2, nil, block)
end

def use_simple_graph_data
  let(:setup_data) { e0; e1 }
  let(:v0) { graph.create_vertex :name => 'eliza' }
  let(:v1) { graph.create_vertex :name => 'darrick' }
  let(:e0) { graph.create_edge nil, v0, v1, :links }
  let(:e1) { graph.create_edge nil, v0, v1, :relinks }
end

def use_pacer_graphml_data(usage_style = :read_write, version = '')
  if usage_style == :read_only
    let(:setup_data) { }
    before(:all) do
      graph.import 'spec/data/pacer.graphml'
    end
  else
    let(:setup_data) do
      graph.import 'spec/data/pacer.graphml'
    end
  end
  let(:pangloss) { graph.v(:name => 'pangloss', :type => 'person').first }
  let(:pacer) { graph.v(:name => 'pacer', :type => 'project').first }
  let(:people) { graph.v(:type => 'person') }
  let(:pangloss_wrote_pacer) { pangloss.out_e(:wrote) { |e| e.in_vertex == pacer } }
end

RSpec.configure do |c|
  c.color_enabled = !in_editor?
  c.filter_run :focus => true
  c.run_all_when_everything_filtered = true
  Pacer.hide_route_elements = true
  Pacer.verbose = false
  c.mock_with :rr

  c.alias_it_should_behave_like_to :it_uses, '-'

  # Not sure what this does: ...
  # c.filter_run_excluding :ruby => lambda {|version|
  #   case version.to_s
  #   when "!jruby"
  #     RUBY_ENGINE != "jruby"
  #   when /^> (.*)/
  #     !(RUBY_VERSION.to_s > $1)
  #   else
  #     !(RUBY_VERSION.to_s =~ /^#{version.to_s}/)
  #   end
  # }
end

puts "Using JRuby #{ JRUBY_VERSION } in #{ RUBY_VERSION } mode."
if ENV['GRAPHS'].to_s == ''
  puts "Testing all graphs."
else
  puts "Testing graphs: #{ ENV['GRAPHS'] }."
end
if use_graph?('neo4j')
  path1 = File.expand_path('tmp/spec.neo4j')
  dir = Pathname.new(path1)
  dir.rmtree if dir.exist?
  $neo_graph = Pacer.neo4j(path1)

  path2 = File.expand_path('tmp/spec.neo4j.2')
  dir = Pathname.new(path2)
  dir.rmtree if dir.exist?
  $neo_graph2 = Pacer.neo4j(path2)

  path3 = File.expand_path('tmp/spec_no_indices.neo4j')
  dir = Pathname.new(path3)
  dir.rmtree if dir.exist?
  $neo_graph_no_indices = Pacer.neo4j(path3)
  $neo_graph_no_indices.drop_index :vertices
  $neo_graph_no_indices.drop_index :edges
end
if use_graph?('dex')
  path1 = File.expand_path('tmp/spec.dex')
  dir = Pathname.new(path1)
  dir.rmtree if dir.exist?
  $dex_graph = Pacer.dex(path1)

  path2 = File.expand_path('tmp/spec.dex.2')
  dir = Pathname.new(path2)
  dir.rmtree if dir.exist?
  $dex_graph2 = Pacer.dex(path2)
end
