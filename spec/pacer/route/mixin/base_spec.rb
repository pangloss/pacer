require 'spec_helper'

# TODO: hopefully this block can be removed as the test suite is fleshed out
for_each_graph(:read_only) do
  describe Pacer::Routes::Base do
    use_pacer_graphml_data(:read_only)
    before { setup_data }
    describe '#inspect' do
      it 'should show the path in the resulting string' do
        other_projects_by_gremlin_writer = 
          graph.v(:name => 'gremlin').as(:grem).in_e(:wrote).out_v.out_e(:wrote) { |e| true }.in_v.except(:grem)
        other_projects_by_gremlin_writer.inspect.should ==
          '#<IndexedVertices -> :grem -> Edges(IN_EDGES, [:wrote]) -> Vertices(OUT_VERTEX) -> Edges(OUT_EDGES, [:wrote], &block) -> Vertices(IN_VERTEX) -> Vertices(&block)>'
      end
    end

    describe '#to_a' do
      it { Set[*graph.v].should == Set[*graph.vertices] }
      it { Set[*(graph.v.to_a)].should == Set[*graph.vertices] }
      it { Set[*graph.e].should == Set[*graph.edges] }
      it { Set[*(graph.e.to_a)].should == Set[*graph.edges] }
    end

    describe '#root?' do
      it { graph.should be_root }
      it { graph.v.should be_root }
      it { graph.v[3].should_not be_root }
      it { graph.v.out_e.should_not be_root }
      it { graph.v.out_e.in_v.should_not be_root }
    end

    describe 'property filter' do
      it { graph.v(:name => 'pacer').to_a.should == [pacer] }
      it { graph.v(:name => 'pacer').count.should == 1 }
    end

    describe 'block filter' do
      it { graph.v { false }.count.should == 0 }
      it { graph.v { true }.count.should == graph.v.count }
      it { graph.v { |v| v.out_e.none? }[:name].to_a.should == ['blueprints'] }

      it 'should work with paths' do
        paths = graph.v.out_e(:wrote).in_v.paths.map(&:to_a)
        filtered_paths = graph.v { true }.out_e(:wrote).e { true }.in_v.paths.map(&:to_a)
        filtered_paths.should == paths
      end
    end

    describe '#result' do
      context 'no matching vertices' do
        subject { graph.v(:name => 'missing').result }
        it { should be_a(VerticesRouteModule) }
        its(:count) { should == 0 }
      end

      it 'should not be nil when no matching vertices' do
        empty = graph.v(:name => 'missing').result
        empty.should be_a(VerticesRouteModule)
        empty.count.should == 0
      end

      it 'should not be nil when no matching edges' do
        empty = graph.e(:missing).result
        empty.should be_a(EdgesRouteModule)
        empty.count.should == 0
      end

      it 'should not be nil when no matching mixed results' do
        empty = graph.v.branch { |x| x.out_e(:missing) }.branch { |x| x.out_e(:missing) }
        empty.should be_a(MixedRouteModule)
        empty.count.should == 0
      end
    end
  end
end

# These specs are :read_only
shared_examples_for Pacer::Routes::Base do
  # defaults -- you
  let(:route) { raise 'define a route' }
  let(:number_of_results) { raise 'how many results are expected' }
  let(:result_type) { raise 'specify :vertex, :edge, :mixed or :object' }
  let(:back) { nil }
  let(:info) { nil }

  context 'without data' do
    subject { route }
    it { should be_a(Pacer::Routes::Base) }
    its(:graph) { should equal(graph) }
    its(:back) { should equal(back) }
    its(:info) { should == info }
    context 'with info' do
      before { route.info = 'some info' }
      its(:info) { should == 'some info' }
      after { route.info = nil }
    end
    its(:vars) { should be_a(Hash) }

    describe '#from_graph?' do
      context 'current graph' do
        subject { route.from_graph? graph }
        it { should be_true }
      end
      context 'other graph' do
        subject { route.from_graph? graph2 }
        it { should be_false }
      end
    end

    describe '#each' do
      it { route.each.should be_a(java.util.Iterator) }
    end

    describe '#result' do
      before { graph.checkpoint }
      subject { route.result }
      it { should be_root }
      its(:element_type) { should == route.element_type }
    end

  end

  context 'with data' do
    around do |spec|
      if number_of_results > 0
        setup_data
        spec.run
      end
    end

    let(:first_element) { route.first }
    let(:all_elements) { route.to_a }

    describe '#[Fixnum]' do
      subject { route[number_of_results - 1] }
      it { should be_a(Pacer::Routes::Base) }
      its(:count) { should == 1 }
      its(:result) { should be_a(graph.element_type(result_type)) }
    end

    describe '#result' do
      subject { route.result }
      it { should be_a(Pacer::Routes::Base) }
      its(:count) { should == number_of_results }
    end

    describe '#route' do
      subject { route.route }
      its(:hide_elements) { should be_true }
      it { should equal(route) }
    end

    describe '#first' do
      subject { route.first }
      it { should_not be_nil }
      its(:graph) { should equal(graph) }
      its(:extensions) { should == route.extensions }
    end

    describe '#to_a' do
      subject { route.to_a }
      its(:count) { should == number_of_results }
      it { should be_a(Array) }
    end

    describe '#except' do
      context '(first_element)' do
        subject { route.except(first_element) }
        it { should_not include(first_element) }
      end
      context '(all_elements)' do
        subject { route.except(all_elements) }
        its(:count) { should == 0 }
      end
    end

    describe '#only' do
      subject { route.only(first_element).uniq }
      its(:to_a) { should == [first_element] }
    end
  end

  context 'without data' do
    around do |spec|
      if number_of_results == 0
        setup_data
        spec.run
      end
    end

    describe '#[Fixnum]' do
      subject { route[0] }
      it { should be_a(Pacer::Routes::Base) }
      its(:count) { should == 0 }
      its(:result) { should be_a(Pacer::Routes::Base) }
    end

    describe '#result' do
      subject { route.result }
      it { should be_a(Pacer::Routes::Base) }
      its(:count) { should == number_of_results }
    end

    describe '#route' do
      subject { route.route }
      its(:hide_elements) { should be_true }
      it { should equal(route) }
    end

    describe '#first' do
      subject { route.first }
      it { should be_nil }
    end

    describe '#to_a' do
      subject { route.to_a }
      its(:count) { should == number_of_results }
      it { should be_a(Array) }
    end
  end
end

for_each_graph(:read_only) do
  use_pacer_graphml_data(:read_only)
  context 'vertices' do
    it_uses Pacer::Routes::Base do
      let(:route) { graph.v }
      let(:number_of_results) { 7 }
      let(:result_type) { :vertex }
    end
  end
  context 'no vertices' do
    it_uses Pacer::Routes::Base do
      let(:route) { graph.v(:something => 'missing') }
      let(:number_of_results) { 0 }
      let(:result_type) { :vertex }
    end
  end
  context 'edges' do
    it_uses Pacer::Routes::Base do
      let(:route) { graph.e }
      let(:number_of_results) { 14 }
      let(:result_type) { :edge }
    end
  end
end
