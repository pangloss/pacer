require 'spec_helper'

Run.tg(:read_only) do
  use_pacer_graphml_data(:read_only)

  describe Pacer::Filter::LoopFilter do
    describe '#repeat' do
      it 'should apply the route part twice' do
        route = graph.v.repeat(2) { |tail| tail.out_e.in_v }.inspect
        route.should == graph.v.out_e.in_v.out_e.in_v.inspect
      end

      it 'should apply the route part 3 times' do
        route = graph.v.repeat(3) { |tail| tail.out_e.in_v }.inspect
        route.should == graph.v.out_e.in_v.out_e.in_v.out_e.in_v.inspect
      end

      describe 'with a range' do
        before { pending }
        let(:start) { graph.vertex(0).v }
        subject { start.repeat(1..3) { |tail| tail.out_e.in_v[0] } }

        it 'should be equivalent to executing each path separately' do
          subject.to_a.should == [start.out_e.in_v.first,
                                  start.out_e.in_v.out_e.in_v.first,
                                  start.out_e.in_v.out_e.in_v.out_e.in_v.first]
        end

        #it { should be_a(BranchedRoute) }
        its(:back) { should be_a_vertices_route }
        its('back.pipe_class') { should == Pacer::Pipes::IdentityPipe }
        its('back.back') { should be_nil }
      end
    end
  end
end
