require 'spec_helper'

for_each_graph(:read_only) do
  use_pacer_graphml_data(:read_only)

  context Pacer::Core::Graph::EdgesRoute do
    subject { graph.e }
    it { should be_a Pacer::Core::Graph::EdgesRoute }
    its(:count) { should == 14 }

    describe '#out_v' do
      subject { graph.e.out_v }
      it { should be_a Pacer::Core::Graph::VerticesRoute }
      its(:count) { should == 14 }
    end

    describe '#in_v' do
      subject { graph.e.in_v }
      it { should be_a Pacer::Core::Graph::VerticesRoute }
      its(:count) { should == 14 }
    end

    describe '#both_v' do
      subject { graph.e.both_v }
      it { should be_a Pacer::Core::Graph::VerticesRoute }
      its(:count) { should == 28 }
    end

    describe '#e' do
      subject { graph.e.e }
      it { should be_a Pacer::Core::Graph::EdgesRoute }
      its(:count) { should == 14 }
    end

    describe '#labels' do
      subject { graph.e.labels }
      it { should be_a Pacer::Core::Route }
      its(:element_type) { should == Object }
      its(:count) { should == 14 }
    end

    describe '#to_h' do
      subject { graph.e.to_h }
      let(:okram) { graph.v(:name => 'okram').first }

      it { should be_a Hash }
      specify 'okram key has all outward related vertices in an array as the value' do
        subject[okram].sort_by { |v| v.element_id }.should == okram.out_e.in_v.to_a.sort_by { |v| v.element_id }
      end
    end
  end
end
