require 'spec_helper'

shared_examples_for Pacer::ElementMixin do
  let(:v0) { graph.create_vertex :name => 'eliza' }
  let(:v1) { graph.create_vertex :name => 'darrick' }
  let(:e0) { graph.create_edge nil, v0, v1, :links }
  let(:e1) { graph.create_edge nil, v0, v1, :relinks }

  describe '#extensions' do
    subject { v0.extensions }
    it { should == Set[] }
  end

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

    describe '#e' do
      context '()', :transactions => false do
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

  describe '#[]' do
    context 'value types' do
      it '(String)' do
        v0[:string] = 'words'
        v0[:string].should == 'words'
      end

      it '(Time)' do
        pending 'property converter'
        time = Time.now
        v0[:time] = time
        v0[:time].should == time
      end

      it '(Fixnum)' do
        v0[:number] = 123
        v0[:number].should == 123
      end

      it '(Float)' do
        v0[:float] = 12.345
        v0[:float].should == 12.345
      end

      it '(Bignum)' do
        pending 'property converter'
        v0[:big] = 123321123321123321123321123321123321
        v0[:big].should == 123321123321123321123321123321123321
      end

      it "('')" do
        v0[:name] = ''
        v0[:name].should be_nil
        v0.property_keys.should_not include('name')
      end

      it '(nil)' do
        v0[:name] = nil
        v0[:name].should be_nil
        v0.property_keys.should_not include('name')
      end
    end

    context 'key types' do
      it 'String' do
        v0['name'].should == v0[:name]
      end

      it 'Fixnum' do
        v0[123] = 'value'
        v0[123].should == 'value'
      end
    end
  end
end

for_each_graph do
  it_should_behave_like Pacer::ElementMixin
end
