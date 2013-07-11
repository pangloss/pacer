require 'spec_helper'

Run.tg(:read_only) do
  use_pacer_graphml_data(:read_only)

  describe Pacer::Filter::ObjectFilter do
    it '#is' do
      [1, 2, 3, 2, 3].to_route.is(2).to_a.should == [2, 2]
    end

    it '#is_not' do
      [1, 2, 3, 2, 3].to_route.is_not(2).to_a.should == [1, 3, 3]
    end

    it '#compact' do
      [1, nil, 2, 3].to_route.compact.to_a.should == [1, 2, 3]
    end

    describe '#vertex filter' do

      let (:filter_node) { graph.v.first }
    
      it "#is" do
        all_nodes = graph.v.to_a.select { |n| n.getId != filter_node.getId }
        graph.v.is_not(filter_node).to_a.should == all_nodes
      end

      it "#is_not" do
        graph.v.is(filter_node).to_a.should == [filter_node]
      end

    end
  end

end
