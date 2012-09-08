require 'spec_helper'

shared_examples_for Pacer::Wrappers::ElementWrapper do
  context 'vertex' do
    subject { v0 }
    it { should be_a(Pacer::Core::Graph::VerticesRoute) }
    it { should be_a(Pacer::Wrappers::ElementWrapper) }
    it { should be_a(Pacer::Wrappers::VertexWrapper) }
    it { should_not be_a(Pacer::Wrappers::EdgeWrapper) }

    describe '#v' do
      context '()' do
        subject { v0.v }
        its(:to_a) { should == [v0] }
        it { should be_a_vertices_route }
      end

      context '(:name => "eliza")' do
        subject { v0.v(:name => 'eliza') }
        its(:to_a) { should == [v0] }
        it { should be_a_vertices_route }
      end

      context '(:name => "other")' do
        subject { v0.v(:name => 'other') }
        its(:to_a) { should == [] }
        it { should be_a_vertices_route }
      end

      context '(SimpleMixin)' do
        subject { v0.v(Tackle::SimpleMixin) }
        its(:to_a) { should == [v0] }
        it { should be_a_vertices_route }
        its(:extensions) { should == [Tackle::SimpleMixin] }
        its(:element_type) { should == :vertex }
      end
    end

    describe '#e' do
      it 'is unsupported' do
        expect { v0.e }.to raise_error(Pacer::UnsupportedOperation)
      end
    end

    describe '#hash' do
      it 'should not collide between vertices and edges' do
        # different graphs need different numbers
        600.times { graph.create_edge nil, graph.create_vertex, graph.create_vertex, 'abc' }
        v_hashes = graph.v.map(&:hash).to_a
        e_hashes = graph.e.map(&:hash).to_a
        count = v_hashes.count + e_hashes.count
        (v_hashes + e_hashes).uniq.count.should == count
        set = graph.v.to_set + graph.e.to_set
        set.count.should == count
      end
    end

    describe '#eql?' do
      subject { Hash.new(0) }
      before do
        subject[v0] += 1
        subject[graph.v.first] += 1
      end

      its(:keys) { should == [v0] }
      its(:values) { should == [2] }

      it 'should put wrapped vertices in the same key' do
        subject[v0.v(Tackle::SimpleMixin).first] += 1
        subject.values.should == [3]
      end

      it 'should put other vertices in a different key' do
        subject[v1].should == 0
        subject[v0].should == 2
      end
    end
  end

  context 'edge' do
    subject { e0 }
    it { should be_a(Pacer::Core::Graph::EdgesRoute) }
    it { should be_a(Pacer::Wrappers::ElementWrapper) }
    it { should be_a(Pacer::Wrappers::EdgeWrapper) }
    it { should_not be_a(Pacer::Wrappers::VertexWrapper) }

    describe '#e', :transactions => false do
      context '()' do
        subject { e0.e }
        its(:to_a) { should == [e0] }
        it(:a => :b) { should be_an_edges_route }
      end

      context '(:links)' do
        subject { e0.e(:links) }
        its(:to_a) { should == [e0] }
        it { should be_an_edges_route }
      end

      context '(:other)' do
        subject { e0.e(:other) }
        its(:to_a) { should == [] }
        it { should be_an_edges_route }
      end

      context '(SimpleMixin)' do
        subject { e0.e(Tackle::SimpleMixin) }
        its(:to_a) { should == [e0] }
        it { should be_an_edges_route }
        its(:extensions) { should == [Tackle::SimpleMixin] }
      end
    end

    describe '#v' do
      it 'is unsupported' do
        expect { e0.v }.to raise_error(Pacer::UnsupportedOperation)
      end
    end

    describe '#eql?', :transactions => false do
      subject { Hash.new(0) }
      before do
        subject[e0] += 1
        subject[graph.e.first] += 1
      end

      its(:keys) { should == [e0] }
      its(:values) { should == [2] }

      it 'should put wrapped edges in the same key' do
        subject[e0.e(Tackle::SimpleMixin).first] += 1
        subject.values.should == [3]
      end

      it 'should put other edges in a different key' do
        subject[e1].should == 0
        subject[e0].should == 2
      end
    end
  end

  describe '#graph' do
    it { v0.graph.should == graph }
    it { e0.graph.should == graph }
  end

  contexts(
  'vertex' => proc{
    let(:element) { v0 }
  },
  'edge' => proc{
    let(:element) { e0 }
  }) do
    describe '#[]' do
      context 'value types' do
        it '(String)' do
          element[:string] = 'words'
          element[:string].should == 'words'
        end

        it '(Array)' do
          a = [10, 'elements']
          element[:array] = a
          element[:array].should == a
        end

        it '(Hash)' do
          h = { :elements => 10 }
          element[:hash] = h
          element[:hash].should == h
        end

        it '(Time)' do
          time = Time.utc 2011, 1, 2, 3, 4, 5
          element[:time] = time
          element[:time].should == time
        end

        it '(Fixnum)' do
          element[:number] = 123
          element[:number].should == 123
        end

        it '(Float)' do
          element[:float] = 12.345
          element[:float].should == 12.345
        end

        it '(Bignum)' do
          element[:big] = 123321123321123321123321123321123321
          element[:big].should == 123321123321123321123321123321123321
        end

        it "('')" do
          element[:name] = ''
          element[:name].should be_nil
          element.property_keys.should_not include('name')
        end

        it '(nil)' do
          element[:name] = nil
          element[:name].should be_nil
          element.property_keys.should_not include('name')
        end
      end

      context 'key types' do
        it 'String' do
          element['name'].should == element[:name]
        end

        it 'Fixnum' do
          element[123] = 'value'
          element[123].should == 'value'
        end
      end
    end

    describe '#result', :transactions => false do
      subject { element.result }
      it { should equal(element) }
    end

    describe '#from_graph?' do
      context 'same graph' do
        subject { element.from_graph? graph }
        it { should be_true }
      end
      context 'different graph' do
        subject { element.from_graph? graph2 }
        it { should be_false }
      end
    end

    describe '#properties' do
      before do
        element.properties = { :a => 'valuea', :b => 'valueb' }
      end
      subject { element.properties }
      it { should be_a(Hash) }
      its(:count) { should == 2 }
      it 'should have the correct vales' do
        element.properties['a'].should == 'valuea'
        element.properties['b'].should == 'valueb'
        element[:a].should == 'valuea'
        element[:b].should == 'valueb'
      end
      it 'should not affect the element if returned values are changed' do
        element.properties['a'].gsub!(/value/, 'oops')
        element.properties['a'].should == 'valuea'
        element[:a].should == 'valuea'
      end
      it 'should not affect the element if returned keys are changed' do
        element.properties.delete('a')
        element.properties['a'].should == 'valuea'
        element[:a].should == 'valuea'
      end
      it 'should not affect the element if something is added' do
        element.properties['c'] = 'something'
        element[:c].should be_nil
      end
      context 'existing properties' do
        before do
          element.properties = { :a => 'new value', :c => 'value c' }
        end
        its(:count) { should == 2 }
        it 'should have the correct values' do
          element[:a].should == 'new value'
          element[:b].should be_nil
          element[:c].should == 'value c'
        end
      end
    end

    subject { element }
    its(:element_id) { should_not be_nil }
    #its(:to_a) { should == [element] }
  end
end

Run.all do
  it_uses Pacer::Wrappers::ElementWrapper do
    let(:v0) { graph.create_vertex :name => 'eliza' }
    let(:v1) { graph.create_vertex :name => 'darrick' }
    let(:e0) { graph.create_edge nil, v0, v1, :links }
    let(:e1) { graph.create_edge nil, v0, v1, :relinks }
  end

  context 'vertex' do
    let(:v0) { graph.create_vertex :name => 'eliza' }
    subject { v0 }
    its(:class) { should == Pacer::Wrappers::VertexWrapper  }
  end

  context 'edge' do
    let(:v0) { graph.create_vertex :name => 'eliza' }
    let(:v1) { graph.create_vertex :name => 'darrick' }
    let(:e0) { graph.create_edge nil, v0, v1, :links }
    subject { e0 }
    its(:class) { should == Pacer::Wrappers::EdgeWrapper }
  end
end
Run.all do
  # This runs about 500 specs, basically it should test all the ways
  # that wrappers act the same as native elements
  describe 'wrapped elements' do
    it_uses Pacer::Wrappers::ElementWrapper do
      let(:v0) { graph.create_vertex(Tackle::SimpleMixin, :name => 'eliza') }
      let(:v1) { graph.create_vertex(Tackle::SimpleMixin, :name => 'darrick') }
      let(:e0) { graph.create_edge nil, v0, v1, :links, Tackle::SimpleMixin }
      let(:e1) { graph.create_edge nil, v0, v1, :relinks, Tackle::SimpleMixin }
    end
  end
end

describe Pacer, '.wrap_vertex' do
  before { Pacer.edge_wrapper Tackle::SimpleMixin }
  subject { Pacer.vertex_wrapper Tackle::SimpleMixin }
  its(:name) { should =~ /^Pacer::Wrap::/ }
  its(:ancestors) { should include Pacer::Wrappers::VertexWrapper }
end

describe Pacer, '.wrap_vertex' do
  before { Pacer.vertex_wrapper Tackle::SimpleMixin }
  subject { Pacer.edge_wrapper Tackle::SimpleMixin }
  its(:name) { should =~ /^Pacer::Wrap::/ }
  its(:ancestors) { should include Pacer::Wrappers::EdgeWrapper }
end

Run.tg :read_only do
  use_pacer_graphml_data :read_only

  describe Pacer::Wrappers::ElementWrapper do
    subject { Pacer.vertex_wrapper Tackle::SimpleMixin }

    its(:name) { should =~ /^Pacer::Wrap::/ }
    its(:extensions) { should == [Tackle::SimpleMixin] }

    describe '.clear_cache' do
      before do
        subject.const_set :ORIGINAL, true
        Pacer.vertex_wrapper(Tackle::SimpleMixin).const_defined?(:ORIGINAL).should be_true
        Pacer::Wrappers::ElementWrapper.clear_cache
      end

      it 'should get rid of the Pacer::Wrap namespace' do
        Pacer.const_defined?(:Wrap).should be_false
      end

      it 'should not be the same object if redefined' do
        # if the wrapper is redefined identically, you can't use a normal
        # comparison to see if it's actually been redefined.
        Pacer.vertex_wrapper(Tackle::SimpleMixin).const_defined?(:ORIGINAL).should be_false
      end
    end

    describe 'extension ordering' do
      before do
        Pacer::Wrappers::ElementWrapper.clear_cache
      end
      subject { Pacer.vertex_wrapper TP::Person, Tackle::SimpleMixin, TP::Coder }

      its(:extensions) { should == [TP::Person, Tackle::SimpleMixin, TP::Coder]  }
      it 'should have the ancestors set in the correct order' do
        # Ruby searches for methods down this list, so order is
        # important for method overrides.
        subject.ancestors[0...6].should == [
          Pacer::Wrap::VertexWrapperTP_PersonTackle_SimpleMixinTP_Coder,
          TP::Coder::Route,
          Tackle::SimpleMixin::Vertex,
          Tackle::SimpleMixin::Route,
          TP::Person::Route,
          Pacer::Wrappers::VertexWrapper,
        ]
      end

      it 'should preserve the order once it is established for that combination of extensions' do
        subject.ancestors.should == Pacer.vertex_wrapper(TP::Coder, TP::Person, Tackle::SimpleMixin).ancestors
      end

      context 'should preserve extension order if a route uses the wrapper and adds more extensions' do
        let(:wrapper) { Pacer.vertex_wrapper TP::Person, Tackle::SimpleMixin, TP::Coder }
        subject do
          route = graph.v(wrapper, Pacer::Utils::TSort)
          first = route.first
          first.should_not be_nil
          first.class
        end

        it 'should have ancestors in the correct order' do
          subject.ancestors[0...9].should == [
            Pacer::Wrap::VertexWrapperTP_PersonTackle_SimpleMixinTP_CoderPacer_Utils_TSort,
            Pacer::Utils::TSort::Vertex,
            Pacer::Utils::TSort::Route,
            TSort,
            TP::Coder::Route,
            Tackle::SimpleMixin::Vertex,
            Tackle::SimpleMixin::Route,
            TP::Person::Route,
            Pacer::Wrappers::VertexWrapper,
          ]
        end
      end

      context 'should preserve extension order in a block filter' do
        subject do
          klass = nil
          route = graph.v(TP::Person, Tackle::SimpleMixin, TP::Coder) { |e| klass = e.class }
          route.first.should_not be_nil
          klass
        end

        it 'should have ancestors in the correct order' do
          subject.ancestors[0...6].should == [
            Pacer::Wrap::VertexWrapperTP_PersonTackle_SimpleMixinTP_Coder,
            TP::Coder::Route,
            Tackle::SimpleMixin::Vertex,
            Tackle::SimpleMixin::Route,
            TP::Person::Route,
            Pacer::Wrappers::VertexWrapper,
          ]
        end
      end

      context 'should be in a different order if cleared and defined differently' do
        before { Pacer::Wrappers::ElementWrapper.clear_cache }
        subject { Pacer.vertex_wrapper Tackle::SimpleMixin, TP::Person, TP::Coder }

        its(:extensions) { should == [Tackle::SimpleMixin, TP::Person, TP::Coder]  }
        it 'should have the ancestors set in the correct order' do
          # Ruby searches for methods down this list, so order is
          # important for method overrides.
          subject.ancestors[0...6].should == [
            Pacer::Wrap::VertexWrapperTackle_SimpleMixinTP_PersonTP_Coder,
            TP::Coder::Route,
            TP::Person::Route,
            Tackle::SimpleMixin::Vertex,
            Tackle::SimpleMixin::Route,
            Pacer::Wrappers::VertexWrapper,
          ]
        end

        context 'should preserve extension order if a route adds more extensions' do
          subject do
            klass = nil
            route = graph.v(Tackle::SimpleMixin, TP::Person, TP::Coder) { |e| klass = e.class }
            route.first.should_not be_nil
            klass
          end

          it { should_not be_nil }
          it 'should have ancestors in the correct order' do
            subject.ancestors[0...6].should == [
              Pacer::Wrap::VertexWrapperTackle_SimpleMixinTP_PersonTP_Coder,
              TP::Coder::Route,
              TP::Person::Route,
              Tackle::SimpleMixin::Vertex,
              Tackle::SimpleMixin::Route,
              Pacer::Wrappers::VertexWrapper,
            ]
          end
        end
      end
    end
  end
end
