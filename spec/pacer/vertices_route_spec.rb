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

  it { @g.should_not be_is_a(RouteOperations) }
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

  describe '#result' do
    it 'should not be nil when no matching vertices' do
      empty = @g.v(:name => 'missing').result
      empty.should be_is_a(VerticesRouteModule)
      empty.count.should == 0
    end

    it 'should not be nil when no matching edges' do
      empty = @g.e(:missing).result
      empty.should be_is_a(EdgesRouteModule)
      empty.count.should == 0
    end

    it 'should not be nil when no matching mixed results' do
      empty = @g.v.branch { |x| x.out_e(:missing) }.branch { |x| x.out_e(:missing) }
      empty.should be_is_a(MixedRouteModule)
      empty.count.should == 0
    end
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

  describe '#repeat' do
    it 'should apply the route part twice' do
      route = @g.v.repeat(2) { |tail| tail.out_e.in_v }.inspect
      route.should == @g.v.out_e.in_v.out_e.in_v.inspect
    end

    it 'should apply the route part 3 times' do
      route = @g.v.repeat(3) { |tail| tail.out_e.in_v }.inspect
      route.should == @g.v.out_e.in_v.out_e.in_v.out_e.in_v.inspect
    end

    describe 'with a range' do
      before do
        @start = @g.vertex(0).v
        @route = @start.repeat(1..3) { |tail| tail.out_e.in_v[0] }
      end

      it 'should be equivalent to executing each path separately' do
        @route.to_a.should == [@start.out_e.in_v.first,
                               @start.out_e.in_v.out_e.in_v.first,
                               @start.out_e.in_v.out_e.in_v.out_e.in_v.first]
      end

      it { @route.should be_a(BranchedRoute) }
      it { @route.back.should be_a(VerticesRoute) }
      it { @route.back.back.should be_nil }
    end

  end

end

describe PathsRoute do
  before :all do
    @g = Pacer.tg 'spec/data/pacer.graphml'
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

  describe '#transpose' do
    it 'should return the paths between people and projects' do
      Set[*@g.v(:type => 'person').out_e.in_v(:type => 'project').paths.transpose].should ==
        Set[[@g.vertex(0), @g.vertex(5), @g.vertex(5), @g.vertex(5)],
            [@g.edge(0), @g.edge(1), @g.edge(13), @g.edge(12)],
            [@g.vertex(1), @g.vertex(4), @g.vertex(2), @g.vertex(3)]]
    end
  end

  describe '#subgraph' do
    before do
      @sg = @g.v(:type => 'person').out_e.in_v(:type => 'project').subgraph

      @vertices = @g.v(:type => 'person').to_a + @g.v(:type => 'project').to_a
      @edges = @g.v(:type => 'person').out_e(:wrote)
    end

    it { Set[*@sg.v.ids].should == Set[*@vertices.map { |v| v.id }] }
    it { Set[*@sg.e.ids].should == Set[*@edges.map { |e| e.id }] }

    it { @sg.e.labels.uniq.should == ['wrote'] }
    it { Set[*@sg.v.map { |v| v.properties }].should == Set[*@vertices.map { |v| v.properties }] }
  end
end

describe BranchedRoute do
  before :all do
    @g = Pacer.tg 'spec/data/pacer.graphml'
    @br = @g.v(:type => 'person').
      branch { |b| b.out_e.in_v(:type => 'project') }.
      branch { |b| b.out_e.in_v.out_e }
  end

  describe '#inspect' do
    it 'should include both branches when inspecting' do
      @br.inspect.should ==
        '#<Vertices([{:type=>"person"}]) -> Branched { #<V -> Edges(OUT_EDGES) -> Vertices(IN_VERTEX, [{:type=>"project"}])> | #<V -> Edges(OUT_EDGES) -> Vertices(IN_VERTEX) -> Edges(OUT_EDGES)> }>'
    end
  end

  it 'should return matches in round robin order by default' do
    @br.to_a.should ==
      [@g.vertex(1), @g.edge(3),
       @g.vertex(4), @g.edge(2),
       @g.vertex(2), @g.edge(4),
       @g.vertex(3), @g.edge(6), @g.edge(5), @g.edge(7)]
  end

  it '#exhaustive should return matches in exhaustive merge order' do
    @br.exhaustive.to_a.should ==
      [@g.vertex(1), @g.vertex(4), @g.vertex(2), @g.vertex(3),
        @g.edge(3), @g.edge(2), @g.edge(4), @g.edge(6), @g.edge(5), @g.edge(7)]
  end

  it { @br.branch_count.should == 2 }
  it { @br.should_not be_root }

  describe '#mixed' do
    it { @br.mixed.to_a.should == @br.to_a }
  end

  describe 'branch chaining bug' do
    before do
      @linear = Pacer.tg
      a, b, c, d = @linear.add_vertex('a'), @linear.add_vertex('b'), @linear.add_vertex('c'), @linear.add_vertex('d')
      @linear.add_edge nil, a, b, 'to'
      @linear.add_edge nil, b, c, 'to'
      @linear.add_edge nil, c, d, 'to'
      @source = VerticesRoute.from_vertex_ids @linear, ['a', 'b']

      @single_v = @source.branch { |v| v.out_e.in_v }.branch { |v| v.out_e.in_v }.v
      @single_m = @source.branch { |v| v.out_e.in_v }.branch { |v| v.out_e.in_v }.mixed

      @v =  @source.branch { |v| v.out_e.in_v }.branch { |v| v.out_e.in_v }.v.branch                { |v| v.out_e.in_v }.branch { |v| v.out_e.in_v }
      @m =  @source.branch { |v| v.out_e.in_v }.branch { |v| v.out_e.in_v }.mixed.branch            { |v| v.out_e.in_v }.branch { |v| v.out_e.in_v }
      @ve = @source.branch { |v| v.out_e.in_v }.branch { |v| v.out_e.in_v }.exhaustive.v.branch     { |v| v.out_e.in_v }.branch { |v| v.out_e.in_v }.exhaustive
      @me = @source.branch { |v| v.out_e.in_v }.branch { |v| v.out_e.in_v }.exhaustive.mixed.branch { |v| v.out_e.in_v }.branch { |v| v.out_e.in_v }.exhaustive
    end

    it { @single_v.count.should == 4 }
    it { @single_m.count.should == 4 }
    it { @single_v.group_count { |v| v.id }.should ==  { 'b' => 2, 'c' => 2 } }
    it { @single_m.group_count { |v| v.id }.should ==  { 'b' => 2, 'c' => 2 } }

    it { @v.count.should ==  8 }
    it { @m.count.should ==  8 }
    it { @ve.count.should == 8 }
    it { @me.count.should == 8 }

    it { @v.group_count { |v| v.id }.should ==  { 'c' => 4, 'd' => 4 } }
    it { @m.group_count { |v| v.id }.should ==  { 'c' => 4, 'd' => 4 } }
    it { @ve.group_count { |v| v.id }.should == { 'c' => 4, 'd' => 4 } }
    it { @me.group_count { |v| v.id }.should == { 'c' => 4, 'd' => 4 } }

  end

  describe 'chained branch routes' do
    describe 'once' do
      before do
        @once = @g.v.branch { |v| v.v }.branch { |v| v.v }.v
      end

      it 'should double each vertex' do
        @once.count.should == @g.v.count * 2
      end

      it 'should have 2 of each vertex' do
        @once.group_count { |v| v.id.to_i }.should == { 0 => 2, 1 => 2, 2 => 2, 3 => 2, 4 => 2, 5 => 2, 6 => 2 }
      end
    end

    describe 'twice' do
      before do
        # the difference must be with the object that's passed to the branch method
        @twice_v = @g.v.branch { |v| v.v }.branch { |v| v.v }.v.branch { |v| v.v }.branch { |v| v.v }
        @twice_m = @g.v.branch { |v| v.v }.branch { |v| v.v }.mixed.branch { |v| v.v }.branch { |v| v.v }
        @twice_v_e = @g.v.branch { |v| v.v }.branch { |v| v.v }.exhaustive.v.branch { |v| v.v }.branch { |v| v.v }.exhaustive
        @twice_m_e = @g.v.branch { |v| v.v }.branch { |v| v.v }.exhaustive.mixed.branch { |v| v.v }.branch { |v| v.v }.exhaustive
      end

      it { @twice_v.count.should == @g.v.count * 2 * 2 }
      it { @twice_m.count.should == @g.v.count * 2 * 2 }
      it { @twice_v_e.count.should == @g.v.count * 2 * 2 }
      it { @twice_m_e.count.should == @g.v.count * 2 * 2 }

      describe 'should have 4 of each' do
        it { @twice_v.group_count { |v| v.id.to_i }.sort.should == { 0 => 4, 1 => 4, 2 => 4, 3 => 4, 4 => 4, 5 => 4, 6 => 4 }.sort }
        it { @twice_m.group_count { |v| v.id.to_i }.sort.should == { 0 => 4, 1 => 4, 2 => 4, 3 => 4, 4 => 4, 5 => 4, 6 => 4 }.sort }
        it { @twice_v_e.group_count { |v| v.id.to_i }.sort.should == { 0 => 4, 1 => 4, 2 => 4, 3 => 4, 4 => 4, 5 => 4, 6 => 4 }.sort }
        it { @twice_m_e.group_count { |v| v.id.to_i }.sort.should == { 0 => 4, 1 => 4, 2 => 4, 3 => 4, 4 => 4, 5 => 4, 6 => 4 }.sort }
      end
    end
  end

  describe 'route with a custom split pipe' do
    before do
      @r = @g.v.branch { |person| person.v }.branch { |project| project.v }.branch { |other| other.out_e }.split_pipe(Tackle::TypeSplitPipe).mixed
    end

    describe 'vertices' do
      it { @r.v.to_a.should == @r.v.uniq.to_a }
      it 'should have only all person and project vertices' do
        people_and_projects = Set[*@g.v(:type => 'person')] + Set[*@g.v(:type => 'project')]
        Set[*@r.v].should == people_and_projects
      end
    end

    describe 'edges' do
      it { @r.e.to_a.should == @r.e.uniq.to_a }
      it 'should have out edges from all vertices except person and project' do
        # TODO: this type of thing should be much easier
        people_and_projects = Set[*@g.v(:type => 'person')] + Set[*@g.v(:type => 'project')]
        vertices = @g.v.to_a - people_and_projects.to_a
        edges = Set[*vertices.map { |v| v.out_e.to_a }.flatten]
        Set[*@r.e].should == edges
      end
    end

    describe 'chained' do
      def add_branch(vertices_path)
        vertices_path.
          branch { |person| person.out_e.in_v }.
          branch { |project| project.v }.
          branch { |other| other.out_e.in_v }.split_pipe(Tackle::TypeSplitPipe).v
      end

      it 'should have 5 unique elements when run once' do
        @g.v.repeat(1) { |repeater| add_branch(repeater) }.count.should == 12
        @g.v.repeat(1) { |repeater| add_branch(repeater) }.uniq.count.should == 5
      end

      it 'should have 4 unique elements when run twice' do
        @g.v.repeat(2) { |repeater| add_branch(repeater) }.count.should == 14
        @g.v.repeat(2) { |repeater| add_branch(repeater) }.uniq.count.should == 4
      end

      it 'should have 4 unique elements when run thrice' do
        @g.v.repeat(3) { |repeater| add_branch(repeater) }.count.should == 14
        @g.v.repeat(3) { |repeater| add_branch(repeater) }.uniq.count.should == 4
      end
    end
  end
end
