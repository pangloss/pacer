require 'spec_helper'

describe Pacer::Transform::Branch do
  before :all do
    @g = Pacer.tg 'spec/data/pacer.graphml'
    @br = @g.v(:type => 'person').
      branch { |b| b.out_e.in_v(:type => 'project') }.
      branch { |b| b.out_e.in_v.out_e }
  end

  describe '#inspect' do
    it 'should include both branches when inspecting' do
      @br.inspect.should ==
        "#<V-Index(type: \"person\") -> Elem-Branch { #<V -> outE -> inV -> V-Property(type==\"project\")> | #<V -> outE -> inV -> outE> }>"
    end
  end

  it 'should return matches in fair merge order by default' do
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

  it { @br.branches.count.should == 2 }
  it { @br.should_not be_root }

  describe '#mixed' do
    it { @br.mixed.to_a.should == @br.to_a }
  end

  describe 'branch chaining bug' do
    before do
      @linear = Pacer.tg
      @a, @b, @c, @d = @linear.create_vertex('a'), @linear.create_vertex('b'), @linear.create_vertex('c'), @linear.create_vertex('d')
      @ab = @linear.create_edge nil, @a, @b, 'to'
      @bc = @linear.create_edge nil, @b, @c, 'to'
      @cd = @linear.create_edge nil, @c, @d, 'to'
      @source = %w[a b].id_to_element_route(based_on: @linear.v)

      single = @source.branch { |v| v.out_e.in_v }.branch { |v| v.out_e.in_v }
      @single_v = single.v
      @single_m = single.mixed

      @v = single.v.branch { |v| v.out_e.in_v }.branch { |v| v.out_e.in_v }
      @m = single.mixed.branch { |v| v.out_e.in_v }.branch { |v| v.out_e.in_v }
      @ve = single.exhaustive.v.branch { |v| v.out_e.in_v }.branch { |v| v.out_e.in_v }.exhaustive
      @me = single.exhaustive.mixed.branch { |v| v.out_e.in_v }.branch { |v| v.out_e.in_v }.exhaustive
    end

    specify { @source.count.should == 2 }
    specify { @single_v.count.should == 4 }
    specify { @single_m.count.should == 4 }
    specify { @single_v.group_count { |v| v.element_id }.should ==  { 'b' => 2, 'c' => 2 } }
    specify { @single_m.group_count { |v| v.element_id }.should ==  { 'b' => 2, 'c' => 2 } }

    specify { @v.count.should ==  8 }
    specify { @m.count.should ==  8 }
    specify { @ve.count.should == 8 }
    specify { @me.count.should == 8 }

    specify { @v.group_count { |v| v.element_id }.should ==  { 'c' => 4, 'd' => 4 } }
    specify { @m.group_count { |v| v.element_id }.should ==  { 'c' => 4, 'd' => 4 } }
    specify { @ve.group_count { |v| v.element_id }.should == { 'c' => 4, 'd' => 4 } }
    specify { @me.group_count { |v| v.element_id }.should == { 'c' => 4, 'd' => 4 } }

    specify do
      @single_v.paths.collect(&:to_a).should ==
        [[@a, @ab, @b],
         [@b, @bc, @c],
         [@a, @ab, @b],
         [@b, @bc, @c]]
    end

    specify do
      @v.to_a.should == [@c, @c, @d, @d, @c, @c, @d, @d]
      @v.paths.collect(&:to_a).should ==
        [[@a, @ab, @b, @bc, @c], [@a, @ab, @b, @bc, @c], [@b, @bc, @c, @cd, @d], [@b, @bc, @c, @cd, @d],
         [@a, @ab, @b, @bc, @c], [@a, @ab, @b, @bc, @c], [@b, @bc, @c, @cd, @d], [@b, @bc, @c, @cd, @d]]
    end
    specify do
      @v.to_a.should == [@c, @c, @d, @d, @c, @c, @d, @d]
      @v.paths.collect(&:to_a).should ==
        [[@a, @ab, @b, @bc, @c], [@a, @ab, @b, @bc, @c], [@b, @bc, @c, @cd, @d], [@b, @bc, @c, @cd, @d],
         [@a, @ab, @b, @bc, @c], [@a, @ab, @b, @bc, @c], [@b, @bc, @c, @cd, @d], [@b, @bc, @c, @cd, @d]]
    end
    specify do
      @v.to_a.should == [@c, @c, @d, @d, @c, @c, @d, @d]
      @ve.paths.collect(&:to_a).should ==
        [[@a, @ab, @b, @bc, @c], [@b, @bc, @c, @cd, @d],
         [@a, @ab, @b, @bc, @c], [@b, @bc, @c, @cd, @d],
         [@a, @ab, @b, @bc, @c], [@b, @bc, @c, @cd, @d],
         [@a, @ab, @b, @bc, @c], [@b, @bc, @c, @cd, @d]]
    end
    specify do
      @me.to_a.should == [@c, @d, @c, @d, @c, @d, @c, @d]
      @me.paths.collect(&:to_a).should ==
        [[@a, @ab, @b, @bc, @c], [@b, @bc, @c, @cd, @d],
         [@a, @ab, @b, @bc, @c], [@b, @bc, @c, @cd, @d],
         [@a, @ab, @b, @bc, @c], [@b, @bc, @c, @cd, @d],
         [@a, @ab, @b, @bc, @c], [@b, @bc, @c, @cd, @d]]
    end

  end

  describe 'route with a custom split pipe' do
    before do
      @r = @g.v.branch(split_pipe: Tackle::TypeSplitPipe) { |person| person.v{true} }.branch { |project| project.v{true} }.branch { |other| other.out_e }.mixed
    end

    describe 'vertices' do
      specify { @r.v.to_a.should == @r.v.uniq.to_a }
      it 'should have only all person and project vertices' do
        people_and_projects = Set[*@g.v(:type => 'person')] + Set[*@g.v(:type => 'project')]
        Set[*@r.v].should == people_and_projects
      end
    end

    describe 'edges' do
      specify { @r.e.to_a.should == @r.e.uniq.to_a }
      it 'should have out edges from all vertices except person and project' do
        # TODO: this type of thing should be much easier
        people_and_projects = Set[*@g.v(:type => 'person')] + Set[*@g.v(:type => 'project')]
        vertices = @g.v.to_a - people_and_projects.to_a
        edges = Set[*vertices.collect { |v| v.out_e.to_a }.flatten]
        Set[*@r.e].should == edges
      end
    end

    describe 'chained' do
      def add_branch(vertices_path)
        @person = 0
        @project = 0
        @other = 0
        vertices_path.
          branch(split_pipe: Tackle::TypeSplitPipe) { |person| person.v { |x| @person += 1; true }.out_e.in_v }.
          branch { |project| project.v { |x| @project += 1;true} }.
          branch { |other| other.v { |x| @other += 1;true}.out_e.in_v }.v
      end

      it 'should have elements' do
        @g.v.count.should == 7
      end

      it 'should work without repeating' do
        people = @g.v(:type => 'person')
        projects = @g.v(:type => 'project')
        other = @g.v.except(people).except(projects)
        add_branch(@g.v).count.should == people.out_e.in_v.count + projects.count + other.out_e.in_v.count
        @person.should == 2
        @project.should == 4
        @other.should == 1
      end

      it 'should have 12 elements when run once' do
        @g.v.repeat(1) { |repeater| add_branch(repeater) }.count.should == 12
      end
      it 'should have 5 unique elements when run once' do
        @g.v.repeat(1) { |repeater| add_branch(repeater) }.uniq.count.should == 5
      end

      it 'should have 14 elements when run twice' do
        @g.v.repeat(2) { |repeater| add_branch(repeater) }.count.should == 14
      end
      it 'should have 4 unique elements when run twice' do
        @g.v.repeat(2) { |repeater| add_branch(repeater) }.uniq.count.should == 4
      end

      it 'should have 14 elements when run thrice' do
        @g.v.repeat(3) { |repeater| add_branch(repeater) }.count.should == 14
      end
      it 'should have 4 unique elements when run thrice' do
        @g.v.repeat(3) { |repeater| add_branch(repeater) }.uniq.count.should == 4
      end
    end
  end

  context 'exhaustive merge' do
    it 'should not filter the edges out' do
      pending
      #>> g = Pacer.neo4j '/Users/dw/dev/ucmdb/tmp/neo.db'
      #=> #<Neo4jGraph>
      #>> g.v(:type => 'nt').out_e { |e| e.label != 'contained' }.branch { |b| b.out_v }.branch { |b| b.in_v.in_e }
      ##<V[100]>                        #<E[99777]:1439-dependency-3363> #<V[133]>
      ##<E[99757]:2352-dependency-3363> #<V[255]>                        #<E[99747]:484-dependency-3363>
      ##<V[267]>                        #<E[99734]:6055-dependency-3363> #<V[296]>
      ##<E[99728]:5686-dependency-3363> #<V[316]>                        #<E[99727]:4400-dependency-3363>
      ##<V[341]>                        #<E[99715]:5319-dependency-3363> #<V[368]>
      ##<E[99711]:100-dependency-3363>  #<V[379]>                        #<E[99699]:6625-dependency-3363>
      ##<V[389]>                        #<E[99696]:3282-dependency-3363> #<V[404]>
      ##<E[99680]:5104-dependency-3363> #<V[406]>                        #<E[99630]:133-dependency-3363>
      ##<V[1730]>                       #<E[99615]:1933-dependency-3363> #<V[2471]>
      ##<E[99598]:2648-dependency-3363> #<V[2471]>                       #<E[99577]:5753-dependency-3363>
      ##<V[2959]>                       #<E[99568]:1730-dependency-3363>
      #Total: 32
      #=> #<Vertices([{:type=>"nt"}]) -> Edges(OUT_EDGES, &block) -> Elem-Branch { #<E -> Vertices(OUT_VERTEX)> | #<E -> Vertices(IN_VERTEX) -> Edges(IN_EDGES)> }>
      #>> g.v(:type => 'nt').out_e { |e| e.label != 'contained' }.branch { |b| b.out_v }.branch { |b| b.in_v.in_e }.exhaustive
      ##<V[100]>  #<V[133]>  #<V[255]>  #<V[267]>  #<V[296]>  #<V[316]>  #<V[341]>  #<V[368]>  #<V[379]>  #<V[389]>
      ##<V[404]>  #<V[406]>  #<V[1730]> #<V[2471]> #<V[2471]> #<V[2959]>
      #Total: 16
      #=> #<Vertices([{:type=>"nt"}]) -> Edges(OUT_EDGES, &block) -> Elem-Branch { #<E -> Vertices(OUT_VERTEX)> | #<E -> Vertices(IN_VERTEX) -> Edges(IN_EDGES)> }>
    end
  end
end

Run.tg(:read_only) do
  use_pacer_graphml_data(:read_only)

  describe 'chained branch routes' do
    describe 'once' do
      subject { graph.v.branch { |v| v.v{true} }.branch { |v| v.v{true} }.v }

      its(:count) { should == graph.v.count * 2 }
      it 'should have 2 of each vertex' do
        subject.group_count { |v| v.element_id.to_i }.should == { 0 => 2, 1 => 2, 2 => 2, 3 => 2, 4 => 2, 5 => 2, 6 => 2 }
      end
    end

    describe 'twice' do
        # the difference must be with the object that's passed to the branch method
      def single
        graph.v.branch { |v| v.v{true} }.branch { |v| v.v{true} }
      end
      let(:twice_v) { single.v.branch { |v| v.v{true} }.branch { |v| v.v{true} } }
      let(:twice_m) { single.mixed.branch { |v| v.v{true} }.branch { |v| v.v{true} } }
      let(:twice_v_e) { single.exhaustive.v.branch { |v| v.v{true} }.branch { |v| v.v{true} }.exhaustive }
      let(:twice_m_e) { single.exhaustive.mixed.branch { |v| v.v{true} }.branch { |v| v.v{true} }.exhaustive }

      it 'should have 7 vertices' do
        graph.v.count.should == 7
      end

      context 'branched once' do
        subject { single }
        its(:count) { should == graph.v.count * 2 }
        context 'merged with vertices and branched again' do
          subject { twice_v }
          its(:count) { should == graph.v.count * 2 * 2 }
          context 'grouped' do
            subject { twice_v.group_count { |v| v.element_id.to_i }.sort }
            it { should == { 0 => 4, 1 => 4, 2 => 4, 3 => 4, 4 => 4, 5 => 4, 6 => 4 }.sort }
          end
        end
      end

      it { twice_m.count.should == graph.v.count * 2 * 2 }
      it { twice_v_e.count.should == graph.v.count * 2 * 2 }
      it { twice_m_e.count.should == graph.v.count * 2 * 2 }

      describe 'should have 4 of each' do
        it { twice_m.group_count { |v| v.element_id.to_i }.sort.should == { 0 => 4, 1 => 4, 2 => 4, 3 => 4, 4 => 4, 5 => 4, 6 => 4 }.sort }
        it { twice_v_e.group_count { |v| v.element_id.to_i }.sort.should == { 0 => 4, 1 => 4, 2 => 4, 3 => 4, 4 => 4, 5 => 4, 6 => 4 }.sort }
        it { twice_m_e.group_count { |v| v.element_id.to_i }.sort.should == { 0 => 4, 1 => 4, 2 => 4, 3 => 4, 4 => 4, 5 => 4, 6 => 4 }.sort }
      end
    end
  end

end
