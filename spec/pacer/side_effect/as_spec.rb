require 'spec_helper'

Run.all(:read_only) do
  use_pacer_graphml_data(:read_only)

  describe '#as' do
    it 'should set the variable to the correct node' do
      vars = Set[]
      graph.v.as(:a_vertex).in_e(:wrote) { |edge| vars << edge.vars[:a_vertex] }.count
      vars.should == Set[*graph.e.e(:wrote).in_v]
    end

    it 'should not break path generation (simple)' do
      who = nil
      r = graph.v.as(:who).in_e(:wrote).out_v.v { |v|
        who = v.vars[:who]
      }.paths
      r.each do |path|
        path.to_a[0].should == who
        path.length.should == 3
      end
    end

    it 'should not break path generation' do
      who_wrote_what = nil
      r = graph.v.as(:who).in_e(:wrote).as(:wrote).out_v.as(:what).v { |v|
        who_wrote_what = [v.vars[:who], v.vars[:wrote], v.vars[:what]]
      }.paths
      r.each do |path|
        path.to_a.should == who_wrote_what
      end
    end
  end
end
