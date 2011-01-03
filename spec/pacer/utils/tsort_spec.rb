require 'spec_helper'

describe Pacer::Utils::TSort do
  let(:graph) { Pacer.tg }

  context 'single vertex' do
    before do
      graph.create_vertex
    end
    let(:node) { graph.v(Pacer::Utils::TSort).first }

    describe 'tsort()' do
      subject { node.tsort }
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
      [eggs, bacon].to_route.add_edges_to :requires, cook
      cook.add_edges_to :requires, serve
      serve.add_edges_to :requires, breakfast
    end
  end
end
