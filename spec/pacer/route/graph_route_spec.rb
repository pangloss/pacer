require 'spec_helper'

for_each_graph do
  describe Pacer::Core::Graph::GraphRoute do
    describe '#v' do
      subject { graph.v }
      it { should be_a_vertices_route }
    end

    describe '#e' do
      subject { graph.e }
      it { should be_an_edges_route }
    end

    subject { graph }
    it { should_not be_a(Pacer::Routes::RouteOperations) }
  end
end
