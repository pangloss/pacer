require 'spec_helper'

shared_examples_for Pacer::VertexMixin do
  use_simple_graph_data
  describe '#add_extensions' do
    context 'no extensions' do
      subject { v0.add_extensions([]) }
      its(:extensions) { should == Set[] }
      it { should_not be_a(Pacer::ElementWrapper) }
    end

    context 'with extensions' do
      subject { v0.add_extensions([Tackle::SimpleMixin]) }
      its(:extensions) { should == Set[Tackle::SimpleMixin] }
      it { should be_a(Pacer::ElementWrapper) }
      it { should be_a(Pacer::VertexWrapper) }
      it { should_not be_a(Pacer::EdgeWrapper) }

      describe '#v' do
        subject { v0.add_extensions([Tackle::SimpleMixin]).v }
        its(:extensions) { should == Set[Tackle::SimpleMixin] }
        it { should be_a(Pacer::Routes::VerticesRoute) }
        it { should be_a(Tackle::SimpleMixin::Route) }
      end
    end
  end

  describe '#delete!' do
    before do
      @vertex_id = v0.element_id
      v0.delete!
      graph.checkpoint # deleted edges in neo may be looked up during the transaction
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
    let(:dest) { graph2 }
  }) do
    describe '#clone_into', :transactions => false do
      subject { v0.clone_into(dest) }
      its(:properties) { should == { 'name' => 'eliza' } }
      its(:graph) { should equal(dest) }
      its('element_id.to_s') { should == v0.element_id.to_s if supports_custom_id }
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
  its(:inspect) { should == "#<V[#{v0.element_id}]>" }
  context 'with label proc' do
    before do
      graph.vertex_name = proc { |e| "some name" }
    end
    its(:display_name) { should == "some name" }
    its(:inspect) { should == "#<V[#{ v0.element_id }] some name>" }
  end
end

for_each_graph do
  it_uses Pacer::VertexMixin
end
