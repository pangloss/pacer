require 'spec_helper'

describe Pacer::Core::Route do
  let(:base_route) { [1, 2, 3].to_route }
  subject { base_route }

  its(:back) { should be_nil }

  # TODO: move graph-specific stuff to Pacer::Core::Graph::(something)

  it { should be_root }

  its(:hide_elements) { should_not be_true }

  describe '#route' do
    subject { base_route.route }
    it { should equal(base_route) }
    its(:hide_elements) { should be_true }
  end

  its(:vars) { should == {} }


  describe '#each' do
    context 'without block' do
      subject { base_route.each }
      it { should be_a com.tinkerpop.pipes.Pipe }
    end
  end

  describe '#each_path' do
    context 'without block' do
      subject { base_route.each_path }
      it { should be_a com.tinkerpop.pipes.Pipe }
    end
  end

  describe '#each_object' do
    context 'without block' do
      subject { base_route.each_object }
      it { should be_a com.tinkerpop.pipes.Pipe }
    end
  end

  describe '#inspect' do
    subject { base_route.inspect }
    it { should == '#<Obj>' }

    describe 'with route elements visible' do
      before :all do
        # objectspace is required for rr mocks.
        @cols = Pacer.columns
        @limit = Pacer.inspect_limit
        JRuby.objectspace = true
        Pacer.hide_route_elements = false
      end
      after :all do
        Pacer.columns = @cols
        Pacer.inspect_limit = @limit
        JRuby.objectspace = false
        Pacer.hide_route_elements = true
      end
      specify 'default setting' do
        mock(base_route).puts '1 2 3'
        mock(base_route).puts 'Total: 3'
        base_route.inspect.should == '#<Obj>'
      end
      specify '4 column display' do
        Pacer.columns = 4
        mock(base_route).puts '1 2'
        mock(base_route).puts '3'
        mock(base_route).puts 'Total: 3'
        base_route.inspect.should == '#<Obj>'
      end
      specify 'aligned columns' do
        Pacer.columns = 6
        route = [-1, 0, 1, 2].to_route
        mock(route).puts '-1 0 '
        mock(route).puts '1  2 '
        mock(route).puts 'Total: 4'
        route.inspect.should == '#<Obj>'
      end
      specify '2 item limit' do
        Pacer.inspect_limit = 2
        dont_allow(base_route).puts(anything)
        base_route.inspect.should == '#<Obj>'
      end
    end
  end

  describe '#==' do
    it { should == subject }
    it { should_not == [].to_route }
  end
end
