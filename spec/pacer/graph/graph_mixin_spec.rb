require 'spec_helper'

describe Pacer::GraphMixin do
  let(:graph) { Pacer.tg }
  before do
    v0 = graph.create_vertex
    v1 = graph.create_vertex
    graph.create_edge '0', v0, v1, :default
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

  end
end
