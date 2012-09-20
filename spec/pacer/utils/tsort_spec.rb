require 'spec_helper'

describe Pacer::Utils::TSort do
  let(:graph) { Pacer.tg }

  context 'single vertex' do
    before do
      graph.create_vertex
    end
    let(:node) { graph.v(Pacer::Utils::TSort).first }

    describe 'tsort()' do
      subject { node.tsort.to_a }
      it { should == [node] }
    end
  end

  context 'breakfast example' do
    let(:breakfast) { graph.create_vertex 'breakfast' }
    let(:serve) { graph.create_vertex 'serve' }
    let(:cook) { graph.create_vertex 'cook' }
    let(:eggs) { graph.create_vertex 'buy eggs' }
    let(:bacon) { graph.create_vertex 'buy bacon' }

    before do
      [eggs, bacon].to_route(:graph => graph, :element_type => :vertex).add_edges_to :requires, cook
      cook.add_edges_to :requires, serve
      serve.add_edges_to :requires, breakfast
    end

    context 'whole meal' do
      subject do
        graph.v(Pacer::Utils::TSort).tsort.to_a
      end

      it { should == [ bacon, eggs, cook, serve, breakfast ] }

      it 'should be different from the default order' do
        should_not == graph.v.to_a
      end
    end

    context 'from one vertex' do
      subject do
        graph.v(Pacer::Utils::TSort).only(cook).tsort.to_a
      end

      it { should == [ bacon, eggs, cook ] }
    end
  end

  context 'circular' do
    let(:a) { graph.create_vertex 'a' }
    let(:b) { graph.create_vertex 'b' }
    let(:c) { graph.create_vertex 'c' }

    before do
      a.add_edges_to :needs, b
      b.add_edges_to :needs, c
      c.add_edges_to :needs, a
    end

    it 'should raise a TSort::Cyclic error' do
      proc {
        graph.v(Pacer::Utils::TSort).tsort
      }.should raise_error TSort::Cyclic
    end

    it 'can not TSort a subset of a cyclical graph' do
      proc {
        graph.v(Pacer::Utils::TSort).only([a,b]).tsort.should == [a,b]
      }.should raise_error TSort::Cyclic
    end

    it 'can be worked around with subgraph' do
      vertices = graph.v.only([a,b]).result
      edges = graph.e.lookahead(:min => 2) { |e| e.both_v.only(vertices) }.result
      subgraph = (vertices.to_a + edges.to_a).to_route(:graph => graph, :element_type => :mixed).subgraph
      subgraph.v(Pacer::Utils::TSort).tsort.element_ids.to_a.should == ['a', 'b']
    end

    it 'can be sorted with a custom dependencies block' do
      graph.v(Pacer::Utils::TSort).dependencies { |v| v.in.except(c) }.tsort.to_a.should ==
        [a, b, c]
    end
  end
end
