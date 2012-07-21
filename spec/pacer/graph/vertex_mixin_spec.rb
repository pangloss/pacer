require 'spec_helper'

module VertexMixinSpec
  module Project
    def self.route_conditions
      { :type => 'project' }
    end

    module Vertex
    end
  end

  module IsRuby
    def self.route_conditions
      { :language => 'ruby' }
    end

    module Vertex
    end
  end
end

shared_examples_for Pacer::VertexMixin do
  use_simple_graph_data

  describe '#v' do
    subject { v0.v }
    it { should be_a_vertices_route }
    it { should_not be_a(graph.element_type(:vertex)) }
    it { should_not be_an_instance_of(graph.element_type(:vertex)) }
  end

  describe '#add_extensions' do
    context 'no extensions' do
      subject { v0.add_extensions([]) }
      its('extensions.to_a') { should == [] }
      it { should_not be_a(Pacer::Wrappers::ElementWrapper) }
    end

    context 'with extensions' do
      subject { v0.add_extensions([Tackle::SimpleMixin]) }
      its('extensions.to_a') { should == [Tackle::SimpleMixin] }
      it { should be_a(Pacer::Wrappers::ElementWrapper) }
      it { should be_a(Pacer::Wrappers::VertexWrapper) }
      it { should_not be_a(Pacer::Wrappers::EdgeWrapper) }

      describe '#v' do
        subject { v0.add_extensions([Tackle::SimpleMixin]).v }
        its('extensions.to_a') { should == [Tackle::SimpleMixin] }
        it { should be_a_vertices_route }
        it { should be_a(Tackle::SimpleMixin::Route) }
      end
    end
  end

  describe '#as?' do
    let(:v) { graph.create_vertex type: 'project' }
    context 'Project' do
      subject { v.as?(VertexMixinSpec::Project) }
      it { should be_true }
    end
    context 'IsRuby' do
      subject { v.as?(VertexMixinSpec::IsRuby) }
      it { should_not be_true }
    end
    context 'Project, IsRuby' do
      subject { v.as?(VertexMixinSpec::Project, VertexMixinSpec::IsRuby) }
      it { should_not be_true }
    end
  end

  describe '#as' do
    context 'vertex is a Project' do
      let(:v) { graph.create_vertex type: 'project' }

      it 'should yield a Project' do
        yielded = false
        v.as(VertexMixinSpec::Project) do |v2|
          yielded = true
          v2.should == v
          v2.extensions.should include VertexMixinSpec::Project
          v2.should be_a VertexMixinSpec::Project::Vertex
        end
        yielded.should be_true
      end

      it 'should not yield a IsRuby' do
        yielded = false
        v.as(VertexMixinSpec::IsRuby) do |v2|
          yielded = true
        end
        yielded.should be_false
      end
    end
  end

  describe '#delete!' do
    before do
      @vertex_id = v0.element_id
      v0.delete!
    end
    it 'should be removed' do
      graph.vertex(@vertex_id).should be_nil
    end
  end

  contexts(
  'into new tg' => proc {
    let(:dest) { Pacer.tg }
  },
  'into graph2' => proc {
    before { pending 'support temporary hash indices for clone/copy' unless graph.supports_manual_indices? }
    let(:dest) { graph2 }
  }) do
    describe '#clone_into', :transactions => false do
      subject { v0.clone_into(dest) }
      its(:properties) { should == { 'name' => 'eliza' } }
      its(:graph) { should equal(dest) }
      its('element_id.to_s') { should == v0.element_id.to_s if graph.supports_custom_element_ids? }
    end

    describe '#copy_into', :transaction => false do
      subject { v1.copy_into(dest) }
      its(:properties) { should == { 'name' => 'darrick' } }
      its(:graph) { should equal(dest) }
    end
  end

  subject { v0 }
  its(:graph) { should equal(graph) }
  its(:display_name) { should be_nil }
  its(:inspect) { should =~ /#<[VM]\[#{v0.element_id}\]>/ }
  context 'with label proc' do
    before do
      graph.vertex_name = proc { |e| "some name" }
    end
    its(:display_name) { should == "some name" }
    its(:inspect) { should =~ /#<[VM]\[#{ v0.element_id }\] some name>/ }
  end
  it { should_not == v1 }
  it { should == v0 }
  context 'edge with same element id', :transactions => false do
    it { should_not == e0 }
  end

  context 'with more data' do
    let(:from_v) { graph.create_vertex }
    let(:to_v) { graph.create_vertex }

    before do
      %w[ a a a b b c ].each do |label|
        v = graph.create_vertex
        graph.create_edge nil, from_v, v, label
        graph.create_edge nil, v, to_v, label
      end
    end

    describe '#in_edges' do
      specify 'to_v should have 6 in edges' do
        to_v.in_edges.count.should == 6
      end

      specify 'to_v should have 3 in edges with label a' do
        to_v.in_edges('a').count.should == 3
      end

      specify 'to_v should have 4 in edges with label a or c' do
        to_v.in_edges('a', 'c').count.should == 4
      end

      it 'should add an extension' do
        edge = to_v.in_edges(Tackle::SimpleMixin).first
        edge.should be_a(Pacer::EdgeMixin)
        edge.extensions.should include(Tackle::SimpleMixin)
      end

      it 'should be able to mix labels and mixins as arguments' do
        edge = to_v.in_edges('a', Tackle::SimpleMixin, 'b').first
        edge.should be_a(Pacer::EdgeMixin)
        edge.extensions.should include(Tackle::SimpleMixin)
      end

      it 'should filter correctly with a mix of labels and mixins as arguments' do
        to_v.in_edges('a', Tackle::SimpleMixin, 'b').count.should == 5
      end
    end

    describe '#out_edges' do
      specify 'from_v should have 6 out edges' do
        from_v.out_edges.count.should == 6
      end

      specify 'from_v should have 3 out edges with label a' do
        from_v.out_edges('a').count.should == 3
      end

      specify 'from_v should have 4 out edges with label a or c' do
        from_v.out_edges('a', 'c').count.should == 4
      end

      it 'should add an extension' do
        edge = from_v.out_edges(Tackle::SimpleMixin).first
        edge.should be_a(Pacer::EdgeMixin)
        edge.extensions.should include(Tackle::SimpleMixin)
      end

      it 'should be able to mix labels and mixins as arguments' do
        edge = from_v.out_edges('a', Tackle::SimpleMixin, 'b').first
        edge.should be_a(Pacer::EdgeMixin)
        edge.extensions.should include(Tackle::SimpleMixin)
      end

      it 'should filter correctly with a mix of labels and mixins as arguments' do
        from_v.out_edges('a', Tackle::SimpleMixin, 'b').count.should == 5
      end
    end

    describe '#both_edges' do
      specify 'from_v should have 6 edges' do
        from_v.both_edges.count.should == 6
      end

      specify 'from_v should have 3 edges with label a' do
        from_v.both_edges('a').count.should == 3
      end

      specify 'from_v should have 4 edges with label a or c' do
        from_v.both_edges('a', 'c').count.should == 4
      end

      it 'should add an extension' do
        edge = from_v.both_edges(Tackle::SimpleMixin).first
        edge.should be_a(Pacer::EdgeMixin)
        edge.extensions.should include(Tackle::SimpleMixin)
      end

      it 'should be able to mix labels and mixins as arguments' do
        edge = from_v.both_edges('a', Tackle::SimpleMixin, 'b').first
        edge.should be_a(Pacer::EdgeMixin)
        edge.extensions.should include(Tackle::SimpleMixin)
      end

      it 'should filter correctly with a mix of labels and mixins as arguments' do
        from_v.both_edges('a', Tackle::SimpleMixin, 'b').count.should == 5
      end
    end
  end
end

Run.all do
  it_uses Pacer::VertexMixin
end
