require 'spec_helper'

# New tests:
Run.tg(:read_only) do
  use_pacer_graphml_data(:read_only)

  describe RouteOperations do
    describe '#most_frequent' do
      context '()' do
        subject { graph.v[:type].most_frequent }
        it { should == 'project' }
      end

      context '(0)' do
        subject { graph.v[:type].most_frequent(0) }
        it { should == 'project' }
      end

      context '(1)' do
        subject { graph.v[:type].most_frequent(1) }
        it { should == 'person' }
      end

      context '(0..1)' do
        subject { graph.v[:type].most_frequent(0..1) }
        it { should be_a Pacer::Core::Route }
        its(:element_type) { should == Object }
        its(:to_a) { should == ['project', 'person'] }
      end

      context '(0, true)' do
        subject { graph.v[:type].most_frequent(0, true) }
        it { should == ['project', 4] }
      end

      context '(1, true)' do
        subject { graph.v[:type].most_frequent(1, true) }
        it { should == ['person', 2] }
      end

      context '(0..1, true)' do
        subject { graph.v[:type].most_frequent(0..1, true) }
        it { should == [['project', 4], ['person', 2]] }
      end
    end
  end
end

Run.tg do
  use_pacer_graphml_data

  describe RouteOperations do
    before do
      setup_data
    end

    describe '#build_index' do
      context "('new_index', 'k') { count += 1 }", :transactions => true do
        it 'should build the index with raw elements' do
          count = 0
          index = graph.v.build_index('new_index', 'k', 'name')
          index.should_not be_nil
          index.get('k', 'pangloss').count.should == 1
        end

        it 'should build the index with wrapped elements' do
          count = 0
          index = graph.v(TP::Person).build_index('new_index', 'k', 'name')
          index.should_not be_nil
          index.get('k', 'pangloss').count.should == 1
        end

        it 'should do nothing if there are no elements' do
          count = 0
          index = graph.v.limit(0).build_index('new_index', 'k', 'name')
          index.should be_nil
        end

        after do
          graph.dropIndex 'new_index'
        end
      end
    end
  end
end


# Modernize these old tests:
describe RouteOperations do
  before :all do
    @g = Pacer.tg 'spec/data/pacer.graphml'
  end

  describe '#as' do
    it 'should set the variable to the correct node' do
      vars = Set[]
      @g.v.as(:a_vertex).in_e(:wrote) { |edge| vars << edge.vars[:a_vertex] }.count
      vars.should == Set[*@g.e.e(:wrote).in_v]
    end

    it 'should not break path generation (simple)' do
      who = nil
      r = @g.v.as(:who).in_e(:wrote).out_v.v { |v|
        who = v.vars[:who]
      }.paths
      r.each do |path|
        path.to_a[0].should == @g
        path.to_a[1].should == who
        path.length.should == 4
      end
    end

    it 'should not break path generation' do
      who_wrote_what = nil
      r = @g.v.as(:who).in_e(:wrote).as(:wrote).out_v.as(:what).v { |v|
        who_wrote_what = [@g, v.vars[:who], v.vars[:wrote], v.vars[:what]]
      }.paths
      r.each do |path|
        path.to_a.should == who_wrote_what
      end
    end
  end

  describe '#repeat' do
    pending 'switch to using loop'

    #it 'should apply the route part twice' do
    #  route = @g.v.repeat(2) { |tail| tail.out_e.in_v }.inspect
    #  route.should == @g.v.out_e.in_v.out_e.in_v.inspect
    #end

    #it 'should apply the route part 3 times' do
    #  route = @g.v.repeat(3) { |tail| tail.out_e.in_v }.inspect
    #  route.should == @g.v.out_e.in_v.out_e.in_v.out_e.in_v.inspect
    #end

    #describe 'with a range' do
    #  let(:start) { @g.vertex(0).v }
    #  subject { start.repeat(1..3) { |tail| tail.out_e.in_v[0] } }

    #  it 'should be equivalent to executing each path separately' do
    #    subject.to_a.should == [start.out_e.in_v.first,
    #                            start.out_e.in_v.out_e.in_v.first,
    #                            start.out_e.in_v.out_e.in_v.out_e.in_v.first]
    #  end

    #  #it { should be_a(BranchedRoute) }
    #  its(:back) { should be_a_vertices_route }
    #  its('back.pipe_class') { should == Pacer::Pipes::IdentityPipe }
    #  its('back.back') { should be_nil }
    #end
  end

  describe :delete! do
    it 'should not try to delete an element twice'
  end
end
