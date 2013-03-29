require 'spec_helper'

Run.tg(:read_only) do
  use_pacer_graphml_data(:read_only)

  describe Pacer::Filter::PropertyFilter do
    context 'v()' do
      subject { graph.v }
      its(:count) { should == 7 }
    end

    context 'v(:type => "person")' do
      subject { graph.v(:type => 'person') }
      its(:to_a) { should == graph.v('type' => 'person').to_a }
      its(:to_a) { should == graph.v.where('type = "person"').to_a }
      its(:count) { should == 2 }
      its(:extensions) { should == [] }
      it 'should have the correct type' do
        subject[:type].uniq.to_a.should == ['person']
      end
    end

    context 'v(:type => "person", :name => "pangloss")' do
      subject { graph.v(:type => 'person', :name => 'pangloss') }
      its(:to_a) { should == graph.v('type' => 'person', 'name' => 'pangloss').to_a }
      its(:to_a) { should == graph.v.where('type = "person" and name = "pangloss"').to_a }
      its(:count) { should == 1 }
      its(:extensions) { should == [] }
      it 'should have the correct type' do
        subject[:type].first.should == 'person'
      end
      it 'should have the correct name' do
        subject[:name].first.should == 'pangloss'
      end
    end

    context 'v(:type => "person", :name => Set["pangloss", "someone"])' do
      subject { graph.v(:type => 'person', :name => Set['pangloss', 'someone']) }
      its(:to_a) { should == graph.v('type' => 'person', 'name' => 'pangloss').to_a }
      its(:to_a) { should == graph.v.where('type = "person" and (name == "pangloss" or name == "someone")').to_a }
      its(:count) { should == 1 }
      its(:extensions) { should == [] }
      it 'should have the correct type' do
        subject[:type].first.should == 'person'
      end
      it 'should have the correct name' do
        subject[:name].first.should == 'pangloss'
      end
    end

    context 'v(TP::Person)' do
      subject { graph.v(TP::Person) }
      its(:count) { should == 2 }
      its(:extensions) { should == [TP::Person] }
      its(:to_a) { should == graph.v(:type => 'person').to_a }
      its(:to_a) { should_not == graph.v(:type => 'project').to_a }
    end

    context 'v(TP::Project)' do
      subject { graph.v(TP::Project) }
      its(:count) { should == 4 }
      its(:extensions) { should == [TP::Project] }
      its(:to_a) { should == graph.v(:type => 'project').to_a }
    end

    context 'v(TP::Person, TP::Project)' do
      subject { graph.v(TP::Person, TP::Project) }
      its(:count) { should == 0 }
      its(:extensions) { should == [TP::Person, TP::Project] }
    end

    context 'v(Tackle::SimpleMixin)' do
      subject { graph.v(Tackle::SimpleMixin) }
      its(:count) { should == 7 }
      its(:extensions) { should == [Tackle::SimpleMixin] }
    end

    context 'v(:Tackle::SimpleMixin, :name => "pangloss")' do
      subject { graph.v(Tackle::SimpleMixin, :name => 'pangloss') }
      its(:count) { should == 1 }
      its(:extensions) { should == [Tackle::SimpleMixin] }
    end

    context 'reversed params' do
      subject { graph.v.v(TP::Pangloss, Tackle::SimpleMixin) }
      its(:count) { should == 1 }
    end

    context 'reversed params' do
      subject { graph.v.v(TP::Pangloss) }
      its(:count) { should == 1 }
    end

    context 'with wrapper' do
      let(:exts) { [Tackle::SimpleMixin, TP::Project] }
      let(:wrapper_class) { Pacer::Wrappers::VertexWrapper.wrapper_for exts }

      describe 'v(wrapper_class)' do
        subject { graph.v(wrapper_class) }
        its(:wrapper) { should == wrapper_class }
        its(:extensions) { should == exts }
        its(:first) { should be_a wrapper_class }
      end

      describe 'v(wrapper_class, Pacer::Utils::TSort)' do
        subject { graph.v(wrapper_class, Pacer::Utils::TSort) }
        its(:wrapper) { should == wrapper_class }
        its(:extensions) { should == (exts + [Pacer::Utils::TSort]) }
        it { should_not be_empty }
        its('first.class') { should_not == wrapper_class }
        its('first.class.extensions') { should == exts + [Pacer::Utils::TSort] }
      end

      describe 'v(wrapper_class, :name => "pacer")' do
        subject { graph.v(wrapper_class, :name => 'pacer') }
        its(:count) { should == 1 }
        its(:wrapper) { should == wrapper_class }
        its(:extensions) { should == exts }
        its(:first) { should be_a wrapper_class }
        its(:filters) { should_not be_nil }
        its('filters.wrapper') { should == wrapper_class }
      end
    end
  end
end
