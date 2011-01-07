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
      class Procsy
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

def for_each_graph(&block)
  for_tg(&block)
  for_neo4j(&block)
end

def for_tg(&block)
  describe 'tg' do
    let(:supports_custom_id) { true }
    let(:graph) { Pacer.tg }
    let(:graph2) { Pacer.tg }
    instance_eval(&block)
  end
end


def for_neo4j(&block)
  describe 'neo4j' do
    let(:supports_custom_id) { false }
    let(:graph) do
      $neo_graph
    end
    let(:graph2) do
      $neo_graph2
    end
    around do |spec|
      $neo_graph.v.delete!
      $neo_graph2.v.delete!
      if spec.use_transactions?
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

def use_simple_graph_data
  let(:v0) { graph.create_vertex :name => 'eliza' }
  let(:v1) { graph.create_vertex :name => 'darrick' }
  let(:e0) { graph.create_edge nil, v0, v1, :links }
  let(:e1) { graph.create_edge nil, v0, v1, :relinks }
end

RSpec.configure do |c|
  c.color_enabled = !in_editor?
  c.filter_run :focus => true
  c.run_all_when_everything_filtered = true
  Pacer.hide_route_elements = true
  Pacer.verbose = false
  c.mock_with :rr

  c.before(:suite) do
    path1 = File.expand_path('tmp/spec.neo4j')
    dir = Pathname.new(path1)
    dir.rmtree if dir.exist?
    $neo_graph = Pacer.neo4j(path1)

    path2 = File.expand_path('tmp/spec.neo4j.2')
    dir = Pathname.new(path2)
    dir.rmtree if dir.exist?
    $neo_graph2 = Pacer.neo4j(path2)
  end


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

