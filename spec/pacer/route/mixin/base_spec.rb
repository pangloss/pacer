require 'spec_helper'

for_tg do
  describe Pacer::Routes::Base, 'pipe creation internals' do
    context "graph.v" do
      describe '#build_pipeline' do
        subject { graph.v.send(:build_pipeline) }
        it { should be_a(Array) }
        its(:count) { should == 2 }
        its(:first) { should be_a(Pacer::Pipes::GraphElementPipe) }
        specify { subject.first.should equal(subject.last) }
      end

      describe '#pipe_source' do
        subject { graph.v.send(:pipe_source) }
        it { should be_nil }
      end

      describe '#iterator' do
        use_simple_graph_data
        before { setup_data }
        subject { graph.v.send(:iterator) }
        its(:next) { should_not be_nil }
      end
    end

    context "graph.v(:name => 'gremlin').as(:grem).in_e(:wrote)" do
      let(:route) { graph.v(:name => 'gremlin').as(:grem).in_e(:wrote) }
      subject { route }

      its(:inspect) { should == "#<Vertices(VERTEX) -> V-Property([{:name=>\"gremlin\"}]) -> :grem -> Edges(IN_EDGES) -> E-Property([:wrote])>" }
      its(:out_v) { should_not be_nil }
    end

    context "graph.v(:name => 'gremlin').as(:grem).in_e(:wrote)" do
      let(:route) { graph.v(:name => 'gremlin').as(:grem).in_e(:wrote) }
      subject { route }

      its(:inspect) { should == "#<Vertices(VERTEX) -> V-Property([{:name=>\"gremlin\"}]) -> :grem -> Edges(IN_EDGES) -> E-Property([:wrote])>" }
      its(:out_v) { should_not be_nil }
    end

    context "graph.v(:name => 'gremlin').as(:grem).in_e(:wrote)" do
      let(:route) { graph.v.in_e.out_v(Tackle::SimpleMixin) }
      subject { route }

      its(:in_e) { should_not be_nil }
      its(:to_a) { should == [] }
      its(:extensions) { should == Set[Tackle::SimpleMixin] }
    end

    context "graph.v(:name => 'darrick')" do
      use_simple_graph_data
      before { setup_data }
      subject { graph.v(:name => 'darrick') }

      its(:build_pipeline) { should == [nil, nil] }
      its(:pipe_source) { should be_nil }
      its('iterator.next') { should == v1 }
      its(:to_a) { should == [v1] }
    end

    context 'graph.v.element_ids' do
      describe '#build_pipeline' do
        subject { graph.v.element_ids.send(:build_pipeline) }
        it { should be_a(Array) }
        its(:count) { should == 2 }
        its(:first) { should be_a(Pacer::Pipes::GraphElementPipe) }
        its(:last) { should be_a(Pacer::Pipes::IdPipe) }
      end

      describe '#iterator' do
        use_simple_graph_data
        before { setup_data }
        subject { graph.v.element_ids.send(:iterator) }
        its(:next) { should_not be_nil }
        it 'should iterate twice then raise an exception' do
          2.times {
            [v0.element_id, v1.element_id].should include(subject.next)
          }
          begin
            subject.next
            fail 'expected exception to be raised'
          rescue NativeException => e
            e.cause.should == java.util.NoSuchElementException
          end
        end
      end

      describe '#to_a' do
        use_simple_graph_data
        before { setup_data }
        subject { graph.v.element_ids.to_a }
        its(:sort) { should == [v0.element_id, v1.element_id].sort }
      end
    end
  end
end

for_each_graph(:read_only) do
  describe Pacer::Routes::Base do
    use_pacer_graphml_data(:read_only)
    before { setup_data }
    describe '#inspect' do
      it 'should show the path in the resulting string' do
        r = graph.v(:name => 'gremlin')
        r = r.as(:grem)
        r = r.in_e(:wrote)
        r = r.out_v
        r = r.out_e(:wrote) { |e| true }
        r = r.in_v
        r = r.except(:grem)
        r.inspect.should ==
          "#<IndexedVertices -> :grem -> Edges(IN_EDGES) -> E-Property([:wrote]) -> Vertices(OUT_VERTEX) -> Edges(OUT_EDGES) -> E-Property([:wrote], &block) -> Vertices(IN_VERTEX) -> V-Property(&block)>"
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

    describe '#==' do
      specify { graph.v.should == graph.v }
      specify { graph.v.should_not == graph.v { true } }
      specify { graph.v.should_not == graph.v(:x => 1) }
      specify { graph.e.should == graph.e }
      specify { graph.v.should_not == graph.e }
    end

    describe '#result' do
      context 'no matching vertices' do
        subject { graph.v(:name => 'missing').result }
        it { should be_a(VerticesRouteModule) }
        its(:count) { should == 0 }
        its(:empty?) { should be_true }
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
  let(:route_extensions) { Set[] }

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

    subject { route }

    its(:extensions) { should == route_extensions }

    describe '#[Fixnum]' do
      subject { route[number_of_results - 1] }
      it { should be_a(Pacer::Routes::Base) }
      its(:count) { should == 1 }
      its(:result) { should be_a(graph.element_type(result_type)) }
      its(:extensions) { should == route.extensions }
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
      its('first.extensions') { should == route.extensions }
    end

    describe '#except' do
      context '(first_element)' do
        subject { route.except(first_element) }
        its(:to_a) { should_not include(first_element) }
        its('first.class') { should == first_element.class }
        its(:extensions) { should == route.extensions }
      end
      context '(all_elements)' do
        subject { route.except(all_elements) }
        its(:count) { should == 0 }
      end
    end

    describe '#only' do
      subject { route.only(first_element).uniq }
      its(:to_a) { should == [first_element] }
      its('first.class') { should == first_element.class }
      its(:extensions) { should == route.extensions }

      context 'for non-elements' do
        subject { route.element_ids.only(first_element.element_id).uniq }
        its(:to_a) { should == [first_element.element_id] }
      end
    end
  end

  context 'without data' do
    around do |spec|
      if number_of_results == 0
        setup_data
        spec.run
      end
    end

    subject { route }

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

    describe '#element_type' do
      its(:element_type) { should == graph.element_type(result_type) }
    end

    describe '#add_extension' do
      # Note that this mixin doesn't need to include
      # versions of each test with extensions applied because
      context '(SimpleMixin)' do
        before do
          @orig_ancestors = route.class.ancestors
          r = route.add_extension Tackle::SimpleMixin
          r.should equal(route)
        end
        its(:extensions) { should include(Tackle::SimpleMixin) }
        it { should respond_to(:route_mixin_method) }
      end

      context '(Object)' do
        before do
          @orig_ancestors = route.class.ancestors
          route.add_extension Object
        end
        its(:extensions) { should_not include(Object) }
      end

      context '(invalid)' do
        before do
          @orig_ancestors = route.class.ancestors
          route.add_extension :invalid
        end
        its(:extensions) { should_not include(:invalid) }
      end
    end

    describe '#add_extensions' do
      subject { route.add_extensions([Tackle::SimpleMixin, Object, :invalid]) }
      its(:extensions) { should include(Tackle::SimpleMixin) }
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
end
for_each_graph(:read_only) do
  use_pacer_graphml_data(:read_only)
  context 'vertices with extension' do
    it_uses Pacer::Routes::Base do
      let(:back) { graph.v }
      let(:route) { back.filter(Tackle::SimpleMixin) }
      let(:number_of_results) { 7 }
      let(:result_type) { :vertex }
      let(:route_extensions) { Set[Tackle::SimpleMixin] }
    end
  end
end
for_each_graph(:read_only) do
  use_pacer_graphml_data(:read_only)
  context 'no vertices' do
    it_uses Pacer::Routes::Base do
      let(:back) { graph.v }
      let(:route) { back.filter(:something => 'missing') }
      let(:number_of_results) { 0 }
      let(:result_type) { :vertex }
    end
  end
end
for_each_graph(:read_only) do
  use_pacer_graphml_data(:read_only)
  context 'edges' do
    it_uses Pacer::Routes::Base do
      let(:route) { graph.e }
      let(:number_of_results) { 14 }
      let(:result_type) { :edge }
    end
  end
end
