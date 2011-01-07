require 'spec_helper'

describe Base do
  before :all do
    @g = Pacer.tg 'spec/data/pacer.graphml'
  end

  describe '#graph' do
    it { @g.v.graph.should == @g }
    it { @g.v.out_e.graph.should == @g }
    it { @g.v.first.graph.should == @g }
    it { @g.v.in_e.first.graph.should == @g }
    it { @g.v.in_e.out_v.first.graph.should == @g }
  end

  describe '#to_a' do
    it { Set[*@g.v].should == Set[*@g.vertices] }
    it { Set[*(@g.v.to_a)].should == Set[*@g.vertices] }
    it { Set[*@g.e].should == Set[*@g.edges] }
    it { Set[*(@g.e.to_a)].should == Set[*@g.edges] }
    it { @g.v.to_a.count.should == @g.vertices.count }
    it { @g.e.to_a.count.should == @g.edges.count }
  end

  describe '#inspect' do
    it 'should show the path in the resulting string' do
      other_projects_by_gremlin_writer = 
        @g.v(:name => 'gremlin').as(:grem).in_e(:wrote).out_v.out_e(:wrote) { |e| true }.in_v.except(:grem)
      other_projects_by_gremlin_writer.inspect.should ==
        '#<IndexedVertices -> :grem -> Edges(IN_EDGES, [:wrote]) -> Vertices(OUT_VERTEX) -> Edges(OUT_EDGES, [:wrote], &block) -> Vertices(IN_VERTEX) -> Vertices(&block)>'
    end

    it { @g.inspect.should == '#<TinkerGraph>' }
  end

  describe '#root?' do
    it { @g.should be_root }
    it { @g.v.should be_root }
    it { @g.v[3].should_not be_root }
    it { @g.v.out_e.should_not be_root }
    it { @g.v.out_e.in_v.should_not be_root }
    it { @g.v.result.should be_root }
  end

  describe '#[]' do
    it { @g.v[2].count.should == 1 }
    it { @g.v[2].result.is_a?(Pacer::VertexMixin).should be_true }
  end

  describe '#from_graph?' do
    it { @g.v.should be_from_graph(@g) }
    it { @g.v.out_e.should be_from_graph(@g) }
    it { @g.v.out_e.should_not be_from_graph(Pacer.tg) }
  end

  describe '#each' do
    it { @g.v.each.should be_a(java.util.Iterator) }
    it { @g.v.out_e.each.should be_a(java.util.Iterator) }
    it { @g.v.each.to_a.should == @g.v.to_a }
  end

  describe 'property filter' do
    it { @g.v(:name => 'pacer').to_a.should == @g.v.select { |v| v[:name] == 'pacer' } }
    it { @g.v(:name => 'pacer').count.should == 1 }
  end

  describe 'block filter' do
    it { @g.v { false }.count.should == 0 }
    it { @g.v { true }.count.should == @g.v.count }
    it { @g.v { |v| v.out_e.none? }[:name].to_a.should == ['blueprints'] }

    it 'should work with paths' do
      paths = @g.v.out_e(:wrote).in_v.paths.map(&:to_a)
      filtered_paths = @g.v { true }.out_e(:wrote).e { true }.in_v.paths.map(&:to_a)
      filtered_paths.should == paths
    end
  end

  describe '#result' do
    it 'should not be nil when no matching vertices' do
      empty = @g.v(:name => 'missing').result
      empty.should be_a(VerticesRouteModule)
      empty.count.should == 0
    end

    it 'should not be nil when no matching edges' do
      empty = @g.e(:missing).result
      empty.should be_a(EdgesRouteModule)
      empty.count.should == 0
    end

    it 'should not be nil when no matching mixed results' do
      empty = @g.v.branch { |x| x.out_e(:missing) }.branch { |x| x.out_e(:missing) }
      empty.should be_a(MixedRouteModule)
      empty.count.should == 0
    end
  end
end
