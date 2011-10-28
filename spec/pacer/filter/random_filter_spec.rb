require 'spec_helper'

Run.tg(:read_only) do
  use_pacer_graphml_data(:read_only)

  describe 'RandomFilter' do
    describe '#random' do
      it { Set[*graph.v.random(1)].should == Set[*graph.v] }
      it { graph.v.random(0).to_a.should == [] }
      it 'should usually have some number of elements more than 1 and less than all' do
        range = 1..(graph.v.count - 1)
        best2of3 = (0...3).map { graph.v.random(0.5).count }
        best2of3.select { |num| range.include? num }.length.should >= 2
      end
    end
  end
end
