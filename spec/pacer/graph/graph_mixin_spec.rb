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

shared_examples_for Pacer::GraphMixin do
  let(:v0) { graph.create_vertex }
  let(:v1) { graph.create_vertex }
  let(:e0) { graph.create_edge nil, v0, v1, :links }
  let(:e1) { graph.create_edge nil, v0, v1, :relinks }
  before do
    e0 # force edge and vertices to be created.
  end

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
    context 'existing' do
      it 'should raise an exception' do
        if graph.supports_custom_element_ids?
          expect { graph.create_vertex v0.element_id }.to raise_error(Pacer::ElementExists)
        end
      end
    end

    context 'with properties' do
      subject { graph.create_vertex :name => 'Frank' }
      it { subject[:name].should == 'Frank' }
      its(:element_id) { should_not be_nil }

      context 'and an id' do
        subject { graph.create_vertex 1234, :name => 'Steve' }
        it { subject[:name].should == 'Steve' }
        its('element_id.to_s') do
          if graph.respond_to? :id_prefix
            should == graph.id_prefix + '1234'
          elsif graph.supports_custom_element_ids?
            should == '1234' 
          end
        end

        context 'and mixins' do
          subject { graph.create_vertex 1234, Tackle::SimpleMixin, :name => 'John' }
          it { subject[:name].should == 'John' }
          its('element_id.to_s') do
            if graph.respond_to? :id_prefix
              should == graph.id_prefix + '1234'
            elsif graph.supports_custom_element_ids?
              should == '1234' 
            end
          end
          it_behaves_like 'a vertex with a mixin'
        end
      end
    end

    context 'with an id' do
      subject { graph.create_vertex 1234 }
      its('element_id.to_s') do
        if graph.respond_to? :id_prefix
          should == graph.id_prefix + '1234'
        elsif graph.supports_custom_element_ids?
          should == '1234' 
        end
      end

      context 'and mixins' do
        subject { graph.create_vertex 1234, Tackle::SimpleMixin }
        its('element_id.to_s') do
          if graph.respond_to? :id_prefix
            should == graph.id_prefix + '1234'
          elsif graph.supports_custom_element_ids?
            should == '1234' 
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
    let(:from) { graph.vertex v0.element_id }
    let(:to) { graph.vertex v1.element_id }

    context 'existing' do
      it 'should raise an exception' do
        if graph.supports_custom_element_ids?
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
        subject { graph.create_edge 1234, from, to, :connects, :name => 'Steve' }
        it { subject[:name].should == 'Steve' }
        its(:label) { should == 'connects' }
        its('element_id.to_i') { should == 1234 if graph.supports_custom_element_ids? }

        context 'and mixins' do
          subject { graph.create_edge 1234, from, to, :connects, Tackle::SimpleMixin, :name => 'John' }
          it { subject[:name].should == 'John' }
          its(:label) { should == 'connects' }
          its('element_id.to_i') { should == 1234 if graph.supports_custom_element_ids? }
          it_behaves_like 'an edge with a mixin'
        end
      end
    end

    context 'with an id' do
      subject { graph.create_edge 1234, from, to, :connects }
      its(:label) { should == 'connects' }
      its('element_id.to_i') { should == 1234 if graph.supports_custom_element_ids? }

      context 'and mixins' do
        subject { graph.create_edge 1234, from, to, :connects, Tackle::SimpleMixin }
        its(:label) { should == 'connects' }
        its('element_id.to_i') { should == 1234 if graph.supports_custom_element_ids? }
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
    context 'invalid' do
      subject { graph.load_edges [e0.element_id, nil, e0.element_id, 'missing'] }
      it { should == [e0, e0] }
    end

    context 'valid' do
      subject { graph.load_edges [e0.element_id] }
      it { should == [e0] }
    end
  end

  describe '#index_name' do


    it 'should have 2 indices' do
      graph.indices.count.should == 2 if graph.supports_automatic_indices?
    end

    context "'vertices'" do
      around { |spec| spec.run if graph.supports_automatic_indices? }
      subject { graph.index_name 'vertices' }
      it { should_not be_nil }
      its(:index_name) { should == 'vertices' }
      its(:index_type) { should == Pacer.automatic_index }
      its(:index_class) { should == graph.index_class(:vertex) }
      context ':vertex' do
        subject { graph.index_name 'vertices', :vertex }
        it { should_not be_nil }
      end
      context ':edge' do
        subject { graph.index_name 'vertices', :edge }
        it { should be_nil }
      end
    end

    context "'edges'" do
      around { |spec| spec.run if graph.supports_edge_indices? }
      subject { graph.index_name 'edges' }
      it { should_not be_nil }
      its(:index_name) { should == 'edges' }
      its(:index_type) { should == Pacer.automatic_index }
      its(:index_class) { should == graph.index_class(:edge) }
      context ':vertex' do
        subject { graph.index_name 'edges', :vertex }
        it { should be_nil }
      end
      context ':edge' do
        subject { graph.index_name 'edges', :edge }
        it { should_not be_nil }
      end
    end

    context 'missing' do
      around { |spec| spec.run if graph.supports_manual_indices? }
      subject { graph.index_name 'invalid' }
      it { should be_nil }
      context 'edge' do
        before do
          graph.drop_index 'missing_edge' rescue nil
          graph.index_name('missing_edge').should be_nil
        end
        subject { graph.index_name 'missing_edge', :edge, :create => true }
        its(:index_name) { should == 'missing_edge' }
        its(:index_type) { should == Pacer.manual_index }
        its(:index_class) { should == graph.index_class(:edge) }
        after do
          graph.drop_index 'missing_edge'
        end
      end

      context 'vertex' do
        before do
          graph.drop_index 'missing_vertex' rescue nil
          graph.index_name('missing_vertex').should be_nil
        end
        subject { graph.index_name 'missing_vertex', :vertex, :create => true }
        its(:index_name) { should == 'missing_vertex' }
        its(:index_type) { should == Pacer.manual_index }
        its(:index_class) { should == graph.index_class(:vertex) }
        after do
          graph.drop_index 'missing_vertex'
        end
      end
    end

    it 'should return the same object each time' do
      if graph.supports_manual_indices? or graph.supports_automatic_indices?
        graph.index_name('vertices').should equal(graph.index_name('vertices'))
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

  describe '#index_class' do
    around { |spec| spec.run if graph.respond_to? :index_class }
    subject { graph.index_class(:vertex) }
    specify 'should be the class the index returns when queried for index_class' do
      if graph.is_a? Pacer::DexGraph
        subject.should == graph.indices.first.index_class
      else
        subject.to_s.should == graph.index_name('vertices').index_class.to_s
      end
    end
  end

  describe '#import' do
    before { pending 'create a fresh graph for these tests' if graph.is_a? Pacer::DexGraph }

    it 'should load the data into an empty graph' do
      graph2.v.count.should == 0
      graph2.import 'spec/data/pacer.graphml'
      graph2.v.count.should == 7
      graph2.e.count.should == 14
    end

    it 'should not load the data into a graph with conflicting vertex ids' do
      if graph.supports_custom_element_ids?
        graph.create_vertex '0' unless graph.vertex '0'
        expect { graph.import 'spec/data/pacer.graphml' }.to raise_error(Pacer::ElementExists)
      end
    end
  end

  describe '#export' do
    before { pending 'create a fresh graph for these tests' if graph.is_a? Pacer::DexGraph }
    it 'should create a file that can be read back' do
      graph.export 'tmp/graph_mixin_spec_export.graphml'
      graph2.import 'tmp/graph_mixin_spec_export.graphml'
      graph2.v.count.should == graph.v.count
      graph2.e.count.should == graph.e.count
    end
  end

end


Run.all :read_only, false do
  around do |spec|
    spec.run if graph
  end

  let(:v0) { graph.create_vertex }
  let(:v1) { graph.create_vertex }
  let(:e0) { graph.create_edge nil, v0, v1, :links }
  let(:e1) { graph.create_edge nil, v0, v1, :relinks }

  describe Pacer::GraphMixin do
    before do
      e0 # force edge and vertices to be created.
    end

    describe 'rebuild_automatic_index', :transactions => false do
      context 'vertices' do
        before do
          v0.properties = { :name => 'darrick', :type => 'person' }
          v1.properties = { :name => 'eliza', :type => 'person' }
          @orig_idx = graph.createAutomaticIndex 'vertices', graph.index_class(:vertex), nil
          @new_idx = graph.rebuild_automatic_index @orig_idx
        end

        after do
          graph.drop_index :vertices
          graph.v.delete!
        end

        let(:orig_idx) { @orig_idx }
        subject { @new_idx }
        it { should_not equal(orig_idx) }
        it 'should not use the old vertices index' do
          graph.index_name('vertices').should_not equal(orig_idx)
        end
        it { should equal(graph.index_name('vertices')) }
        it 'should have 2 persons' do
          subject.count('type', 'person').should == 2
        end
        it 'should have v1 for eliza' do
          subject.get('name', 'eliza').to_a.should == [v1].to_a
        end
      end

      context 'edges' do
        before do
          v0.properties = { :name => 'darrick', :type => 'person' }
          v1.properties = { :name => 'eliza', :type => 'person' }
          e0.properties = { :style => 'edgy' }
          e1.properties = { :style => 'edgy' }
          @orig_idx = graph.createAutomaticIndex 'edges', graph.index_class(:edge), nil
          @new_idx = graph.rebuild_automatic_index @orig_idx
        end

        after do
          graph.drop_index :edges
          graph.v.delete!
        end


        let(:orig_idx) { @orig_idx }
        subject { @new_idx }
        it { should_not equal(orig_idx) }
        it 'should not use the old edges index' do
          graph.index_name('edges').should_not equal(orig_idx)
        end
        it { should equal(graph.index_name('edges')) }
        it 'should have 1 edge' do
          subject.count('label', 'links').should == 1
        end
        it 'should have e0 and e1 for style => edgy' do
          subject.get('style', 'edgy').to_set.should == [e0, e1].to_set
        end
      end
    end
  end

  describe 'edges can be indexed', :transactions => false do
    after do
      graph.drop_index 'edges'
      graph.v.delete!
    end

    specify 'in an auto index' do
      index = graph.createAutomaticIndex 'edges', graph.index_class(:edge), nil
      graph.edges.count.should == 0
      label = e0.label
      graph.edges.count.should == 1
      index.get('label', label).count.should == 1
    end

    specify 'by adding them to a new auto index' do
      graph.edges.count.should == 0
      label = e0.label
      graph.edges.count.should == 1
      index = graph.createAutomaticIndex 'edges', graph.index_class(:edge), nil
      index.get('label', label).count.should == 0
      Pacer::Utils::AutomaticIndexHelper.addElement(index, e0)
      index.get('label', label).count.should == 1
    end
  end
end

Run.all do
  it_uses Pacer::GraphMixin
end

Run.neo4j do
  describe '#vertex' do
    it 'should not raise an exception for invalid key type' do
      graph.vertex('bad id').should be_nil
    end
  end

  describe '#edge' do
    it 'should not raise an exception for invalid key type' do
      graph.edge('bad id').should be_nil
    end
  end
end
