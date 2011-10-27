require 'spec_helper'

Run.tg(:read_only) do
  use_pacer_graphml_data(:read_only)

  describe 'RandomFilter' do
    describe '#random' do
      it { Set[*graph.v.random(1)].should == Set[*graph.v] }
      it { graph.v.random(0).to_a.should == [] }
      it 'should have some number of elements more than 1 and less than all' do
        range = 1..(graph.v.count - 1)
        range.should include(graph.v.random(0.5).count)
      end
    end
  end
end
