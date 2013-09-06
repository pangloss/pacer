require 'spec_helper'

Run.all(:read_only) do
  use_pacer_graphml_data(:read_only)

  describe '#as_var' do
    it 'should set the variable to the correct node' do
      vars = Set[]
      route = graph.v.as_var(:a_vertex)
      route.in_e(:wrote) { |edge| vars << route.vars[:a_vertex] }.count
      vars.should == Set[*graph.e.e(:wrote).in_v]
    end

    it 'should not break path generation (simple)' do
      who = nil
      r1 = graph.v.as_var(:who)
      r = r1.in_e(:wrote).out_v.v { |v|
        who = r1.vars[:who]
      }.paths
      r.each do |path|
        path.to_a[0].should == who
        path.length.should == 3
      end
    end

    it 'should not break path generation' do
      who_wrote_what = nil
      r1 = graph.v.as_var(:who)
      r = r1.in_e(:wrote).as_var(:wrote).out_v.as_var(:what).v { |v|
        who_wrote_what = [r1.vars[:who], r1.vars[:wrote], r1.vars[:what]]
      }.paths
      r.each do |path|
        path.to_a.should == who_wrote_what
      end
    end
  end
end
