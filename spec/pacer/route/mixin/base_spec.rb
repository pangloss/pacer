require 'spec_helper'

# TODO: hopefully this block can be removed as the test suite is fleshed out
for_each_graph do
  describe Pacer::Routes::Base do
    use_pacer_graphml_data
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
      it { graph.v.to_a.count.should == graph.vertices.count }
      it { graph.e.to_a.count.should == graph.edges.count }
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

shared_examples_for 'Route results' do
  context '#first' do
    subject { route.first }
    it { should_not be_nil }
    its(:graph) { should equal(graph) }
    its(:extensions) { should == route.extensions }
  end

end

shared_examples_for Pacer::Routes::Base do
  # defaults
  let(:back) { nil }
  let(:info) { nil }

  subject { route }
  it { should be_a(Pacer::Routes::Base) }
  its(:graph) { should equal(graph) }
  its(:back) { should equal(back) }
  its(:info) { should == info }
  context 'with info' do
    before { route.info = 'some info' }
    its(:info) { should == 'some info' }
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

  describe '#[]' do
    it { graph.v[2].count.should == 1 }
    it { graph.v[2].result.is_a?(Pacer::VertexMixin).should be_true }
  end

  describe '#each' do
    it { route.each.should be_a(java.util.Iterator) }
  end

  describe '#result' do
    subject { route.result }
    its(:count) { should == route.count }
    it { should be_root }
    it 'should have the right type' do
      pending 'can I check the type of a route?'
      it { should be_a(VerticesRouteModule) }
      empty.should be_a(EdgesRouteModule)
      empty.should be_a(MixedRouteModule)
    end
  end

  describe '#route' do
    subject { route.route }
    its(:hide_elements) { should be_true }
    it { should equal(route) }
  end

  describe '#vars' do
  end
end

for_each_graph do
  use_pacer_graphml_data
  it_uses Pacer::Routes::Base do
    let(:route) { graph.v }
  end
  it_uses 'Route results' do
    let(:route) { graph.v }
  end
  it_uses Pacer::Routes::Base do
    let(:route) { graph.e }
  end
  it_uses 'Route results' do
    let(:route) { graph.e }
  end
end
