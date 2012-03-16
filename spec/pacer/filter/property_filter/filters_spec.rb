require 'spec_helper'

module Pacer::Filter::PropertyFilter
  describe Filters do
    subject { filters }

    context 'no properties' do
      let(:filters) { Pacer::Route.filters [] }

      its(:any?) { should be_false }
    end

    context 'no properties' do
      let(:filters) { Pacer::Route.filters [Tackle::SimpleMixin] }

      its(:any?) { should be_true }
      its(:extensions) { should == [Tackle::SimpleMixin] }
      its(:route_modules) { should be_empty }
      its(:wrapper) { should be_nil }
      its(:blocks) { should be_empty }
      its(:properties) { should be_empty }
    end

    context 'simple properties' do
      let(:filters) { Pacer::Route.filters([name: 'Darrick', nickname: 'pangloss']) }

      its(:any?) { should be_true }
      its(:extensions) { should be_empty }
      its(:route_modules) { should be_empty }
      its(:wrapper) { should be_nil }
      its(:blocks) { should be_empty }
      its(:properties) { should == [ %w[ name Darrick ], %w[ nickname pangloss ] ] }
    end

    context 'with extensions' do
      let(:filters) { Pacer::Route.filters([TP::Person, name: 'Darrick', nickname: 'pangloss']) }

      its(:any?) { should be_true }
      its(:extensions) { should == [TP::Person] }
      its(:route_modules) { should be_empty }
      its(:wrapper) { should be_nil }
      its(:blocks) { should be_empty }
      its(:properties) { should == [ %w[ type person ], %w[ name Darrick ], %w[ nickname pangloss ] ] }
    end
  end
end
