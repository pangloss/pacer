require 'spec_helper'

describe RouteOperations do
  before :all do
    @g = Pacer.tg 'spec/data/pacer.graphml'
  end

  describe '#uniq' do
    it 'should be a route' do
      @g.v.uniq.should be_an_instance_of(FilterRoute)
    end

    it 'results should be unique' do
      @g.e.in_v.group_count(:name).values.sort.last.should > 1
      @g.e.in_v.uniq.group_count(:name).values.sort.last.should == 1
    end
  end

  describe '#random' do
    it { Set[*@g.v.random(1)].should == Set[*@g.v] }
    it { @g.v.random(0).to_a.should == [] }
    it 'should have some number of elements more than 1 and less than all' do
      range = 1..(@g.v.count - 1)
      range.should include(@g.v.random(0.5).count)
    end
  end

  describe '#as' do
    it 'should set the variable to the correct node' do
      vars = Set[]
      @g.v.as(:a_vertex).in_e(:wrote) { |edge| vars << edge.vars[:a_vertex] }.count
      vars.should == Set[*@g.e(:wrote).in_v]
    end

    it 'should not break path generation' do
      who_wrote_what = nil
      @g.v.as(:who).in_e(:wrote).as(:wrote).out_v.as(:what).v { |v| who_wrote_what = [@g, v.vars[:who], v.vars[:wrote], v.vars[:what]] }.paths.each do |path|
        path.to_a.should == who_wrote_what
      end
    end
  end

  describe '#repeat' do
    it 'should apply the route part twice' do
      route = @g.v.repeat(2) { |tail| tail.out_e.in_v }.inspect
      route.should == @g.v.out_e.in_v.out_e.in_v.inspect
    end

    it 'should apply the route part 3 times' do
      route = @g.v.repeat(3) { |tail| tail.out_e.in_v }.inspect
      route.should == @g.v.out_e.in_v.out_e.in_v.out_e.in_v.inspect
    end

    describe 'with a range' do
      let(:start) { @g.vertex(0).v }
      subject { start.repeat(1..3) { |tail| tail.out_e.in_v[0] } }

      it 'should be equivalent to executing each path separately' do
        subject.to_a.should == [start.out_e.in_v.first,
                                start.out_e.in_v.out_e.in_v.first,
                                start.out_e.in_v.out_e.in_v.out_e.in_v.first]
      end

      it { should be_a(BranchedRoute) }
      its(:back) { should be_a(VerticesIdentityRoute) }
      its('back.back') { should be_nil }
    end
  end

  describe :delete! do
    it 'should not try to delete an element twice'
  end
end
