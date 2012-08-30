require 'spec_helper'

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
end
