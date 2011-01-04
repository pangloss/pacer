require 'spec_helper'

shared_examples_for Pacer::EdgeMixin do
  let(:v0) { graph.create_vertex :name => 'eliza' }
  let(:v1) { graph.create_vertex :name => 'darrick' }
  let(:e0) { graph.create_edge nil, v0, v1, :links }
  let(:e1) { graph.create_edge nil, v0, v1, :relinks }

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
        it { should be_a(Pacer::Routes::EdgesRoute) }
        it { should be_a(Tackle::SimpleMixin::Route) }
      end
    end
  end

  subject { e0 }
  its(:display_name) { should == "#{ v0.element_id }-links-#{ v1.element_id }" }
  its(:inspect) { should == "#<E[#{ e0.element_id }]:#{ v0.element_id }-links-#{ v1.element_id }>" }
  context 'with label proc' do
    before do
      graph.edge_name = proc { |e| "some name" }
    end
    its(:display_name) { should == "some name" }
    its(:inspect) { should == "#<E[#{ e0.element_id }]:some name>" }
  end
end

for_each_graph do
  it_uses Pacer::EdgeMixin
end
