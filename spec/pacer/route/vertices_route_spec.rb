require 'spec_helper'

for_tg(:read_only) do
  describe VerticesRoute do
    use_pacer_graphml_data(:read_only)

    describe '#out_e' do
      it { graph.v.out_e.should be_an_edges_route }
      it { graph.v.out_e(:label).should be_a(Pacer::Route) }
      it { graph.v.out_e(:label) { |x| true }.should be_a(Pacer::Route) }
      it { graph.v.out_e { |x| true }.should be_a(Pacer::Route) }

      it { Set[*graph.v.out_e].should == Set[*graph.edges] }

      it { graph.v.out_e.count.should >= 1 }

      specify 'with label filter should work with path generation' do
        r = graph.v.out_e.in_v.in_e { |e| e.label == 'wrote' }.out_v
        paths = r.paths
        paths.first.should_not be_nil
        graph.v.out_e.in_v.in_e(:wrote).out_v.paths.map(&:to_a).should == paths.map(&:to_a)
      end
    end
  end
end

for_tg do
  describe VerticesRoute do
    describe :add_edges_to do
      it 'should not add properties with null values'

      context 'from empty route' do

      end

      context 'to empty array' do

      end

      context 'to nil' do

      end
    end
  end
end
