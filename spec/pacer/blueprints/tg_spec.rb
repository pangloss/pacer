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

      context 'from result' do
        context ':vertex' do
          subject { Pacer.tg.element_type(Pacer.tg.element_type :vertex) }
          it { should == com.tinkerpop.blueprints.pgm.impls.tg.TinkerVertex }
        end

        context ':edge' do
          subject { graph.element_type(Pacer.tg.element_type :edge) }
          it { should == com.tinkerpop.blueprints.pgm.impls.tg.TinkerEdge }
        end

        context ':mixed' do
          subject { graph.element_type(Pacer.tg.element_type :mixed) }
          it { should == com.tinkerpop.blueprints.pgm.impls.tg.TinkerElement }
        end

        context ':object' do
          subject { graph.element_type(Pacer.tg.element_type :object) }
          it { should == Object }
        end
      end

      context 'from index_class' do
        context ':vertex' do
          subject { graph.element_type(graph.index_class :vertex) }
          it { should == com.tinkerpop.blueprints.pgm.impls.tg.TinkerVertex }
        end

        context ':edge' do
          subject { graph.element_type(graph.index_class :edge) }
          it { should == com.tinkerpop.blueprints.pgm.impls.tg.TinkerEdge }
        end
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

    describe '#get_vertices' do
      before { e0 }
      subject { graph.get_vertices }
      it { should be_a(Pacer::Core::Route) }
      its(:count) { should == 2 }
    end

    describe '#get_edges' do
      before { e0 }
      subject { graph.get_edges }
      it { should be_a(Pacer::Core::Route) }
      its(:count) { should == 1 }
    end
  end
end
