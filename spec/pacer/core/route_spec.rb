require 'spec_helper'

describe Pacer::Core::Route do
  let(:base_route) { [1, 2, 3].to_route }
  subject { base_route }

  its(:back) { should be_nil }

  # TODO: move graph-specific stuff to Pacer::Core::Graph::(something)

  it { should be_root }

  its(:hide_elements) { should_not be_true }

  describe '#route' do
    subject { base_route.route }
    it { should equal(base_route) }
    its(:hide_elements) { should be_true }
  end

  its(:vars) { should == {} }


  describe '#each' do
    context 'without block' do
      subject { base_route.each }
      it { should be_a com.tinkerpop.pipes.Pipe }
    end
  end

  describe '#inspect' do
    subject { base_route.inspect }
    it { should == '#<Obj>' }

    describe 'with route elements visible' do
      before :all do
        # objectspace is required for rr mocks.
        @cols = Pacer.columns
        @limit = Pacer.inspect_limit
        JRuby.objectspace = true
        Pacer.hide_route_elements = false
      end
      after :all do
        Pacer.columns = @cols
        Pacer.inspect_limit = @limit
        JRuby.objectspace = false
        Pacer.hide_route_elements = true
      end
      specify 'default setting' do
        mock(base_route).puts '1 2 3'
        mock(base_route).puts 'Total: 3'
        base_route.inspect.should == '#<Obj>'
      end
      specify '4 column display' do
        Pacer.columns = 4
        mock(base_route).puts '1 2'
        mock(base_route).puts '3'
        mock(base_route).puts 'Total: 3'
        base_route.inspect.should == '#<Obj>'
      end
      specify 'aligned columns' do
        Pacer.columns = 6
        route = [-1, 0, 1, 2].to_route
        mock(route).puts '-1 0 '
        mock(route).puts '1  2 '
        mock(route).puts 'Total: 4'
        route.inspect.should == '#<Obj>'
      end
      specify '2 item limit' do
        Pacer.inspect_limit = 2
        dont_allow(base_route).puts(anything)
        base_route.inspect.should == '#<Obj>'
      end
    end

    describe 'with pipe with no args' do
      subject do
        r = base_route.uniq
        r.route_name = nil
        r.inspect
      end
      it { should == "#<Obj -> Obj(Duplicate)>" }
    end
  end

  describe '#==' do
    it { should == subject }
    it { should_not == [].to_route }
    it { should == [1, 2, 3].to_route }
    it { should_not == [1, 3, 2].to_route }
    it { should_not == subject.select { true } }
    # TODO: consider technique to compare blocks?
    #it { subject.select { true }.should == subject.select { true } }
    it { subject.select { true }.should_not == subject.select { false } }
    it { subject.select { true }.should_not == subject.reject { false } }
    it { r = subject.select { true }; r.should == r }
  end

  it { should_not be_empty }
  it 'should be empty' do
    [].to_route.should be_empty
  end

  describe '#add_extension' do
    context 'Object' do
      subject { base_route.add_extension Object }
      its(:extensions) { should be_empty }
    end

    context 'SimpleMixin' do
      subject { base_route.add_extension Tackle::SimpleMixin }
      its(:extensions) { should include(Tackle::SimpleMixin) }
      its('extensions.count') { should == 1 }
      it 'should have extension method' do
        subject.route_mixin_method.should be_true
      end
      it { should be_a Tackle::SimpleMixin::Route }
      its(:first) { should == 1 }
    end
  end

  its(:extensions) { should == [] }

  describe '#extensions=' do
    before :all do
      JRuby.objectspace = true
    end
    after :all do
      JRuby.objectspace = false
    end
    it 'should add one extension' do
      mock(subject).add_extension(Tackle::SimpleMixin)
      subject.extensions = Tackle::SimpleMixin
    end
    it 'should add multiple extensions' do
      mock(subject).add_extension(Tackle::SimpleMixin)
      mock(subject).add_extension(TP::Person)
      subject.extensions = [Tackle::SimpleMixin, TP::Person]
    end
    it 'should accumulate extensions' do
      subject.add_extension TP::Person
      subject.extensions.should == Set[TP::Person]
      subject.extensions = Tackle::SimpleMixin
      subject.extensions.should == Set[TP::Person, Tackle::SimpleMixin]
    end
  end

  describe '#add_extensions' do
    before :all do
      JRuby.objectspace = true
    end
    after :all do
      JRuby.objectspace = false
    end
    it 'should add use add_extension' do
      mock(subject).add_extension(Tackle::SimpleMixin)
      mock(subject).add_extension(TP::Person)
      result = subject.add_extensions [Tackle::SimpleMixin, TP::Person]
    end
    it 'should add multiple extensions' do
      subject.add_extensions [Tackle::SimpleMixin, TP::Person]
      subject.extensions.should == Set[Tackle::SimpleMixin, TP::Person]
    end
    it 'should be chainable' do
      subject.add_extensions([Tackle::SimpleMixin]).should be subject
    end
  end

  describe '#set_pipe_source' do
    before { base_route.set_pipe_source [:a, :b] }
    its(:to_a) { should == [:a, :b] }

    it 'should not change the structure' do
      route = base_route.select { |o| o == 1 or o == :a }.select { true }
      route.to_a.should == [:a]
      route.set_pipe_source [1, 2, 3]
      route.to_a.should == [1]
    end
  end

  its(:element_type) { should == :object }

  describe 'custom pipe' do
    context 'with pipe args' do
      let(:mock_type) { Pacer::Pipes::EnumerablePipe }
      let(:pipe_args) { [['a', 1]] }

      subject { Pacer::RouteBuilder.current.chain nil, :element_type => :object,
                  :pipe_class => mock_type, :pipe_args => pipe_args }

      it 'should create the pipe' do
        subject.send(:build_pipeline).last.to_a.should == ['a', 1]
      end
      its(:pipe_args) { should == [['a', 1]] }
    end
  end
end
