require 'spec_helper'

shared_examples_for Pacer::Core::Graph::ElementRoute do
  describe '#properties' do
    subject { r.properties }
    its(:count) { should == r.count }
    its(:element_type) { should == Object }
    specify 'should all be hashes' do
      props = subject.each
      elements = r.each
      elements.zip(props.to_a).each do |e, p|
        e.properties.should == p
      end
    end
  end

  context 'with extensions' do
    let(:route) { r.add_extension(Tackle::SimpleMixin) }
    describe '#each without a block' do
      subject { route.each_element }
      specify 'elements should be wrapped' do
        subject.first.extensions.should include(Tackle::SimpleMixin)
      end
    end
  end
end

Run.all(:read_only) do
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
