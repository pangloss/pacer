require 'spec_helper'

shared_examples_for Pacer::Core::Graph::ElementRoute do
  describe '#properties' do
    subject { r.properties }
    its(:count) { should == r.count }
    its(:element_type) { should == Object }
    specify 'should all be hashes' do
      props = subject.each
      elements = r.each
      elements.zip(props).each do |e, p|
        e.properties.should == p
      end
    end
  end
end

for_each_graph(:read_only) do
  use_pacer_graphml_data(:read_only)

  context Pacer::Core::Graph::EdgesRoute, '2' do
    it_uses Pacer::Core::Graph::ElementRoute do
      def r
        graph.e
      end
    end
  end

  context Pacer::Core::Graph::VerticesRoute, '2' do
    it_uses Pacer::Core::Graph::ElementRoute do
      def r
        graph.v
      end
    end
  end
end
