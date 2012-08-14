require 'spec_helper'

Run.tg do
  describe Pacer::TinkerGraph do
    let(:v0) { graph.create_vertex }
    let(:v1) { graph.create_vertex }
    let(:e0) { graph.create_edge '0', v0, v1, :default }

    describe '#element_type' do
      context 'invalid' do
        it { expect { graph.element_type(:nothing) }.to raise_error(ArgumentError) }
      end

      context ':vertex' do
        subject { Pacer.tg.element_type(:vertex) }
        it { should == :vertex }
      end

      context 'a vertex' do
        subject { graph.element_type(v0) }
        it { should == :vertex }
      end

      context ':edge' do
        subject { graph.element_type(:edge) }
        it { should == :edge }
      end

      context 'an edge' do
        subject { graph.element_type(e0) }
        it { should == :edge }
      end

      context ':mixed' do
        subject { graph.element_type(:mixed) }
        it { should == :mixed }
      end

      context ':object' do
        subject { graph.element_type(:object) }
        it { should == :object }
      end
    end

    describe '#sanitize_properties' do
      specify 'returns its argument' do
        arg = { :a => 1 }
        graph.sanitize_properties(arg).should equal(arg)
      end
    end

    describe '#in_vertex' do
      it 'should wrap the vertex' do
        v = e0.in_vertex(Tackle::SimpleMixin)
        v.should == v1
        v.extensions.should include(Tackle::SimpleMixin)
      end

      it 'should wrap the vertex 2' do
        v = e0.in_vertex([Tackle::SimpleMixin])
        v.should == v1
        v.extensions.should include(Tackle::SimpleMixin)
      end
    end

    describe '#out_vertex' do
      it 'should wrap the vertex' do
        v = e0.out_vertex(Tackle::SimpleMixin)
        v.should == v0
        v.extensions.should include(Tackle::SimpleMixin)
      end

      it 'should wrap the vertex 2' do
        v = e0.out_vertex([Tackle::SimpleMixin])
        v.should == v0
        v.extensions.should include(Tackle::SimpleMixin)
      end
    end
  end
end
