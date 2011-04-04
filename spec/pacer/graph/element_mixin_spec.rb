require 'spec_helper'

unless defined? ElementMixinSpec
ElementMixinSpec = true

shared_examples_for Pacer::ElementMixin do
  context 'vertex' do
    subject { v0 }
    it { should be_a(Pacer::Core::Graph::VerticesRoute) }
    it { should be_a(Pacer::ElementMixin) }
    it { should be_a(Pacer::VertexMixin) }
    it { should_not be_a(Pacer::EdgeMixin) }

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
        its(:extensions) { should == Set[Tackle::SimpleMixin] }
      end
    end

    describe '#e' do
      it 'is unsupported' do
        expect { v0.e }.to raise_error(Pacer::UnsupportedOperation)
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
    it { should be_a(Pacer::ElementMixin) }
    it { should be_a(Pacer::EdgeMixin) }
    it { should_not be_a(Pacer::VertexMixin) }

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
        its(:extensions) { should == Set[Tackle::SimpleMixin] }
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
    context '', :transactions => false do
      # FIXME: Neo4j edges are flaky sometimes when inside a
      # transaction. If you look them up by id, they are not found.
      its(:to_a) { should == [element] }
      its(:element) { should == element }
    end
  end
end
end

for_each_graph do
  it_uses Pacer::ElementMixin do
    let(:v0) { graph.create_vertex :name => 'eliza' }
    let(:v1) { graph.create_vertex :name => 'darrick' }
    let(:e0) { graph.create_edge nil, v0, v1, :links }
    let(:e1) { graph.create_edge nil, v0, v1, :relinks }
  end

  context 'vertex' do
    let(:v0) { graph.create_vertex :name => 'eliza' }
    subject { v0 }
    it { should_not be_a(Pacer::Wrappers::ElementWrapper) }
  end

  context 'edge' do
    let(:v0) { graph.create_vertex :name => 'eliza' }
    let(:v1) { graph.create_vertex :name => 'darrick' }
    let(:e0) { graph.create_edge nil, v0, v1, :links }
    subject { e0 }
    it { should_not be_a(Pacer::Wrappers::ElementWrapper) }
  end
end
