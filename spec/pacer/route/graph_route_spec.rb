require 'spec_helper'

for_each_graph do
  describe Pacer::Core::Graph::GraphRoute do
    describe '#v' do
      subject { graph.v }
      it { should be_an_instance_of(VerticesRoute) }
    end

    describe '#e' do
      subject { graph.e }
      it { should be_an_instance_of(EdgesRoute) }
    end

    subject { graph }
    it { should_not be_a(RouteOperations) }
  end
end
