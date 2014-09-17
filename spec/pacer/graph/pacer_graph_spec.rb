require 'spec_helper'

shared_examples_for 'an edge with a mixin' do
  its(:route_mixin_method) { should be_true }
  its(:edge_mixin_method) { should be_true }
  it 'should not include the Vertex module' do
    expect { subject.vertex_mixin_method }.to raise_error(NoMethodError)
  end
end

shared_examples_for 'a vertex with a mixin' do
  its(:route_mixin_method) { should be_true }
  its(:vertex_mixin_method) { should be_true }
  it 'should not include the Edge module' do
    expect { subject.edge_mixin_method }.to raise_error(NoMethodError)
  end
end

Run.all :read_write do
  describe Pacer::PacerGraph do
    use_simple_graph_data
    before { setup_data }

    describe '#vertex' do
      context 'not found' do
        subject { graph.vertex '-1' }
        it { should be_nil }
      end

      subject { graph.vertex v0.element_id }
      its(:element_id) { should == v0.element_id }
      its(:graph) { should == graph }

      context 'with mixins' do
        subject { graph.vertex v0.element_id, Tackle::SimpleMixin }
        its(:element_id) { should == v0.element_id }
        it_behaves_like 'a vertex with a mixin'
      end

      context 'with a wrapper' do
        let(:wrapper) { Pacer.vertex_wrapper Tackle::SimpleMixin }
        subject { graph.vertex v0.element_id, wrapper }
        its(:element_id) { should == v0.element_id }
        its(:class) { should == wrapper }
        it_behaves_like 'a vertex with a mixin'
      end

      context 'with a wrapper and a mixin' do
        let(:orig_wrapper) { Pacer.vertex_wrapper Tackle::SimpleMixin }
        let(:wrapper) { Pacer.vertex_wrapper Tackle::SimpleMixin, TP::Person }
        subject { graph.vertex v0.element_id, TP::Person, orig_wrapper }
        its(:element_id) { should == v0.element_id }
        its(:class) { should_not == orig_wrapper }
        its(:class) { should == wrapper }
        it_behaves_like 'a vertex with a mixin'
      end
    end

    describe '#edge' do
      context 'not found' do
        subject { graph.edge '-1' }
        it { should be_nil }
      end

      subject { graph.edge e0.element_id }
      its(:element_id) { should == e0.element_id }
      its(:graph) { should == graph }

      context 'with mixins' do
        subject { graph.edge e0.element_id, Tackle::SimpleMixin }
        its(:element_id) { should == e0.element_id }
        it_behaves_like 'an edge with a mixin'
      end

      context 'with a wrapper' do
        let(:wrapper) { Pacer.edge_wrapper Tackle::SimpleMixin }
        subject { graph.edge e0.element_id, wrapper }
        its(:element_id) { should == e0.element_id }
        its(:class) { should == wrapper }
        it_behaves_like 'an edge with a mixin'
      end

      context 'with a wrapper and a mixin' do
        let(:orig_wrapper) { Pacer.edge_wrapper Tackle::SimpleMixin }
        let(:wrapper) { Pacer.edge_wrapper Tackle::SimpleMixin, TP::Wrote }
        subject { graph.edge e0.element_id, orig_wrapper, TP::Wrote }
        its(:element_id) { should == e0.element_id }
        its(:class) { should_not == orig_wrapper }
        its(:class) { should == wrapper }
        it_behaves_like 'an edge with a mixin'
      end
    end

    describe '#create_vertex' do
      let(:use_id) { rand 1000000 }

      before do
        c = example.metadata[:graph_commit]
        c.call if c
      end

      context 'existing' do
        it 'should raise an exception' do
          unless graph.features.ignoresSuppliedIds
            expect { graph.create_vertex v0.element_id }.to raise_error(Pacer::ElementExists)
          end
        end
      end

      context 'with properties' do
        subject { graph.create_vertex :name => 'Frank' }
        it { subject[:name].should == 'Frank' }
        its(:element_id) { should_not be_nil }

        context 'and an id' do
          subject { graph.create_vertex use_id, :name => 'Steve' }
          it { subject[:name].should == 'Steve' }
          its('element_id.to_s') do
            if graph.respond_to? :id_prefix
              should == graph.id_prefix + use_id.to_s
            elsif not graph.features.ignoresSuppliedIds
              should == use_id.to_s
            end
          end

          context 'and mixins' do
            subject { graph.create_vertex use_id, Tackle::SimpleMixin, :name => 'John' }
            it { subject[:name].should == 'John' }
            its('element_id.to_s') do
              if graph.respond_to? :id_prefix
                should == graph.id_prefix + use_id.to_s
              elsif not graph.features.ignoresSuppliedIds
                should == use_id.to_s
              end
            end
            it_behaves_like 'a vertex with a mixin'
          end
        end
      end

      context 'with an id' do
        subject { graph.create_vertex use_id }
        its('element_id.to_s') do
          if graph.respond_to? :id_prefix
            should == graph.id_prefix + use_id.to_s
          elsif not graph.features.ignoresSuppliedIds
            should == use_id.to_s
          end
        end

        context 'and mixins' do
          subject { graph.create_vertex use_id, Tackle::SimpleMixin }
          its('element_id.to_s') do
            if graph.respond_to? :id_prefix
              should == graph.id_prefix + use_id.to_s
            elsif not graph.features.ignoresSuppliedIds
              should == use_id.to_s
            end
          end
          it_behaves_like 'a vertex with a mixin'
        end
      end

      context 'with mixins' do
        subject { graph.create_vertex Tackle::SimpleMixin }
        it_behaves_like 'a vertex with a mixin'
      end
    end


    describe '#create_edge' do
      let(:use_id) { rand 1000000 }
      let(:from) { graph.vertex v0.element_id }
      let(:to) { graph.vertex v1.element_id }

      before do
        c = example.metadata[:graph_commit]
        c.call if c
      end

      context 'existing' do
        it 'should raise an exception' do
          if not graph.features.ignoresSuppliedIds
            expect { graph.create_edge e0.element_id, from, to, :connects }.to raise_error(Pacer::ElementExists)
          end
        end
      end

      context 'with properties' do
        subject { graph.create_edge nil, from, to, :connects, :name => 'Frank' }
        it { subject[:name].should == 'Frank' }
        its(:label) { should == 'connects' }
        its(:element_id) { should_not be_nil }

        context 'and an id' do
          subject { graph.create_edge use_id, from, to, :connects, :name => 'Steve' }
          it { subject[:name].should == 'Steve' }
          its(:label) { should == 'connects' }
          its('element_id.to_i') { should == use_id unless graph.features.ignoresSuppliedIds }

          context 'and mixins' do
            subject { graph.create_edge use_id, from, to, :connects, Tackle::SimpleMixin, :name => 'John' }
            it { subject[:name].should == 'John' }
            its(:label) { should == 'connects' }
            its('element_id.to_i') { should == use_id unless graph.features.ignoresSuppliedIds }
            it_behaves_like 'an edge with a mixin'
          end
        end
      end

      context 'with an id' do
        subject { graph.create_edge use_id, from, to, :connects }
        its(:label) { should == 'connects' }
        its('element_id.to_i') { should == use_id unless graph.features.ignoresSuppliedIds }

        context 'and mixins' do
          subject { graph.create_edge use_id, from, to, :connects, Tackle::SimpleMixin }
          its(:label) { should == 'connects' }
          its('element_id.to_i') { should == use_id unless graph.features.ignoresSuppliedIds }
          it_behaves_like 'an edge with a mixin'
        end
      end

      context 'with mixins' do
        subject { graph.create_edge nil, from, to, :connects, Tackle::SimpleMixin }
        its(:label) { should == 'connects' }
        it_behaves_like 'an edge with a mixin'
      end
    end

    describe '#bulk_job_size' do
      subject { graph.bulk_job_size }
      describe 'default' do
        it { should == 5000 }
      end
      describe 'custom' do
        before { graph.bulk_job_size = 12 }
        it { should == 12 }
      end
    end

    describe '#in_bulk_job?' do
      subject { graph.in_bulk_job? }
      it { should be_false }

      context 'in bulk job' do
        around do |spec|
          graph.v[0].bulk_job do
            spec.call
          end
        end
        it { should be_true }
      end
    end

    describe '#load_vertices' do
      context 'invalid' do
        subject { graph.load_vertices [v0.element_id, nil, v0.element_id, 'missing'] }
        it { should == [v0, v0] }
      end

      context 'valid' do
        subject { graph.load_vertices [v0.element_id, v1.element_id] }
        it { should == [v0, v1] }
      end
    end

    describe '#load_edges' do
      before do
        c = example.metadata[:graph_commit]
        c.call if c
      end
      it 'should only find valid edges' do
        # FIXME: It can't find the tempids. Don't know why I'm not getting the actual ID for e0 even after commit.
        return if graph_name == 'orient'
        graph.load_edges([e0.element_id.to_s, nil, e0.element_id, 'missing']).should == [e0, e0]
      end
    end

    describe '#index' do
      it 'should have no indices' do
        graph.indices.count.should == 0 if graph.features.supportsKeyIndices
      end

      context 'missing' do
        around { |spec| spec.run if graph.features.supportsIndices }
        subject { graph.index 'invalid' }
        it { should be_nil }
        context 'edge' do
          before do
            graph.drop_index 'missing_edge' rescue nil
            graph.index('missing_edge').should be_nil
          end
          subject { graph.index 'missing_edge', :edge, :create => true }
          its(:name) { should == 'missing_edge' }
          after do
            graph.transaction(nesting: true) do
              graph.drop_index 'missing_edge'
            end
          end
        end

        context 'vertex' do
          before do
            graph.drop_index 'missing_vertex' rescue nil
            graph.index('missing_vertex').should be_nil
          end
          subject { graph.index 'missing_vertex', :vertex, :create => true }
          its(:name) { should == 'missing_vertex' }
          after do
            graph.transaction(nesting: true) do
              graph.drop_index 'missing_vertex'
            end
          end
        end
      end
    end

    describe '#graph' do
      subject { graph.graph }
      it { should == graph }
    end

    describe '#vertex_name' do
      before { graph.vertex_name = :some_proc }
      subject { graph.vertex_name }
      it { should == :some_proc }
      after { graph.vertex_name = nil }
    end

    describe '#edge_name' do
      before { graph.edge_name = :some_proc }
      subject { graph.edge_name }
      it { should == :some_proc }
      after { graph.edge_name = nil }
    end

    describe '#import' do
      it 'should load the data into an empty graph' do
        graph2.v.delete!
        graph2.v.count.should == 0
        Pacer::GraphML.import graph2, 'spec/data/pacer.graphml'
        graph2.v.count.should == 7
        graph2.e.count.should == 14
      end

      it 'should not load the data into a graph with conflicting vertex ids' do
        unless graph.features.ignoresSuppliedIds
          graph.create_vertex '0' unless graph.vertex '0'
          c = example.metadata[:graph_commit]
          c.call if c
          expect { Pacer::GraphML.import graph, 'spec/data/pacer.graphml' }.to raise_error(Pacer::ElementExists)
        end
      end
    end

    describe '#export' do
      it 'should create a file that can be read back' do
        graph.v.count.should == 2
        graph.e.count.should == 2
        Pacer::GraphML.export graph, '/tmp/graph_mixin_spec_export.graphml'
        graph2.e.delete!
        graph2.v.delete!
        graph2.v.count.should == 0
        graph2.e.count.should == 0
        Pacer::GraphML.import graph2, '/tmp/graph_mixin_spec_export.graphml'
        puts File.read '/tmp/graph_mixin_spec_export.graphml'
        graph2.v.count.should == 2
        graph2.e.count.should == 2
      end
    end

    describe '#indices' do
      subject { graph.indices.to_a }
      it { should be_empty }
    end

    describe '#element_type' do
      context 'invalid' do
        it { expect { graph.element_type(:nothing) }.to raise_error(ArgumentError) }
      end

      context ':vertex' do
        subject { graph.element_type(:vertex) }
        it { should == :vertex }
      end

      context 'a vertex' do
        subject { graph.element_type(v0) }
        it { should == :vertex }
      end

      context ':edge' do
        subject { graph.element_type(:edge) }
        it { should == :edge }
      end

      context 'an edge' do
        subject { graph.element_type(e0) }
        it { should == :edge }
      end

      context ':mixed' do
        subject { graph.element_type(:mixed) }
        it { should == :mixed }
      end

      context ':object' do
        subject { graph.element_type(:object) }
        it { should == :object }
      end

      context 'from element_type' do
        context ':vertex' do
          subject { graph.element_type(graph.element_type :vertex) }
          it { should == :vertex }
        end

        context ':edge' do
          subject { graph.element_type(graph.element_type :edge) }
          it { should == :edge }
        end

        context ':mixed' do
          subject { graph.element_type(graph.element_type :mixed) }
          it { should == :mixed }
        end

        context ':object' do
          subject { graph.element_type(graph.element_type :object) }
          it { should == :object }
        end
      end

      context 'from index_class' do
        context ':vertex' do
          subject { graph.element_type(graph.index_class :vertex) }
          it { should == :vertex }
        end
      end
    end
  end
end
