require 'spec_helper'

shared_examples_for Pacer::EdgeMixin do
  use_simple_graph_data

  describe '#e' do
    subject { e0.e }
    it { should be_an_edges_route }
    it { should_not be_a(graph.element_type(:edge)) }
    it { should_not be_an_instance_of(graph.element_type(:edge)) }
  end

  describe '#add_extensions' do
    context 'no extensions' do
      subject { e0.add_extensions([]) }
      its(:extensions) { should == Set[] }
      it { should_not be_a(Pacer::ElementWrapper) }
    end

    context 'with extensions' do
      subject { e0.add_extensions([Tackle::SimpleMixin]) }
      its(:extensions) { should == Set[Tackle::SimpleMixin] }
      it { should be_a(Pacer::ElementWrapper) }
      it { should be_a(Pacer::EdgeWrapper) }
      it { should_not be_a(Pacer::VertexWrapper) }

      describe '#e' do
        subject { e0.add_extensions([Tackle::SimpleMixin]).e }
        its(:extensions) { should == Set[Tackle::SimpleMixin] }
        it { should be_an_edges_route }
        it { should be_a(Tackle::SimpleMixin::Route) }
      end
    end
  end

  describe '#delete!' do
    before do
      @edge_id = e0.element_id
      e0.delete!
      graph.checkpoint # deleted edges in neo may be looked up during the transaction
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
    let(:dest) { graph2 }
  }) do
    describe '#clone_into', :transactions => false do
      before { pending 'support temporary hash indices for clone/copy' unless graph.supports_manual_indices? }
      context 'including vertices' do
        subject { e0.clone_into(dest, :create_vertices => true) }

        its('element_id.to_s') { should == e0.element_id.to_s if graph.supports_custom_element_ids? }
        its(:label) { should == 'links' }
        its(:graph) { should equal(dest) }
        its('in_vertex.properties') { should == { 'name' => 'eliza' } }
        its('out_vertex.properties') { should == { 'name' => 'darrick' } }
      end

      context 'without vertices' do
        subject { e0.clone_into(dest) rescue nil }
        it { should be_nil }

        context 'but already existing' do
          before do
            v0.clone_into(dest)
            v1.clone_into(dest)
          end
          its('element_id.to_s') { should == e0.element_id.to_s if graph.supports_custom_element_ids? }
          its(:label) { should == 'links' }
          its(:graph) { should equal(dest) }
          its('in_vertex.properties') { should == { 'name' => 'eliza' } }
          its('out_vertex.properties') { should == { 'name' => 'darrick' } }
        end
      end
    end

    describe '#copy_into', :transactions => false do
      before { pending unless graph.supports_manual_indices? }
      subject { v0.clone_into(dest); v1.clone_into(dest); e0.copy_into(dest) }
      its(:label) { should == 'links' }
      its(:graph) { should equal(dest) }
      its('in_vertex.properties') { should == { 'name' => 'eliza' } }
      its('out_vertex.properties') { should == { 'name' => 'darrick' } }
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

for_each_graph do
  it_uses Pacer::EdgeMixin
end
