require 'spec_helper'

for_tg(:read_only) do
  context Pacer::Core::Graph::VerticesRoute do
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
        graph.v.out_e.in_v.in_e(:wrote).out_v.paths.collect(&:to_a).should == paths.collect(&:to_a)
      end
    end
  end
end

for_tg do
  use_pacer_graphml_data

  context Pacer::Core::Graph::VerticesRoute do
    describe :add_edges_to do
      let(:pangloss) { graph.v(:name => 'pangloss') }
      let(:pacer) { graph.v(:name => 'pacer') }

      context '1 to 1' do
        before do
          setup_data
          @result = pangloss.add_edges_to(:likes, pacer, :pros => "it's fast", :cons => nil)
        end

        subject { graph.edge(@result) }

        it { should_not be_nil }
        its(:out_vertex) { should == pangloss.first }
        its(:in_vertex) { should == pacer.first }
        its(:label) { should == 'likes' }

        it 'should store properties' do
          subject[:pros].should == "it's fast"
        end

        it 'should not add properties with null values' do
          subject.getPropertyKeys.should_not include('cons')
        end
      end

      context 'from empty route' do

      end

      context 'to empty array' do

      end

      context 'to nil' do

      end
    end
  end
end
