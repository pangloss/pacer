require 'spec_helper'
require 'pacer/graph/element_mixin_spec'

Run.all do
  # This runs about 500 specs, basically it should test all the ways
  # that wrappers act the same as native elements
  describe Pacer::Wrappers::ElementWrapper do
    it_uses Pacer::ElementMixin do
      let(:v0) { graph.create_vertex(Tackle::SimpleMixin, :name => 'eliza') }
      let(:v1) { graph.create_vertex(Tackle::SimpleMixin, :name => 'darrick') }
      let(:e0) { graph.create_edge nil, v0, v1, :links, Tackle::SimpleMixin }
      let(:e1) { graph.create_edge nil, v0, v1, :relinks, Tackle::SimpleMixin }
    end
  end
end

describe Pacer, '.wrap_vertex' do
  before { Pacer.edge_wrapper Tackle::SimpleMixin }
  subject { Pacer.vertex_wrapper Tackle::SimpleMixin }
  its(:name) { should =~ /^Pacer::Wrap::/ }
  its(:ancestors) { should include Pacer::Wrappers::VertexWrapper }
end

describe Pacer, '.wrap_vertex' do
  before { Pacer.vertex_wrapper Tackle::SimpleMixin }
  subject { Pacer.edge_wrapper Tackle::SimpleMixin }
  its(:name) { should =~ /^Pacer::Wrap::/ }
  its(:ancestors) { should include Pacer::Wrappers::EdgeWrapper }
end

describe Pacer::Wrappers::ElementWrapper, focus: true do
  subject { Pacer.vertex_wrapper Tackle::SimpleMixin }

  its(:name) { should =~ /^Pacer::Wrap::/ }
  its(:extensions) { should == [Tackle::SimpleMixin] }

  describe '.clear_cache' do
    before do
      subject.const_set :ORIGINAL, true
      Pacer.vertex_wrapper(Tackle::SimpleMixin).const_defined?(:ORIGINAL).should be_true
      Pacer::Wrappers::ElementWrapper.clear_cache
    end

    it 'should get rid of the Pacer::Wrap namespace' do
      Pacer.const_defined?(:Wrap).should be_false
    end

    it 'should not be the same object if redefined' do
      # if the wrapper is redefined identically, you can't use a normal
      # comparison to see if it's actually been redefined.
      Pacer.vertex_wrapper(Tackle::SimpleMixin).const_defined?(:ORIGINAL).should be_false
    end
  end

  describe '.wrap' do
  end
end

