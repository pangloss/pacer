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

def for_each_graph(tx = true, &block)
  for_tg(tx, &block)
  for_neo4j(tx, &block)
end

def for_tg(tx = nil, &block)
  describe 'tg' do
    let(:supports_custom_id) { true }
    let(:graph) { Pacer.tg }
    let(:graph2) { Pacer.tg }
    instance_eval(&block)
  end
end

def for_neo4j(tx = true, &block)
  describe 'neo4j' do
    let(:supports_custom_id) { false }
    let(:graph) do
      $neo_graph
    end
    let(:graph2) do
      $neo_graph2
    end
    if tx
      around do |spec|
        $neo_graph.v.delete!
        $neo_graph2.v.delete!
        graph.manual_transactions do
          graph2.manual_transactions do
            begin
              graph.start_transaction
              graph2.start_transaction
              spec.call
            ensure
              graph.rollback_transaction rescue nil
              graph2.rollback_transaction rescue nil
            end
          end
        end
      end
    else
      before do
        $neo_graph.v.delete!
        $neo_graph2.v.delete!
      end
    end
    instance_eval(&block)
  end
end

RSpec.configure do |c|
  c.color_enabled = !in_editor?
  c.filter_run :focus => true
  c.run_all_when_everything_filtered = true
  Pacer.hide_route_elements = true
  Pacer.verbose = false
  c.mock_with :rr

  c.before(:suite) do
    puts 'before suite'
    # Make sure these instance variables exist in the correct scope
    path1 = File.expand_path('tmp/spec.neo4j')
    dir = Pathname.new(path1)
    dir.rmtree if dir.exist?
    $neo_graph = Pacer.neo4j(path1)

    path2 = File.expand_path('tmp/spec.neo4j.2')
    dir = Pathname.new(path2)
    dir.rmtree if dir.exist?
    $neo_graph2 = Pacer.neo4j(path2)
  end


  c.alias_it_should_behave_like_to :it_uses, ':'

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

