require 'spec_helper'

Run.tg(:read_only) do
  use_pacer_graphml_data(:read_only)

  describe 'UniqFilter' do
    describe '#uniq' do
      it 'should be a route' do
        graph.v.uniq.should be_an_instance_of(Pacer::Route)
      end

      it 'results should be unique' do
        graph.e.in_v.group_count(:name).values.sort.last.should > 1
        graph.e.in_v.uniq.group_count(:name).values.sort.last.should == 1
      end
    end
  end
end
