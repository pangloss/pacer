require 'spec_helper'

describe Pacer::ElementMixin do
  let(:graph) { Pacer.tg }
  let(:graph) { Pacer.tg }
  let(:v0) { graph.create_vertex :name => 'eliza' }
  let(:v1) { graph.create_vertex :name => 'darrick' }
  let(:e0) { graph.create_edge '0', v0, v1, :links }
  let(:e1) { graph.create_edge '1', v0, v1, :relinks }

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
      context '()' do
        subject { e0.e }
        its(:to_a) { should == [e0] }
        it { should be_a(Pacer::Routes::EdgesRoute) }
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
end
