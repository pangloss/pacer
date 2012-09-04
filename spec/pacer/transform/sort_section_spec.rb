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
    let(:with_path) do
      graph.v.section(:x).out.out.sort_section(:x) do |v, section, path|
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
      yielded = false
      graph.v.section(:x).out_e.in_v.sort_section(:x) do |v, section, path|
        yielded = true
        path.should be_a Array
        path.length.should == 3
        a, b, c = path
        path.each { |e| e.graph.should_not be_nil }
        section.graph.should_not be_nil
        a.should == section
        a.should be_a Pacer::Wrappers::VertexWrapper
        b.should be_a Pacer::Wrappers::EdgeWrapper
        c.should == v
        c.should be_a Pacer::Wrappers::VertexWrapper
      end.first
      yielded.should be_true
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

  it 'should put groups into the correct order' do
    # depends on the order of graph.v(type: 'project') ...
    route = graph.v(type: 'project').section(:proj).out[:name].sort_section(:proj)
    route.to_a.should == %w[
      blueprints
      blueprints
      gremlin
      pipes
      blueprints
      pipes
    ]
  end
end
