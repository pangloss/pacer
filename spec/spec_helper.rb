require 'rspec'
require 'pacer'
require 'set'
require 'json'

Dir['./spec/support/**/*.rb'].map {|f| require f}
Dir['./spec/tackle/*.rb'].map {|f| require f}

include Pacer::Routes

class RSpec::Core::ExampleGroup
  def self.run_all(reporter=nil)
    run(reporter || NullObject.new)
  end
end

def in_editor?
  ENV.has_key?('TM_MODE') || ENV.has_key?('EMACS') || ENV.has_key?('VIM')
end

require 'pacer-neo4j'
require 'pacer-dex'

Run = Rspec::GraphRunner.new ENV['GRAPHS']

def use_simple_graph_data
  let(:setup_data) { e0; e1 }
  let(:v0) { graph.create_vertex :name => 'eliza' }
  let(:v1) { graph.create_vertex :name => 'darrick' }
  let(:e0) { graph.create_edge nil, v0, v1, :links }
  let(:e1) { graph.create_edge nil, v0, v1, :relinks }
end

def use_pacer_graphml_data(usage_style = :read_write)
  if usage_style == :read_only
    let(:setup_data) { }
    before(:all) do
      graph.import 'spec/data/pacer.graphml' if graph
    end
  else
    let(:setup_data) do
      graph.import 'spec/data/pacer.graphml' if graph
    end
  end
  let(:pangloss) { graph.v(:name => 'pangloss', :type => 'person').first }
  let(:pacer) { graph.v(:name => 'pacer', :type => 'project').first }
  let(:people) { graph.v(:type => 'person') }
  let(:pangloss_wrote_pacer) { pangloss.out_e(:wrote) { |e| e.in_vertex == pacer } }
end

def use_grateful_dead_data(usage_style = :read_write)
  if usage_style == :read_only
    let(:setup_data) { }
    before(:all) do
      graph.import 'spec/data/grateful-dead.xml' if graph
    end
  else
    let(:setup_data) do
      graph.import 'spec/data/grateful-dead.xml' if graph
    end
  end
end

RSpec.configure do |c|
  c.color_enabled = !in_editor?
  c.filter_run :focus => true
  c.run_all_when_everything_filtered = true
  Pacer.hide_route_elements = true
  Pacer.verbose = false
  c.mock_with :rr

  c.alias_it_should_behave_like_to :it_uses, '-'

  puts "Using JRuby #{ JRUBY_VERSION } in #{ RUBY_VERSION } mode."
  puts Run.inspect

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
