require 'spec_helper'

shared_examples_for Pacer::Routes::Base do
  # defaults
  let(:back) { nil }
  let(:info) { nil }

  subject { route }
  its(:graph) { should equal(graph) }
  its(:back) { should equal(back) }
  its(:info) { should == info }
  context 'with info' do
    before { route.info = 'some info' }
    its(:info) { should == 'some info' }
  end

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


  # TODO: Apply tests to the results?
  describe '#graph' do
    subject { route.first.graph }
    it { should equal(graph) }
  end

  describe '#to_a' do
    it { Set[*graph.v].should == Set[*graph.vertices] }
    it { Set[*(route.to_a)].should == Set[*graph.vertices] }
    it { Set[*graph.e].should == Set[*graph.edges] }
    it { Set[*(graph.e.to_a)].should == Set[*graph.edges] }
    it { route.to_a.count.should == graph.vertices.count }
    it { graph.e.to_a.count.should == graph.edges.count }
  end

  describe '#inspect' do
    it 'should show the path in the resulting string' do
      other_projects_by_gremlin_writer = 
        graph.v(:name => 'gremlin').as(:grem).in_e(:wrote).out_v.out_e(:wrote) { |e| true }.in_v.except(:grem)
      other_projects_by_gremlin_writer.inspect.should ==
        '#<IndexedVertices -> :grem -> Edges(IN_EDGES, [:wrote]) -> Vertices(OUT_VERTEX) -> Edges(OUT_EDGES, [:wrote], &block) -> Vertices(IN_VERTEX) -> Vertices(&block)>'
    end
  end

  describe '#root?' do
    it { graph.should be_root }
    it { route.should be_root }
    it { graph.v[3].should_not be_root }
    it { route.out_e.should_not be_root }
    it { route.out_e.in_v.should_not be_root }
    it { route.result.should be_root }
  end

  describe '#[]' do
    it { graph.v[2].count.should == 1 }
    it { graph.v[2].result.is_a?(Pacer::VertexMixin).should be_true }
  end

  describe '#from_graph?' do
    it { route.should be_from_graph(graph) }
    it { route.out_e.should be_from_graph(graph) }
    it { route.out_e.should_not be_from_graph(Pacer.tg) }
  end

  describe '#each' do
    it { route.each.should be_a(java.util.Iterator) }
    it { route.out_e.each.should be_a(java.util.Iterator) }
    it { route.each.to_a.should == route.to_a }
  end

  describe 'property filter' do
    it { graph.v(:name => 'pacer').to_a.should == route.select { |v| v[:name] == 'pacer' } }
    it { graph.v(:name => 'pacer').count.should == 1 }
  end

  describe 'block filter' do
    it { graph.v { false }.count.should == 0 }
    it { graph.v { true }.count.should == route.count }
    it { graph.v { |v| v.out_e.none? }[:name].to_a.should == ['blueprints'] }

    it 'should work with paths' do
      paths = route.out_e(:wrote).in_v.paths.map(&:to_a)
      filtered_paths = graph.v { true }.out_e(:wrote).e { true }.in_v.paths.map(&:to_a)
      filtered_paths.should == paths
    end
  end

  describe '#result' do
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
      empty = route.branch { |x| x.out_e(:missing) }.branch { |x| x.out_e(:missing) }
      empty.should be_a(MixedRouteModule)
      empty.count.should == 0
    end
  end
end
for_each_graph do
  it_uses Pacer::Routes::Base do
    before do
      graph.import 'spec/data/pacer.graphml'
    end
    let(:route) { graph.v }
  end
end
