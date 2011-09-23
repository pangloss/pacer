require 'spec_helper'

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
end
