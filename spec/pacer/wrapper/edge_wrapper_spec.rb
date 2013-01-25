require 'spec_helper'

Run.all :read_only do
  describe Pacer::Wrappers::EdgeWrapper do
    use_pacer_graphml_data :read_only

    let(:e_exts) { [Tackle::SimpleMixin, TP::Wrote] }
    let(:e_wrapper_class) { Pacer::Wrappers::EdgeWrapper.wrapper_for e_exts }

    subject { e_wrapper_class }

    it { should_not be_nil }
    its(:route_conditions) { should == { label: 'wrote' } }
    its(:extensions) { should == e_exts }

    describe 'instance' do
      subject do
        e_wrapper_class.new graph, pangloss_wrote_pacer.element
      end
      it               { should_not be_nil }
      its(:element)    { should_not be_nil }
      it               { should == pangloss_wrote_pacer }
      it               { should_not equal pangloss_wrote_pacer }
      its(:element_id) { should == pangloss_wrote_pacer.element_id }
      its(:extensions) { should == e_exts }

      describe 'with more extensions added' do
        subject { e_wrapper_class.new(graph, pacer.element).add_extensions([Pacer::Utils::TSort]) }
        its(:class) { should_not == e_wrapper_class }
        its(:extensions) { should == e_exts + [Pacer::Utils::TSort] }
      end
    end
  end

describe Pacer::Wrappers::EdgeWrapper do
  use_simple_graph_data

  describe '#e' do
    subject { e0.e }
    it { should be_an_edges_route }
    its(:element_type) { should == :edge }
  end

  describe '#add_extensions' do
    context 'no extensions' do
      subject { e0.add_extensions([]) }
      its('extensions.to_a') { should == [] }
      its(:class) { should == graph.base_edge_wrapper }
    end

    context 'with extensions' do
      subject { e0.add_extensions([Tackle::SimpleMixin]) }
      its('extensions.to_a') { should == [Tackle::SimpleMixin] }
      it { should be_a(Pacer::Wrappers::ElementWrapper) }
      it { should be_a(Pacer::Wrappers::EdgeWrapper) }
      it { should_not be_a(Pacer::Wrappers::VertexWrapper) }

      describe '#e' do
        subject { e0.add_extensions([Tackle::SimpleMixin]).e }
        its('extensions.to_a') { should == [Tackle::SimpleMixin] }
        it { should be_an_edges_route }
        it { should be_a(Tackle::SimpleMixin::Route) }
      end
    end
  end

  subject { e0 }
  its(:graph) { should equal(graph) }
  its(:display_name) { should == "#{ v0.element_id }-links-#{ v1.element_id }" }
  its(:inspect) { should == "#<E[#{ e0.element_id }]:#{ v0.element_id }-links-#{ v1.element_id }>" }
  context 'with label proc' do
    before do
      graph.edge_name = proc { |e| "some name" }
    end
    its(:display_name) { should == "some name" }
    its(:inspect) { should == "#<E[#{ e0.element_id }]:some name>" }
  end

  context '', :transactions => true do
    it { should_not == e1 }
    it { should == e0 }
    it { should_not == v0 }
  end
end
end

Run.all :read_write do
  use_simple_graph_data

describe Pacer::Wrappers::EdgeWrapper do
  describe '#delete!' do
    before do
      @edge_id = e0.element_id
      e0.delete!
      c = example.metadata[:graph_commit]
      c.call if c
    end
    it 'should be removed' do
      graph.edge(@edge_id).should be_nil
    end
  end

  contexts(
  'into new tg' => proc {
    let(:dest) { Pacer.tg }
  },
  'into graph2' => proc {
    let(:dest) {
      c = example.metadata[:graph2_commit]
      c.call() if c
      graph2.v.delete!
      c.call() if c
      graph2
    }
  }) do
    describe '#clone_into' do
      context 'including vertices' do
        subject { e0.clone_into(dest, :create_vertices => true) }

        its('element_id.to_s') { should == e0.element_id.to_s unless graph.features.ignoresSuppliedIds }
        its(:label) { should == 'links' }
        its(:graph) { should equal(dest) }
        its('in_vertex.properties') { should == e0.in_vertex.properties }
        its('out_vertex.properties') { should == e0.out_vertex.properties }
      end

      context 'without vertices' do
        context 'not existing' do
          subject { e0.clone_into(dest) rescue nil }
          it { should be_nil }
        end

        context 'existing' do
          before do
            v0.clone_into(dest)
            v1.clone_into(dest)
          end
          subject { e0.clone_into(dest) }
          its('element_id.to_s') { should == e0.element_id.to_s unless graph.features.ignoresSuppliedIds }
          its(:label) { should == 'links' }
          its(:graph) { should equal(dest) }
          its('in_vertex.properties') { should == e0.in_vertex.properties }
          its('out_vertex.properties') { should == e0.out_vertex.properties }
        end
      end
    end

    describe '#copy_into' do
      subject { v0.clone_into(dest); v1.clone_into(dest); e0.copy_into(dest) }
      its(:label) { should == 'links' }
      its(:graph) { should equal(dest) }
      its('in_vertex.properties') { should == e0.in_vertex.properties }
      its('out_vertex.properties') { should == e0.out_vertex.properties }
    end
  end
end
end
