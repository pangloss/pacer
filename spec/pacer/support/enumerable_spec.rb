require 'spec_helper'

describe Enumerable do
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
end
