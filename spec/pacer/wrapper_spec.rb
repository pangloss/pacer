require 'spec_helper'
require 'pacer/graph/element_mixin_spec'

Run.all do
  # This runs about 500 specs, basically it should test all the ways
  # that wrappers act the same as native elements
  it_uses Pacer::ElementMixin do
    let(:v0) { graph.create_vertex(Tackle::SimpleMixin, :name => 'eliza') }
    let(:v1) { graph.create_vertex(Tackle::SimpleMixin, :name => 'darrick') }
    let(:e0) { graph.create_edge nil, v0, v1, :links, Tackle::SimpleMixin }
    let(:e1) { graph.create_edge nil, v0, v1, :relinks, Tackle::SimpleMixin }
  end
end

Run.all :read_only do
  use_pacer_graphml_data :read_only

  describe Pacer::Wrappers::VertexWrapper do

    let(:v_exts) { Set[Tackle::SimpleMixin, TP::Project] }
    let(:v_wrapper_class) { Pacer::Wrappers::VertexWrapper.wrapper_for v_exts }

    subject { v_wrapper_class }

    it { should_not be_nil }
    its(:route_conditions) { should == { type: 'project' } }
    its(:extensions) { should == v_exts }

    describe 'instance' do
      subject { v_wrapper_class.new pacer }
      it               { should_not be_nil }
      its(:element)    { should_not be_nil }
      it               { should == pacer }
      it               { should_not equal pacer }
      its(:element_id) { should == pacer.element_id }
      its(:extensions) { should == v_exts }
    end
  end

  describe Pacer::Wrappers::EdgeWrapper do

    let(:e_exts) { Set[Tackle::SimpleMixin, TP::Wrote] }
    let(:e_wrapper_class) { Pacer::Wrappers::EdgeWrapper.wrapper_for e_exts }

    subject { e_wrapper_class }

    it { should_not be_nil }
    its(:route_conditions) { should == { label: 'wrote' } }
    its(:extensions) { should == e_exts }

    describe 'instance' do
      subject { e_wrapper_class.new pangloss_wrote_pacer }
      it               { should_not be_nil }
      its(:element)    { should_not be_nil }
      it               { should == pangloss_wrote_pacer }
      it               { should_not equal pangloss_wrote_pacer }
      its(:element_id) { should == pangloss_wrote_pacer.element_id }
      its(:extensions) { should == e_exts }
    end
  end
end
