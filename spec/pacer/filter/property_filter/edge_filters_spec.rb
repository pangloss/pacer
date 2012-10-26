require 'spec_helper'

# edge filters are also tested in filters_spec
module Pacer::Filter::PropertyFilter
  Run.tg do
    describe EdgeFilters do
      subject { filters }

      context 'symbol label' do
        let(:filters) { Pacer::Route.edge_filters [:label] }

        its(:any?) { should be_true }
        its(:labels) { should == ['label'] }
        its(:extensions_only?) { should be_false }
        its(:extensions) { should be_empty }
        its(:route_modules) { should be_empty }
        its(:wrapper) { should be_nil }
        its(:blocks) { should be_empty }
        its(:properties) { should be_empty }
      end

      context 'symbol labels' do
        let(:filters) { Pacer::Route.edge_filters [:label, :label2] }

        its(:any?) { should be_true }
        its(:labels) { should == ['label', 'label2'] }
      end

      context 'labels arrays' do
        let(:filters) { Pacer::Route.edge_filters ["label", [:label2]] }

        its(:any?) { should be_true }
        its(:labels) { should == ['label', 'label2'] }
      end

      context 'labels and properties' do
        let(:filters) { Pacer::Route.edge_filters [:label, { prop: 'value' }] }

        its(:any?) { should be_true }
        its(:labels) { should == ['label'] }
        its(:properties) { should == [['prop', 'value']] }
      end

      context 'labels and extension' do
        let(:filters) { Pacer::Route.edge_filters [:label, TP::Person] }

        its(:any?) { should be_true }
        its(:labels) { should == ['label'] }
        its(:extensions) { should == [TP::Person] }
        its(:properties) { should == [ %w[ type person ] ] }
      end

      context 'labels and simple extension' do
        let(:filters) { Pacer::Route.edge_filters [:label, Tackle::SimpleMixin] }

        its(:any?) { should be_true }
        its(:labels) { should == ['label'] }
        its(:extensions) { should == [Tackle::SimpleMixin] }
        its(:properties) { should be_empty }
      end
    end
  end
end
