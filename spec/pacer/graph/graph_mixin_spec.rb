require 'spec_helper'

describe Pacer::GraphMixin do
  let(:graph) { Pacer.tg }
  let(:v0) { graph.create_vertex }
  let(:v1) { graph.create_vertex }
  let(:e0) { graph.create_edge '0', v0, v1, :links }
  let(:e1) { graph.create_edge '1', v0, v1, :relinks }
  before do
    e0 # force edge and vertices to be created.
  end

  shared_examples_for 'an edge with a mixin' do
    its(:route_mixin_method) { should be_true }
    its(:edge_mixin_method) { should be_true }
    it 'should not inclued the Vertex module' do
      expect { subject.vertex_mixin_method }.to raise_error(NoMethodError)
    end
  end

  shared_examples_for 'a vertex with a mixin' do
    its(:route_mixin_method) { should be_true }
    its(:vertex_mixin_method) { should be_true }
    it 'should not inclued the Edge module' do
      expect { subject.edge_mixin_method }.to raise_error(NoMethodError)
    end
  end

  describe '#vertex' do
    context 'not found' do
      subject { graph.vertex 'nonexistant' }
      it { should be_nil }
    end

    subject { graph.vertex '0' }
    its(:element_id) { should == '0' }
    its(:graph) { should == graph }

    context 'with mixins' do
      subject { graph.vertex '0', Tackle::SimpleMixin }
      its(:element_id) { should == '0' }
      it_behaves_like 'a vertex with a mixin'
    end
  end

  describe '#edge' do
    context 'not found' do
      subject { graph.edge 'nonexistant' }
      it { should be_nil }
    end

    subject { graph.edge '0' }
    its(:element_id) { should == '0' }
    its(:graph) { should == graph }

    context 'with mixins' do
      subject { graph.edge '0', Tackle::SimpleMixin }
      its(:element_id) { should == '0' }
      it_behaves_like 'an edge with a mixin'
    end
  end

  describe '#create_vertex' do
    context 'existing' do
      it 'should raise an exception' do
        expect { graph.create_vertex '0' }.to raise_error(Pacer::ElementExists)
      end
    end

    context 'with properties' do
      subject { graph.create_vertex :name => 'Frank' }
      it { subject[:name].should == 'Frank' }
      its(:element_id) { should_not be_nil }

      context 'and an id' do
        subject { graph.create_vertex 123, :name => 'Steve' }
        it { subject[:name].should == 'Steve' }
        its(:element_id) { should == '123' }

        context 'and mixins' do
          subject { graph.create_vertex 123, Tackle::SimpleMixin, :name => 'John' }
          it { subject[:name].should == 'John' }
          its(:element_id) { should == '123' }
          it_behaves_like 'a vertex with a mixin'
        end
      end
    end

    context 'with an id' do
      subject { graph.create_vertex 123 }
      its(:element_id) { should == '123' }

      context 'and mixins' do
        subject { graph.create_vertex 123, Tackle::SimpleMixin }
        its(:element_id) { should == '123' }
        it_behaves_like 'a vertex with a mixin'
      end
    end

    context 'with mixins' do
      subject { graph.create_vertex Tackle::SimpleMixin }
      it_behaves_like 'a vertex with a mixin'
    end
  end


  describe '#create_edge' do
    let(:from) { graph.vertex '0' }
    let(:to) { graph.vertex '1' }

    context 'existing' do
      it 'should raise an exception' do
        expect { graph.create_edge '0', from, to, :connects }.to raise_error(Pacer::ElementExists)
      end
    end

    context 'with properties' do
      subject { graph.create_edge nil, from, to, :connects, :name => 'Frank' }
      it { subject[:name].should == 'Frank' }
      its(:label) { should == 'connects' }
      its(:element_id) { should_not be_nil }

      context 'and an id' do
        subject { graph.create_edge 123, from, to, :connects, :name => 'Steve' }
        it { subject[:name].should == 'Steve' }
        its(:label) { should == 'connects' }
        its(:element_id) { should == '123' }

        context 'and mixins' do
          subject { graph.create_edge 123, from, to, :connects, Tackle::SimpleMixin, :name => 'John' }
          it { subject[:name].should == 'John' }
          its(:label) { should == 'connects' }
          its(:element_id) { should == '123' }
          it_behaves_like 'an edge with a mixin'
        end
      end
    end

    context 'with an id' do
      subject { graph.create_edge 123, from, to, :connects }
      its(:label) { should == 'connects' }
      its(:element_id) { should == '123' }

      context 'and mixins' do
        subject { graph.create_edge 123, from, to, :connects, Tackle::SimpleMixin }
        its(:label) { should == 'connects' }
        its(:element_id) { should == '123' }
        it_behaves_like 'an edge with a mixin'
      end
    end

    context 'with mixins' do
      subject { graph.create_edge nil, from, to, :connects, Tackle::SimpleMixin }
      its(:label) { should == 'connects' }
      it_behaves_like 'an edge with a mixin'
    end
  end

  describe '#import' do
    it 'should load the data into an empty graph' do
      g = Pacer.tg
      g.import 'spec/data/pacer.graphml'
      g.v.count.should == 7
      g.e.count.should == 14
    end

    it 'should not load the data into a graph with conflicting vertex ids' do
      expect { graph.import 'spec/data/pacer.graphml' }.to raise_error(Pacer::ElementExists)
    end
  end

  describe '#export' do
    it 'should create a file that can be read back' do
      graph.export 'spec/data/graph_mixin_spec_export.tmp'
      g = Pacer.tg 'spec/data/graph_mixin_spec_export.tmp'
      g.v.count.should == graph.v.count
      g.e.count.should == graph.e.count
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
      subject { graph.load_vertices [0, nil, '0', 'missing'] }
      it { should == [v0, v0] }
    end

    context 'valid' do
      subject { graph.load_vertices [0, 1] }
      it { should == [v0, v1] }
    end
  end

  describe '#load_edges' do
    context 'invalid' do
      subject { graph.load_edges [0, nil, '0', 'missing'] }
      it { should == [e0, e0] }
    end

    context 'valid' do
      subject { graph.load_edges [0] }
      it { should == [e0] }
    end
  end

  describe '#index_name' do
    context "('vertices')" do
      subject { graph.index_name 'vertices' }
      it { should_not be_nil }
      its(:index_name) { should == 'vertices' }
      its(:index_type) { should == Pacer.automatic_index }
      its(:index_class) { should == graph.index_class(:vertex) }
    end

    context "('edges')" do
      subject { graph.index_name 'edges' }
      it { should_not be_nil }
      its(:index_name) { should == 'edges' }
      its(:index_type) { should == Pacer.automatic_index }
      its(:index_class) { should == graph.index_class(:edge) }
    end

    context 'missing' do
      subject { graph.index_name 'invalid' }
      it { should be_nil }
    end

    it 'should return the same object each time' do
      graph.index_name('vertices').should equal(graph.index_name('vertices'))
    end
  end

  describe 'rebuild_automatic_index' do
    context 'vertices' do
      before do
        v0.properties = { :name => 'darrick', :type => 'person' }
        v1.properties = { :name => 'eliza', :type => 'person' }
        @new_idx = graph.rebuild_automatic_index orig_idx
      end
      let(:orig_idx) { graph.index_name 'vertices' }
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
        subject.get('name', 'eliza').should == [v1].to_hashset
      end
    end

    context 'edges' do
      before do
        v0.properties = { :name => 'darrick', :type => 'person' }
        v1.properties = { :name => 'eliza', :type => 'person' }
        e0.properties = { :style => 'edgy' }
        e1.properties = { :style => 'edgy' }
        @new_idx = graph.rebuild_automatic_index orig_idx
      end
      let(:orig_idx) { graph.index_name 'edges' }
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
        subject.get('style', 'edgy').should == [e0, e1].to_hashset
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
  end

  describe '#edge_name' do
    before { graph.edge_name = :some_proc }
    subject { graph.edge_name }
    it { should == :some_proc }
  end

  describe '#index_class' do
    subject { graph.index_class(:vertex) }
    it { should == graph.element_type(:vertex).java_class.to_java }
  end
end
