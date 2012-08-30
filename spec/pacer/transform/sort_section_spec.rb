require 'spec_helper'

Run.tg :read_only do
  use_pacer_graphml_data :read_only

  let(:unsorted) { graph.v.out.out }

  describe 'sort by name' do
    let(:by_name) do
      graph.v.section(:x).out.out.sort_section(:x) { |v| v[:name] }
    end

    it 'should have the same elements' do
      by_name.group_count.should == unsorted.group_count
    end

    it 'should have 3 elements in the path' do
      by_name.paths.each do |path|
        path.length.should == 3
      end
    end
  end

  describe 'sort with more info' do
    let(:unsorted) { graph.v.out.out }
    let(:yielded) { [] }
    let(:with_path) do
      graph.v.section(:x).out.out.sort_section(:x) do |v, section, path|
        yielded << [v, section, path]
        [path[-2][:name], v[:name]]
      end
    end

    it 'should have the same elements' do
      with_path.group_count.should == unsorted.group_count
    end

    it 'should have 3 elements in the path' do
      with_path.paths.each do |path|
        path.length.should == 3
      end
    end

    it 'should yield' do
      with_path.first.should_not be_nil
      yielded.length.should == 1
    end
  end

  describe 'sort by values' do
    let :by_value do
      graph.v.section(:x).out.out.element_ids.sort_section(:x)
    end
    it 'should work with no block' do
      by_value.to_a.should_not be_empty
    end
  end
end
