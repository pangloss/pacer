require 'spec_helper'

for_tg do
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
        it { should == com.tinkerpop.blueprints.pgm.impls.tg.TinkerVertex }
      end

      context 'a vertex' do
        subject { graph.element_type(v0) }
        it { should == com.tinkerpop.blueprints.pgm.impls.tg.TinkerVertex }
      end

      context ':edge' do
        subject { graph.element_type(:edge) }
        it { should == com.tinkerpop.blueprints.pgm.impls.tg.TinkerEdge }
      end

      context 'an edge' do
        subject { graph.element_type(e0) }
        it { should == com.tinkerpop.blueprints.pgm.impls.tg.TinkerEdge }
      end

      context ':mixed' do
        subject { graph.element_type(:mixed) }
        it { should == com.tinkerpop.blueprints.pgm.impls.tg.TinkerElement }
      end

      context ':object' do
        subject { graph.element_type(:object) }
        it { should == Object }
      end
    end
  end
end
