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

Run.tg :read_only do
  use_pacer_graphml_data :read_only

  describe Pacer::Wrappers::ElementWrapper do
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

    describe 'extension ordering' do
      before do
        Pacer::Wrappers::ElementWrapper.clear_cache
      end
      subject { Pacer.vertex_wrapper TP::Person, Tackle::SimpleMixin, TP::Coder }

      its(:extensions) { should == [TP::Person, Tackle::SimpleMixin, TP::Coder]  }
      it 'should have the ancestors set in the correct order' do
        # Ruby searches for methods down this list, so order is
        # important for method overrides.
        subject.ancestors[0...6].should == [
          Pacer::Wrap::VertexWrapperTP_PersonTackle_SimpleMixinTP_Coder,
          TP::Coder::Route,
          Tackle::SimpleMixin::Vertex,
          Tackle::SimpleMixin::Route,
          TP::Person::Route,
          Pacer::Wrappers::VertexWrapper,
        ]
      end

      it 'should preserve the order once it is established for that combination of extensions' do
        subject.ancestors.should == Pacer.vertex_wrapper(TP::Coder, TP::Person, Tackle::SimpleMixin).ancestors
      end

      context 'should preserve extension order if a route uses the wrapper and adds more extensions' do
        let(:wrapper) { Pacer.vertex_wrapper TP::Person, Tackle::SimpleMixin, TP::Coder }
        subject do
          route = graph.v(wrapper, Pacer::Utils::TSort)
          first = route.first
          first.should_not be_nil
          first.class
        end

        it 'should have ancestors in the correct order' do
          subject.ancestors[0...9].should == [
            Pacer::Wrap::VertexWrapperTP_PersonTackle_SimpleMixinTP_CoderPacer_Utils_TSort,
            Pacer::Utils::TSort::Vertex,
            Pacer::Utils::TSort::Route,
            TSort,
            TP::Coder::Route,
            Tackle::SimpleMixin::Vertex,
            Tackle::SimpleMixin::Route,
            TP::Person::Route,
            Pacer::Wrappers::VertexWrapper,
          ]
        end
      end

      context 'should preserve extension order in a block filter' do
        subject do
          klass = nil
          route = graph.v(TP::Person, Tackle::SimpleMixin, TP::Coder) { |e| klass = e.class }
          route.first.should_not be_nil
          klass
        end

        it 'should have ancestors in the correct order' do
          subject.ancestors[0...7].should == [
            Pacer::Wrap::VertexWrapperTP_PersonTackle_SimpleMixinTP_CoderPacer_Extensions_BlockFilterElement,
            Pacer::Extensions::BlockFilterElement::Route,
            TP::Coder::Route,
            Tackle::SimpleMixin::Vertex,
            Tackle::SimpleMixin::Route,
            TP::Person::Route,
            Pacer::Wrappers::VertexWrapper,
          ]
        end
      end

      context 'should be in a different order if cleared and defined differently' do
        before { Pacer::Wrappers::ElementWrapper.clear_cache }
        subject { Pacer.vertex_wrapper Tackle::SimpleMixin, TP::Person, TP::Coder }

        its(:extensions) { should == [Tackle::SimpleMixin, TP::Person, TP::Coder]  }
        it 'should have the ancestors set in the correct order' do
          # Ruby searches for methods down this list, so order is
          # important for method overrides.
          subject.ancestors[0...6].should == [
            Pacer::Wrap::VertexWrapperTackle_SimpleMixinTP_PersonTP_Coder,
            TP::Coder::Route,
            TP::Person::Route,
            Tackle::SimpleMixin::Vertex,
            Tackle::SimpleMixin::Route,
            Pacer::Wrappers::VertexWrapper,
          ]
        end

        context 'should preserve extension order if a route adds more extensions' do
          subject do
            klass = nil
            route = graph.v(Tackle::SimpleMixin, TP::Person, TP::Coder) { |e| klass = e.class }
            route.first.should_not be_nil
            klass
          end

          it { should_not be_nil }
          it 'should have ancestors in the correct order' do
            subject.ancestors[0...7].should == [
              Pacer::Wrap::VertexWrapperTackle_SimpleMixinTP_PersonTP_CoderPacer_Extensions_BlockFilterElement,
              Pacer::Extensions::BlockFilterElement::Route,
              TP::Coder::Route,
              TP::Person::Route,
              Tackle::SimpleMixin::Vertex,
              Tackle::SimpleMixin::Route,
              Pacer::Wrappers::VertexWrapper,
            ]
          end
        end
      end
    end
  end
end
