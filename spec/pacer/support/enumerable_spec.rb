require 'spec_helper'

describe Enumerable do
  describe '#one?' do
    it 'should be true if there is one element' do
      [:x].one?.should be_true
    end

    it 'should be false if there are no elements' do
      [].one?.should be_false
    end

    it 'should be false if there are 2 elements' do
      [:a, :b].one?.should be_false
    end

    it 'should be false if there are lots of elements' do
      ([:a, :b] * 100).one?.should be_false
    end
  end

  describe '#many?' do
    it 'should be false if there is one element' do
      [:x].many?.should be_false
    end

    it 'should be false if there are no elements' do
      [].many?.should be_false
    end

    it 'should be true if there are 2 elements' do
      [:a, :b].many?.should be_true
    end

    it 'should be true if there are lots of elements' do
      ([:a, :b] * 100).many?.should be_true
    end
  end

  describe '#to_hashset' do
    it 'should return an empty hashset' do
      [].to_hashset.should == java.util.HashSet.new
    end

    it 'should not clone an existing hashset' do
      hs = java.util.HashSet.new
      hs.to_hashset.should equal(hs)
    end

    it 'should create a hashset from an array' do
      hs = java.util.HashSet.new
      hs.add 'a'
      hs.add 'b'
      ['a', 'b', 'a'].to_hashset.should == hs
    end

    it 'should create a hashset from an arraylist' do
      hs = java.util.HashSet.new
      hs.add 'a'
      hs.add 'b'
      al = java.util.ArrayList.new
      al.add 'a'
      al.add 'b'
      al.add 'a'
      al.to_hashset.should == hs
    end
  end

  Run.tg do
    use_simple_graph_data

    describe '#to_route' do
      context "from [1, 'a']" do
        context 'with no arguments' do
          subject { [1, 'a'].to_route }
          it { should be_a Pacer::Core::Route }
          its(:element_type) { should == :object }
          its(:to_a) { should == [1, 'a'] }
        end

        context 'based on an object route' do
          subject { [1, 'a'].to_route(:based_on => graph.v[:name]) }
          it { should be_a Pacer::Core::Route }
          its(:element_type) { should == :object }
          its(:to_a) { should == [1, 'a'] }
        end

        context 'based on an object route with an extension' do
          subject { [1, 'a'].to_route(:based_on => graph.v[:name].add_extensions([Tackle::SimpleMixin])) }
          it { should be_a Pacer::Core::Route }
          its(:extensions) { should == [Tackle::SimpleMixin] }
          its(:element_type) { should == :object }
          its(:to_a) { should == [1, 'a'] }
        end
      end

      context 'from [elements]' do
        let(:elements) { [v0, v1] }

        context 'based on an element route' do
          subject { elements.to_route(:based_on => graph.v) }
          its(:element_type) { should == graph.element_type(:vertex) }
          its(:to_a) { should == elements }
        end

        context 'based on an extended element route' do
          subject { elements.to_route(:based_on => graph.v(Tackle::SimpleMixin)) }
          its(:extensions) { should == [Tackle::SimpleMixin] }
          its(:element_type) { should == graph.element_type(:vertex) }
          its(:to_a) { should == elements }
        end
      end
    end
  end
end
