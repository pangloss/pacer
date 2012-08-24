require 'spec_helper'

describe '#unique?' do
  it 'should be true if unique' do
    [1, 2, 3].to_route.unique?.should be_true
  end

  it 'should be true if unique' do
    [1, 2, 3, 1, 4].to_route.unique?.should be_false
  end
end
