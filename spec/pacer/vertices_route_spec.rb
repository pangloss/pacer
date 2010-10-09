require 'spec_helper'
require 'set'

include Pacer::Routes

describe GraphRoute do
  before do
    @g = Pacer.tg
  end

  describe '#v' do
    it { @g.v.should be_an_instance_of(VerticesRoute) }
  end

  describe '#e' do
    it { @g.e.should be_an_instance_of(EdgesRoute) }
  end
end


describe VerticesRoute do
  before do
    @g = Pacer.tg 'spec/data/pacer.graphml'
  end

  describe '#out_e' do
    it { @g.v.out_e.should be_an_instance_of(EdgesRoute) }
    it { @g.v.out_e(:label).should be_an_instance_of(EdgesRoute) }
    it { @g.v.out_e(:label) { |x| true }.should be_an_instance_of(EdgesRoute) }
    it { @g.v.out_e { |x| true }.should be_an_instance_of(EdgesRoute) }

    it { Set[*@g.v.out_e].should == Set[*@g.edges] }

    it { @g.v.out_e.count.should >= 1 }
  end
end

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
        '#<Vertices([{:name=>"gremlin"}]) -> :grem -> Edges(IN_EDGES, [:wrote]) -> Vertices(OUT_VERTEX) -> Edges(OUT_EDGES, [:wrote], &block) -> Vertices(IN_VERTEX) -> Vertices(&block)>'
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
    it { @g.v.each.should be_is_a(java.util.Iterator) }
    it { @g.v.out_e.each.should be_is_a(java.util.Iterator) }
    it { @g.v.each.to_a.should == @g.v.to_a }
  end

  describe 'property filter' do
    it { @g.v(:name => 'pacer').to_a.should == @g.v.select { |v| v[:name] == 'pacer' } }
    it { @g.v(:name => 'pacer').count.should == 1 }
  end

  describe 'block filter' do
    it { @g.v { false }.count.should == 0 }
    it { @g.v { true }.count.should == @g.v.count }
    it { @g.v { |v| v.out_e.none? }[:name].should == ['blueprints'] }
  end
end

describe RouteOperations do
  before :all do
    @g = Pacer.tg 'spec/data/pacer.graphml'
  end

  describe '#uniq' do
    it 'should be a route' do
      @g.v.uniq.should be_an_instance_of(VerticesRoute)
    end

    it 'results should be unique' do
      @g.e.in_v.group_count(:name).values.sort.last.should > 1
      @g.e.in_v.uniq.group_count(:name).values.sort.last.should == 1
    end
  end

  describe '#random' do
    it { Set[*@g.v.random(1)].should == Set[*@g.v] }
    it { @g.v.random(0).to_a.should == [] }
    it 'should have some number of elements more than 1 and less than all' do
      range = 1..(@g.v.count - 1)
      range.should include(@g.v.random(0.5).count)
    end
  end

  describe '#as' do
    it 'should set the variable to the correct node' do
      vars = Set[]
      @g.v.as(:a_vertex).in_e(:wrote) { |edge| vars << edge.vars[:a_vertex] }.count
      vars.should == Set[*@g.e(:wrote).in_v]
    end
  end

  describe '#paths' do
    it 'should return the paths between people and projects' do
      Set[*@g.v(:type => 'person').out_e.in_v(:type => 'project').paths].should ==
        Set[[@g.vertex(0), @g.edge(0), @g.vertex(1)],
            [@g.vertex(5), @g.edge(1), @g.vertex(4)],
            [@g.vertex(5), @g.edge(13), @g.vertex(2)],
            [@g.vertex(5), @g.edge(12), @g.vertex(3)]]
    end
  end
end
