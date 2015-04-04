require 'spec_helper'

module VertexWrapperSpec
  module Project
    def self.route_conditions(graph)
      { :type => 'project' }
    end

    module Vertex
    end
  end

  module IsRuby
    def self.lookup(graph)
      { :language => 'ruby' }
    end

    module Vertex
    end
  end

  Run.all :read_only do
    use_pacer_graphml_data :read_only

    describe Pacer::Wrappers::VertexWrapper do

      let(:v_exts) { [Tackle::SimpleMixin, TP::Project] }
      let(:v_wrapper_class) { Pacer::Wrappers::VertexWrapper.wrapper_for v_exts }

      subject { v_wrapper_class }

      it { should_not be_nil }
      it { subject.route_conditions(graph).should == { type: 'project' } }
      its(:extensions) { should == v_exts }

      describe 'instance' do
        subject do
          v_wrapper_class.new graph, pacer.element
        end
        it               { should_not be_nil }
        its(:element)    { should_not be_nil }
        it               { should == pacer }
        it               { should_not equal pacer }
        its(:element_id) { should == pacer.element_id }
        its(:extensions) { should == v_exts }

        describe 'with more extensions added' do
          subject { v_wrapper_class.new(graph, pacer.element).add_extensions([Pacer::Utils::TSort]) }
          its(:class) { should_not == v_wrapper_class }
          its(:extensions) { should == v_exts + [Pacer::Utils::TSort] }
        end
      end
    end
  end

  Run.all :read_only do
    describe 'type filtering' do
      before :all do
        graph.tx do
          graph.create_vertex type: 'project'
          graph.create_vertex type: 'project'
          graph.create_vertex type: 'file'
          graph.create_vertex language: 'ruby'
          graph.create_vertex language: 'perl'
        end
      end

      context Project, 'using route_conditions' do
        specify 'initial lookup' do
          graph.v(Project).count.should == 2
        end
        specify 'filter route' do
          graph.v.v(Project).count.should == 2
        end
      end

      context IsRuby, 'using lookup' do
        specify 'initial lookup' do
          graph.v(IsRuby).count.should == 1
        end
        specify 'filter route' do
          graph.v.v(IsRuby).count.should == 1
        end
      end
    end
  end

  shared_examples_for Pacer::Wrappers::VertexWrapper do
    use_simple_graph_data

    describe '#v' do
      subject { v0.v }
      it { should be_a_vertices_route }
      its(:element_type) { should == :vertex }
    end

    describe '#add_extensions' do
      context 'no extensions' do
        subject { v0.add_extensions([]) }
        its('extensions.to_a') { should == [] }
        its(:class) { should == graph.base_vertex_wrapper }
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
      context 'project' do
        let(:v) { graph.create_vertex type: 'project' }
        context 'Project' do
          subject { v.as?(Project) }
          it { should be_true }
        end
        context 'IsRuby' do
          subject { v.as?(IsRuby) }
          it { should_not be_true }
        end
        context 'Project, IsRuby' do
          subject { v.as?(Project, IsRuby) }
          it { should_not be_true }
        end
      end
      context 'language' do
        let(:v) { graph.create_vertex language: 'ruby' }
        context 'Project' do
          subject { v.as?(Project) }
          it { should_not be_true }
        end
        context 'IsRuby' do
          subject { v.as?(IsRuby) }
          it { should be_true }
        end
        context 'Project, IsRuby' do
          subject { v.as?(Project, IsRuby) }
          it { should_not be_true }
        end
      end
    end

    describe '#as' do
      context 'vertex is a Project' do
        let(:v) { graph.create_vertex type: 'project' }

        it 'should yield a Project' do
          yielded = false
          v.as(Project) do |v2|
            yielded = true
            v2.should == v
            v2.extensions.should include Project
            v2.should be_a Project::Vertex
          end
          yielded.should be_true
        end

        it 'should not yield a IsRuby' do
          yielded = false
          v.as(IsRuby) do |v2|
            yielded = true
          end
          yielded.should be_false
        end
      end
    end

    describe '#only_as' do
      context 'able' do
        subject { graph.create_vertex IsRuby, type: 'project', language: 'ruby' }

        its(:extensions) { should include IsRuby }

        it 'should yield a Project' do
          yielded = false
          subject.only_as(Project) do |v2|
            yielded = true
            v2.should == subject
            v2.extensions.should == [Project]
            v2.should be_a Project::Vertex
          end
          yielded.should be_true
        end
      end

      context 'unable' do
        subject { graph.create_vertex IsRuby, language: 'ruby' }

        it 'should not yield a Project' do
          yielded = false
          subject.only_as(Project) do |v2|
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
        c = example.metadata[:graph_commit]
        c.call if c
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
        before { pending 'support temporary hash indices for clone/copy' unless graph.features.supportsIndices }
        let(:dest) { graph2 }
      }
    ) do
      before do
        graph.transaction(nesting: true) { setup_data }
      end
      describe '#clone_into', :transactions => false, read_transaction: true do
        subject { dest.transaction { v0.clone_into(dest) } }
        its(:properties) { should == { 'name' => 'eliza' } }
        its(:graph) { should equal(dest) }
        its('element_id.to_s') { should == v0.element_id.to_s unless graph.features.ignoresSuppliedIds }
      end

      describe '#copy_into', :transaction => false, read_transaction: true do
        subject { v1.copy_into(dest) }
        its(:properties) { should == { 'name' => 'darrick' } }
        its(:graph) { should equal(dest) }
      end
    end

    subject { graph.transaction(nesting: true) { setup_data; v0 } }
    its(:graph) { should equal(graph) }
    its(:display_name) { should be_nil }
    its(:inspect) { should =~ /#<[VM]\[#{Regexp.quote v0.element_id.to_s }\]>/ }
    context 'with label proc' do
      before do
        graph.vertex_name = proc { |e| "some name" }
      end
      its(:display_name) { should == "some name" }
      its(:inspect) { should =~ /#<[VM]\[#{ Regexp.quote v0.element_id.to_s }\] some name>/ }
    end
    it { should_not == v1 }
    it { should == v0 }
    context 'edge with same element id', :transactions => false, read_transaction: true do
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
          edge.should be_a(Pacer::Wrappers::EdgeWrapper)
          edge.extensions.should include(Tackle::SimpleMixin)
        end

        it 'should be able to mix labels and mixins as arguments' do
          edge = to_v.in_edges('a', Tackle::SimpleMixin, 'b').first
          edge.should be_a(Pacer::Wrappers::EdgeWrapper)
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
          edge.should be_a(Pacer::Wrappers::EdgeWrapper)
          edge.extensions.should include(Tackle::SimpleMixin)
        end

        it 'should be able to mix labels and mixins as arguments' do
          edge = from_v.out_edges('a', Tackle::SimpleMixin, 'b').first
          edge.should be_a(Pacer::Wrappers::EdgeWrapper)
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
          edge.should be_a(Pacer::Wrappers::EdgeWrapper)
          edge.extensions.should include(Tackle::SimpleMixin)
        end

        it 'should be able to mix labels and mixins as arguments' do
          edge = from_v.both_edges('a', Tackle::SimpleMixin, 'b').first
          edge.should be_a(Pacer::Wrappers::EdgeWrapper)
          edge.extensions.should include(Tackle::SimpleMixin)
        end

        it 'should filter correctly with a mix of labels and mixins as arguments' do
          from_v.both_edges('a', Tackle::SimpleMixin, 'b').count.should == 5
        end
      end
    end
  end

  Run.all do
    it_uses Pacer::Wrappers::VertexWrapper
  end
end
