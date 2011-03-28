require 'spec_helper'

describe Pacer::Filter::CollectionFilter do
  context 'on an array of objects' do
    let(:route) { [1,2,3].to_route }

    it 'should filter out an element' do
      route.except(2).to_a.should == [1,3]
    end

    it 'should filter out an array of elements' do
      route.except([2,3]).to_a.should == [1]
    end

    it 'should filter out the elements from another route' do
      route.except([2,3].to_route).to_a.should == [1]
    end
  end
end
