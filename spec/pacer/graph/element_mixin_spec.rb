require 'spec_helper'

shared_examples_for Pacer::ElementMixin do
  let(:v0) { graph.create_vertex :name => 'eliza' }
  let(:v1) { graph.create_vertex :name => 'darrick' }
  let(:e0) { graph.create_edge nil, v0, v1, :links }
  let(:e1) { graph.create_edge nil, v0, v1, :relinks }

  context 'vertex' do
    subject { v0 }
    it { should be_a(Pacer::Routes::VerticesRouteModule) }
    it { should be_a(Pacer::ElementMixin) }
    it { should be_a(Pacer::VertexMixin) }
    it { should_not be_a(Pacer::EdgeMixin) }
    it { should_not be_a(Pacer::ElementWrapper) }

    describe '#v' do
      context '()' do
        subject { v0.v }
        its(:to_a) { should == [v0] }
        it { should be_a(Pacer::Routes::VerticesRoute) }
      end

      context '(:name => "eliza")' do
        subject { v0.v(:name => 'eliza') }
        its(:to_a) { should == [v0] }
        it { should be_a(Pacer::Routes::VerticesRoute) }
      end

      context '(:name => "other")' do
        subject { v0.v(:name => 'other') }
        its(:to_a) { should == [] }
        it { should be_a(Pacer::Routes::VerticesRoute) }
      end

      context '(SimpleMixin)' do
        subject { v0.v(Tackle::SimpleMixin) }
        its(:to_a) { should == [v0] }
        it { should be_a(Pacer::Routes::VerticesRoute) }
        its(:extensions) { should == Set[Tackle::SimpleMixin] }
      end
    end

    describe '#e' do
      it 'is unsupported' do
        expect { v0.e }.to raise_error(Pacer::UnsupportedOperation)
      end
    end
  end

  context 'edge' do
    subject { e0 }
    it { should be_a(Pacer::Routes::EdgesRouteModule) }
    it { should be_a(Pacer::ElementMixin) }
    it { should be_a(Pacer::EdgeMixin) }
    it { should_not be_a(Pacer::VertexMixin) }
    it { should_not be_a(Pacer::ElementWrapper) }

    describe '#e', :transactions => false do
      context '()' do
        subject { e0.e }
        its(:to_a) { should == [e0] }
        it(:a => :b) { should be_a(Pacer::Routes::EdgesRoute) }
      end

      context '(:links)' do
        subject { e0.e(:links) }
        its(:to_a) { should == [e0] }
        it { should be_a(Pacer::Routes::EdgesRoute) }
      end

      context '(:other)' do
        subject { e0.e(:other) }
        its(:to_a) { should == [] }
        it { should be_a(Pacer::Routes::EdgesRoute) }
      end

      context '(SimpleMixin)' do
        subject { e0.e(Tackle::SimpleMixin) }
        its(:to_a) { should == [e0] }
        it { should be_a(Pacer::Routes::EdgesRoute) }
        its(:extensions) { should == Set[Tackle::SimpleMixin] }
      end
    end

    describe '#v' do
      it 'is unsupported' do
        expect { e0.v }.to raise_error(Pacer::UnsupportedOperation)
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

        it '(Time)' do
          pending 'property converter'
          time = Time.now
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
          pending 'property converter'
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
    its(:extensions) { should == Set[] }
    its(:element_id) { should_not be_nil }
    context '', :transactions => false do
      # FIXME: Neo4j edges are flaky sometimes when inside a
      # transaction. If you look them up by id, they are not found.
      its(:to_a) { should == [element] }
      its(:element) { should == element }
    end
  end
end

for_each_graph do
  it_uses Pacer::ElementMixin
end
