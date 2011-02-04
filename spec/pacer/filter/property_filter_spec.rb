require 'spec_helper'

for_tg(:read_only) do
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
      its(:extensions) { should == Set[] }
      it 'should have the correct type' do
        subject[:type].uniq.to_a.should == ['person']
      end
    end

    context 'v(:type => "person", :name => "pangloss")' do
      subject { graph.v(:type => 'person', :name => 'pangloss') }
      its(:to_a) { should == graph.v('type' => 'person', 'name' => 'pangloss').to_a }
      its(:to_a) { should == graph.v.where('type = "person" and name = "pangloss"').to_a }
      its(:count) { should == 1 }
      its(:extensions) { should == Set[] }
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
      its(:extensions) { should == Set[TP::Person] }
      its(:to_a) { should == graph.v(:type => 'person').to_a }
      its(:to_a) { should_not == graph.v(:type => 'project').to_a }
    end

    context 'v(TP::Project)' do
      subject { graph.v(TP::Project) }
      its(:count) { should == 4 }
      its(:extensions) { should == Set[TP::Project] }
      its(:to_a) { should == graph.v(:type => 'project').to_a }
    end

    context 'v(TP::Project)' do
      subject { graph.v(TP::Person, TP::Project) }
      its(:count) { should == 0 }
      its(:extensions) { should == Set[TP::Person, TP::Project] }
    end

    context 'v(Tackle::SimpleMixin)' do
      subject { graph.v(Tackle::SimpleMixin) }
      its(:count) { should == 7 }
      its(:extensions) { should == Set[Tackle::SimpleMixin] }
    end

    context 'v(:Tackle::SimpleMixin)' do
      subject { graph.v(Tackle::SimpleMixin, :name => 'pangloss') }
      its(:count) { should == 1 }
      its(:extensions) { should == Set[Tackle::SimpleMixin] }
    end

    context 'v(:Tackle::SimpleMixin)' do
      subject { graph.v(Tackle::SimpleMixin, :name => 'pangloss') }
      its(:count) { should == 1 }
      its(:extensions) { should == Set[Tackle::SimpleMixin] }
    end
  end
end
